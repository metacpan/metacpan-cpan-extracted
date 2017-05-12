###########################################
package Sys::Ramdisk;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(:all);
use File::Temp qw(tempdir);
use File::Basename;

our $VERSION = "0.02";

my %class_mapper =
  map { $_->[0] => __PACKAGE__ . "::" . $_->[1] }
    ( [linux  => "Linux"],
      [macos  => "OSX"],
      [osx    => "OSX"],
      [darwin => "OSX"],
    );

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        cleanup => 1,
        %options,
    };

    if(! defined $self->{dir}) {
        $self->{dir} = tempdir( CLEANUP => 1 );
    }

    if(! defined $self->{size}) {
        $self->{size} = "100m";
    }

    my $subclass = os_class_find();

    eval "require $subclass";

    bless $self, $subclass;

    return $self;
}

###########################################
sub os_supported_list {
###########################################
    (my $path = __PACKAGE__) =~ s/::/\//g;
    $path = "$path.pm";

    my $dir = $INC{$path};
    $dir =~ s/\.pm$//;

    my @classes = ();

    opendir DIR, "$dir" or LOGDIE "Cannot opendir $dir ($!)";
    for my $dir (readdir DIR) {
        next if $dir eq ".";
        next if $dir eq "..";
        $dir =~ s/\.pm$//;
        push @classes, $dir;
    }

    closedir DIR;

    return @classes;
}

###########################################
sub os_find {
###########################################
    my $uname = bin_find("uname");

    if(! defined $uname) {
        LOGWARN "uname command not found in PATH";
        return undef;
    }

    my($uname_info) = tap $uname;
    chomp $uname_info;

    if(! defined $uname or length $uname == 0) {
        LOGWARN "uname didn't return anything meaningful";
        return undef;
    }

    return $uname_info;
}

###########################################
sub os_class_find {
###########################################
    my $os = os_find();

    my $keyword = lc $os;

    if(exists $class_mapper{ $keyword }) {
        my $class = $class_mapper{ $keyword };

        DEBUG "Found class $class";
        return $class;
    }

    WARN "OS '$os' not supported (yet). Please contact the maintainer";
    return undef;
}

###########################################
sub dir {
###########################################
    my($self, $dir) = @_;

    if(defined $dir) {
        $self->{dir} = $dir;
    }

    return $self->{dir};
}

###########################################
sub DESTROY {
###########################################
    my($self, $dir) = @_;

    $self->unmount() if $self->{cleanup};
}

###########################################
sub size_normalize {
###########################################
    my($self, $size) = @_;

    if($size =~ /(\d+)m/) {
        return $1 * 1024 * 1024;
    }

    return $size;
}

1;

__END__

=head1 NAME

Sys::Ramdisk - Create and nuke RAM disks on various systems

=head1 SYNOPSIS

    use Sys::Ramdisk;

    my $ramdisk = Sys::Ramdisk->new(
       size => "100m",
       dir  => "/tmp/ramdisk",
    );

    $ramdisk->mount();

    # Use ramdisk on /tmp/ramdisk ...

    $ramdisk->unmount();

=head1 DESCRIPTION

Most Unix systems provide RAM disks, although every OS/filesystem 
flavor seems to have its own interface to it. Sys::Ramdisk provides
a system-agnostic interface to it, by abstracting the nitty gritty
of the particular implementation.

=head1 METHODS

=over 4

=item C<new()>

Constructor, optional arguments are 

=over 4

=item C<size> 

The size of the RAM disk, defaults to 100m.

=item C<dir>

The directory the RAM disk is going to be mounted under, defaults
to a temporary directory, created on demand and returned by the dir()
method later

=item C<cleanup>

Set this to true if you want the object destructor unmount the
yroot when the object goes out of scope. Defaults to true.

=back

=item C<mount()>

Mount the RAM disk.

=item C<unmount()>

Unmount the RAM disk.

=item C<dir()>

Set or get the name of the directory the RAM disk will be mounted 
under. Note that some operating systems mount the RAM disk under a 
different directory nevertheless (e.g. OSX), make sure to check 
$ramdisk->dir() after running mount() to figure out where it actually 
landed.

=back

=head1 SUPPORTED OPERATING SYSTEMS

Currently, only Linux and OSX are supported.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
