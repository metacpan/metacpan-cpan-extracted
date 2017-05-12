package Sys::Info::Driver::Windows;
use strict;
use warnings;

our $VERSION = '0.78';

use base qw( Exporter );
use Carp qw( croak    );
use Sys::Info::Constants qw( WIN_B24_DIGITS );

# (only relevant) indexes for GetSystemMetrics()
use constant SM_TABLETPC    => 86; # Windows XP Tablet PC edition
use constant SM_MEDIACENTER => 87; # Windows XP, Media Center Edition
use constant SM_STARTER     => 88; # Windows XP Starter Edition
use constant SM_SERVERR2    => 89; # Windows Server 2003 R2
use constant SERIAL_BASE    => 24;

use XSLoader;

my %REGISTRY;
BEGIN {
    # SetDualVar req. in Win32::TieRegistry breaks any handler
    local $SIG{__DIE__};
    local $@;

    my $eok = eval {
        require Win32::TieRegistry;
        Win32::TieRegistry->import(
            TiedHash  => \%REGISTRY,
            Delimiter => q{/},
        );
        1;
    };

    if ( $@ || ! $eok ) {
        my $error = $@ || '<unknown error>';
        croak "Error loading Win32::TieRegistry: $error";
    }
}

our @EXPORT;
our %EXPORT_TAGS = (
    metrics => [qw/
        GetSystemMetrics
        SM_TABLETPC
        SM_MEDIACENTER
        SM_SERVERR2
        SM_STARTER
    /],
    info => [ qw/ GetSystemInfo CPUFeatures / ],
    WMI  => [ qw/ WMI WMI_FOR               / ],
    etc  => [ qw/ decode_serial_key         / ],
    reg  => [ qw/ registry                  / ],
);
our @EXPORT_OK    = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

XSLoader::load( __PACKAGE__, $VERSION );

sub registry { return \%REGISTRY }

sub WMI {
    my $WMI = Win32::OLE->GetObject( 'WinMgmts:' ) || return;
    croak Win32::OLE->LastError if Win32::OLE->LastError != 0;
    return $WMI;
}

sub WMI_FOR {
    my $WMI = WMI() || return;
    my $ID  = shift || croak 'No WMI Class specified';
    my $O   = $WMI->InstancesOf( $ID ) || return;
    croak Win32::OLE->LastError() if Win32::OLE->LastError() != 0;
    return $O;
}

sub decode_serial_key {
    # Modified from:
    #     http://www.perlmonks.org/?node_id=497616
    #     (c) Original code: William Gannon
    #     (c) Modifications: Charles Clarkson
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    my $key     = shift || croak 'Key is missing';
    my @encoded = ( unpack 'C*', $key )[ reverse 52 .. 66 ];
    use integer;

    my $quotient = sub {
        my( $index, $encoded ) = @_;
        my $dividend = $index * 256 ^ $encoded;
        # return modulus and integer quotient
        return( $dividend % SERIAL_BASE, $dividend / SERIAL_BASE );
    };

    my @indices;
    foreach my $i ( 0 .. SERIAL_BASE ) {
        my $index = 0;
        foreach my $j (@encoded) { # Shift off remainder
            ( $index, $j ) = $quotient->( $index, $j );
        }
        unshift @indices, $index;
    }

    # translate base 24 "digits" to characters
    my $cd_key = join q{}, (WIN_B24_DIGITS)[ @indices ];

    # Add seperators and return
    return join q{-}, $cd_key =~ m/(.{5})/xmsg;
}

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Windows - Windows driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::Windows qw(:metrics);
    if ( GetSystemMetrics(SM_SERVERR2) ) {
        # do something ...
    }

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows>
released on C<17 April 2011>.

This is the main module in the C<Windows> driver collection.

=head1 METHODS

None.

=head1 FUNCTIONS

The following functions will be automatically exported when the module
is used.

=head2 CPUFeatures

TODO

=head2 registry

Returns a C<Win32::TieRegistry> hashref.

=head2 WMI

Returns the C<WMI> object.

=head2 WMI_FOR CLASS

Returns the WMI object for the supplied C<WMI Class> name.

=head2 decode_serial_key KEY

Decodes the base24 encoded C<KEY>.

=head2 GetSystemMetrics

Interface to C<GetSystemMetrics> Windows function. Accepts an integer as the
parameter. The interface is incomplete (as Sys::Info does not need the rest)
and only these constants are defined:

    SM_TABLETPC
    SM_MEDIACENTER
    SM_SERVERR2
    SM_STARTER

All these constants and the function itself can be imported by the C<:metrics>
key.

=head2 GetSystemInfo

An interface to the C<Win32 API> function C<GetSystemInfo>:

    my %si = GetSystemInfo();
    printf("CPU: %s Family %s Model %s Stepping %s\n",
        @si{qw/
            wProcessorArchitecture2
            wProcessorLevel
            wProcessorModel
            wProcessorStepping
        /}
    );

=head1 SEE ALSO

L<Sys::Info>,
L<http://www.perlmonks.org/?node_id=497616>,
L<http://msdn.microsoft.com/en-us/library/ms724385(VS.85).aspx>,
L<http://msdn.microsoft.com/en-us/library/ms724429(VS.85).aspx>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
