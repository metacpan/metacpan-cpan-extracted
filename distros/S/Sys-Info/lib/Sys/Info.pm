package Sys::Info;
$Sys::Info::VERSION = '0.7811';
use strict;
use warnings;

use Carp qw( croak );
use Sys::Info::Constants qw( OSID );
use base qw( Sys::Info::Base );

our @EXPORT_OK = qw( OSID );

__PACKAGE__->_mk_object( $_ ) for qw( OS Device );

sub import {
    my($class, @names) = @_;
    my $caller = caller;
    my %cache  = map { $_ => 1 } @EXPORT_OK;
    no strict qw( refs );
    foreach my $name ( @names ) {
        croak "Bogus import: $name"                 if not $class->can($name);
        croak "Caller already has the $name method" if     $caller->can($name);
        croak "Access denied for $name"             if not exists $cache{$name};
        *{ $caller . q{::} . $name } = *{ $class . q{::} . $name };
    }
    return;
}

sub new {
    my $class = shift;
    my $self  = {};
    bless  $self, $class;
    return $self;
}

sub perl { return defined $^V ? sprintf( '%vd', $^V ) : _legacy_perl( $] ) }

sub perl_build {
    return 0 if OSID ne 'Windows';
    require Win32 if $] >= 5.006;
    return 0 if not defined &Win32::BuildNumber;
    return Win32::BuildNumber();
}

sub perl_long { return join q{.}, perl(), perl_build() }

sub httpd {
    my $self   = shift;
    my $server = $ENV{SERVER_SOFTWARE} || return;

    if ( $server =~ m{\A Microsoft\-IIS/ (.+?) \z}xms ) {
        return 'Microsoft Internet Information Server ' . $1;
    }

    if ( $server   =~ m{\A (Apache)/(.+?) \z}xmsi ) {
        my $apache = $1;
        my @data   = split /\s+/xms, $2;
        my $v      = shift @data;
        my @mods;
        my($mn, $mv);
        foreach my $e (@data) {
            next if $e =~ m{ \A \( .+? \) \z}xms;
            ($mn,$mv) = split m{/}xms, $e;
            $mn =~ s{ \-(.+?) \z }{}xms;
            push @mods, $mn .'(' . $mv . ')';
        }
        return "$apache $v. Modules: " . join q{ }, @mods;
    }

   return $server;
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _mk_object {
    my $self  = shift;
    my $name  = shift || croak '_mk_object() needs a name';
    no strict qw(refs);
    *{ lc $name } = sub {
        shift->load_module( 'Sys::Info::' . $name )->new( @_ );
    };
    return;
}

sub _legacy_perl { # function
    my $v = shift or return;
    my($rev, $patch_sub) = split m{[.]}xms, $v;
    $patch_sub =~ s{[0_]}{}xmsg;
    my @v = split m{}xms, $patch_sub;
    return sprintf '%d.%d.%d', $rev, $v[0], $v[1] || '0';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info

=head1 VERSION

version 0.7811

=head1 SYNOPSIS

    use Sys::Info;
    my $info = Sys::Info->new;
    printf "Perl version is %s\n", $info->perl;
    if(my $httpd = $info->httpd) {
        print "HTTP Server is $httpd\n";
    }
    my $cpu = $info->device('CPU');
    my $os  = $info->os;
    printf "Operating System is %s\n", $os->name( long => 1 );
    printf "CPU: %s\n", scalar $cpu->identify;

=head1 DESCRIPTION

Extracts and collects information from the host system.

=head1 NAME

Sys::Info - Fetch information from the host system

=head1 METHODS

=head2 new

Constructor.

=head2 os

Creates and returns an instance of a L<Sys::Info::OS> object.
See L<Sys::Info::OS> for available methods.

=head2 device

Creates and returns an instance of the specified device's object.
See L<Sys::Info::Device> for more information.

=head2 perl

Returns the perl version in the I<version number> format (i.e.: 5.8.8).
This is also true for legacy perls (i.e.: 5.005_03 will be 5.5.3)

=head2 perl_build

Returns the ActivePerl build number if code is used under Windows with
ActivePerl. Returns zero otherwise.

=head2 perl_long

This method is just a combination of C<perl> & C<perl_build>.

=head2 httpd

If the code is used under a HTTP server and this server is recognised,
returns the name of this server. Returns C<undef> otherwise.

=head1 CONSTANTS

=head2 OSID

Returns the OS identifier.

=head1 SEE ALSO

L<Sys::Info::Base>,
L<Sys::Info::OS>,
L<Sys::Info::Device>,
L<Filesys::Ext2>,
L<Filesys::Statvfs>,
L<Filesys::Type>
L<Filesys::DiskFree>,
L<Filesys::DiskSpace>,
L<Filesys::DiskUsage>,
L<Linux::Distribution>,
L<Linux::Distribution::Packages>,
L<Probe::MachineInfo>,
L<Sys::CPU>,
L<Sys::CpuLoad>,
L<Sys::Filesystem>,
L<Sys::HostIP>,
L<Sys::Hostname::FQDN>,
L<Sys::Load>,
L<Sys::MemInfo>,
L<Sys::Uptime>,
L<Unix::Processors>,
L<Win32::SystemInfo>,
L<Win32>,
L<Win32API::File>,
L<Win32API::Net>,
L<Win32::OLE>,
L<Win32::TieRegistry>

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
