package Sys::GNU::ldconfig;
# $Id: ldconfig.pm 1086 2013-02-25 16:53:37Z fil $
# Copyright 2013 Philip Gwyn - All rights reserved

use 5.00405;
use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.02';

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( ld_lookup ld_root );

sub DEBUG () { 0 }

use Carp;
use Config;
use File::Basename qw( dirname );
use File::Glob qw( bsd_glob );
use File::Slurp qw( slurp );
use File::Spec;


#############################################################################
our $LD;
sub ld_lookup
{
    my( $name ) = @_;
    $LD ||= Sys::GNU::ldconfig->new;
    return $LD->lookup( $name );
}

sub ld_root
{
    my( $path ) = @_;
    $LD ||= Sys::GNU::ldconfig->new;
    $LD->root( $path );
}

#############################################################################
sub new
{
    my( $package ) = @_;
    $package = ref $package if ref $package;
    my $self = bless { root => File::Spec->rootdir,
                       absroot => File::Spec->rootdir,
                       dirs => [],
                       have_dirs => 0
                     }, $package;
    return $self;
}

#################################################
sub root
{
    my( $self, $path ) = @_;
    confess "Root '$path' doesn't exist" unless -d $path;
    $self->{root} = $path;
    $self->{have_dirs} = 0;
    $self->{dirs} = [];
    return;
}


#################################################
# The heart of the module
sub lookup
{
    my( $self, $part ) = @_;

    my $file = $self->_lookup( $part );
    return unless defined $file;
    return $self->_derooted( $file );
}

sub _lookup
{
    my( $self, $part ) = @_;

    $part = "lib$part" unless $part =~ /^lib/;
    $part = "$part.$Config{dlext}" unless $part =~ /\.\Q$Config{dlext}\E/;  # allow .so.7 (for example)
    DEBUG and warn "Looking for '$part'\n";

    return $self->_chase_lib( $part ) if -e $part;
    foreach my $dir ( $self->dirs ) {
        my $file = File::Spec->catfile( $dir, $part );
        return $self->_chase_lib( $file ) if -e $file;
    }
    return;
}


# This logic is lifted from PAR::Packer
# _chase_lib - find the runtime link of a shared library
# Logic based on info found at the following sites:
# http://lists.debian.org/lsb-spec/1999/05/msg00011.html
# http://docs.sun.com/app/docs/doc/806-0641/6j9vuqujh?a=view#chapter5-97360
sub _chase_lib {
   my ($self, $file) = @_;

   while ($Config{d_symlink} and -l $file) {
       if ($file =~ /^(.*?\.\Q$Config{dlext}\E\.\d+)\..*/) {
           return $1 if -e $1;
       }

       return $file if $file =~ /\.\Q$Config{dlext}\E\.\d+$/;

       my $dir = File::Basename::dirname($file);
       $file = readlink($file);

       unless (File::Spec->file_name_is_absolute($file)) {
           $file = File::Spec->rel2abs($file, $dir);
       }
   }

   if ($file =~ /^(.*?\.\Q$Config{dlext}\E\.\d+)\..*/) {
       return $1 if -e $1;
   }
 
   return $file;
}

#################################################
sub _rooted
{
    my( $self, $dir ) = @_;
    my $root = $self->{root};
    return $dir if $root eq $self->{absroot};
    return File::Spec->catdir( $root, $dir );
}

#################################################
sub _derooted
{
    my( $self, $file ) = @_;
    my $root = $self->{root};
    $file =~ s/^\Q$root// unless $root eq $self->{absroot};
    return $file;
}

#################################################
sub _list_dirs
{
    my( $self ) = @_;
    my @dirs;
    if( $ENV{$Config{ldlibpthname}} ) {
        DEBUG and warn "Using $Config{ldlibpthname}\n";
        push @dirs, map { $self->_rooted( $_ ) } 
                    split ':', $ENV{$Config{ldlibpthname}};
    }
    my $conf = File::Spec->catfile( $self->{root}, 'etc', 'ld.so.conf' );
    push @dirs, $self->_read_conf( $conf ) if -f $conf;

    push @dirs, map { $self->_rooted( $_ ) } qw( /lib64 /lib /usr/lib64 /usr/lib );
    foreach my $dir ( @dirs ) {
        next unless -d $dir;
        DEBUG and warn "Search in $dir\n";
        push @{ $self->{dirs} }, $dir;
    }
    $self->{have_dirs} = 1;
}


#################################################
sub _read_conf
{
    my( $self, $file ) = @_;
    DEBUG and warn "Reading config '$file'\n";
    my $c = slurp( $file );
    my @dirs = split /[: \t\n,]+/, $c;
    my @ret;
    my $include_next = 0;
    foreach my $dir ( @dirs ) {
        if( $include_next ) {
            $include_next = 0;
            push @ret, $self->_read_glob( $file, $dir );
        }
        elsif( $dir eq 'include' ) {
            $include_next = 1;
        }
        else {
            push @ret, $self->_rooted( $dir );
        }
    }
    return @ret;
}


sub _read_glob
{
    my( $self, $file, $dir ) = @_;
    my( $vol, $dirname, $glob ) = File::Spec->splitpath( $dir );
    my $root = $self->{root};
    $root = dirname( $file ) unless File::Spec->file_name_is_absolute( $dir );
    my $confdir = File::Spec->catdir( $root, $dirname );
    DEBUG and warn "Look in $confdir for $glob\n";
    my @ret;
    foreach my $conf ( bsd_glob( File::Spec->catfile( $confdir, $glob ) ) ) {
        next unless -f $conf;
        push @ret, $self->_read_conf( $conf );
    }
    return @ret;
}


#################################################
sub dirs
{
    my( $self ) = @_;
    $self->_list_dirs unless $self->{have_dirs};
    return @{ $self->{dirs} };
}

1;
__END__

=head1 NAME

Sys::GNU::ldconfig - Search for shared libraries

=head1 SYNOPSIS

    use Sys::GNU::ldconfig;

    my $libso = ld_lookup( 'k5crypto' );    # /usr/lib64/libk5crypto.so on CentOS 5.8
    $libso = ld_lookup( 'libk5crypto' );    # same thing
    
    my $ld = Sys::GNU::ldconfig->new;
    $libso = $ld->lookup( 'k5crypto' );     # same again
    $libso = $ld->lookup( 'libk5crypto' );  # still the same


=head1 DESCRIPTION

Sys::GNU::ldconfig reproduces the logic used by ldconfig and ld.so to find a
shared library (.so or .dll).  It is intended for modules like PAR::Packer, 
that repackage code.

Sys::GNU::ldconfig will search the following places in order for a shared library:

=over 4

=item LD_LIBRARY_PATH

This is a colon C<:> seperated list of directories.  Because it is named differently
on some systems, ld_lookup uses C<$Config::Config{ldlibpthname}>.

=item /etc/ld.so.conf

This file contains a list of directories to search.  Directories are
seperated by comma (C<,>), space (C< >), colon (C<:>) or newline (C<\n>). 
May also contain an "include" directive, which is a file glob of other
config files to include.

=item Trusted directories

    /lib64
    /lib
    /usr/lib64
    /lib

These directories are hardcoded into L<ldconfig>.

=back

=head1 FUNCTIONS

=head2 ld_lookup

    $so = ld_lookup( 'k5cyrpto' );
    $so = ld_lookup( 'libk5cyrpto' );
    $so = ld_lookup( 'libk5cyrpto.so.13' );

Find a shared library.  Works with the library name (C<k5crypto>), filename
(C<libk5crypto.so>) or versioned filename (C<libk5cyrpto.so.13>).

Returns the full path to the major version of the library, for example
C</usr/lib64/libcurl.so.4> and not the full versioned
(C</usr/lib64/libcurl.so.4.2.0> or unversioned (C</usr/lib64/libcurl.so>).

When first called, ld_lookup creates a list of directories to search.
Subsequent calls will reuse this list.  The list is cleared by calling
L</ld_root>.

=head2 ld_root

    ld_root( '/mnt' );

Sets the root directory.  Defaults to C</>.  This is roughly equivalent to
doing L<chroot>(2) before calling L</ld_lookup>.  Note that if ld_lookup will return
a file path with the root stripped out.

Setting the root directory will clear the list of directories to search.

=head1 METHODS

Sys::GNU::ldconfig also provides an object-oriented interface.

=head2 new

    $ld = Sys::GNU::Lookup->new;

Create an object.

=head2 lookup

    my $so = $ld->lookup( 'k5cyrpto' );

Find a shared library.

=head2 dirs

    my @dirs = $ld->dirs;

Returns a list of directories that will be searched for shared libraries.


=head2 root

    $ld->root( '/mnt' );

Set the root directory to search in.

=head1 SEE ALSO

L<ld.so>(8), 
L<ldconfig>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -AT- cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
