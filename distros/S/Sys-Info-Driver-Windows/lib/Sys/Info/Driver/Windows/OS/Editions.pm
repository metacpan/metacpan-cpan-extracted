package Sys::Info::Driver::Windows::OS::Editions;
use strict;
use warnings;
use Sys::Info::Driver::Windows qw( :metrics :WMI );

use constant RE_X86   => qr{  X86}xmsi;
use constant RE_AMD64 => qr{AMD64}xmsi;
use constant RE_IA64  => qr{ IA64}xmsi;

## no critic ( ValuesAndExpressions::ProhibitMagicNumbers    )
## no critic ( ValuesAndExpressions::RequireNumberSeparators )

our $VERSION = '0.78';

my %VISTA_EDITION = (
   0x00000006 => q{Business Edition},
   0x00000010 => q{Business N Edition},
   0x00000004 => q{Enterprise Edition},
   0x00000002 => q{Home Basic Edition},
   0x00000005 => q{Home Basic N Edition},
   0x00000003 => q{Home Premium Edition},
   0x0000000B => q{Starter Edition},
   0x00000001 => q{Ultimate Edition},
);

my %SERVER08_EDITION = (
   0x00000012 => q{Cluster Server Edition},
   0x00000008 => q{Datacenter Edition Full Installation}, # Windows Server ...
   0x0000000C => q{Datacenter Edition Core Installation}, # Windows Server ...
   0x0000000A => q{Enterprise Edition Full Installation}, # Windows Server ...
   0x0000000E => q{Enterprise Edition Core Installation}, # Windows Server ...
   0x0000000F => q{Enterprise Edition For Itanium Based Systems}, # Windows Server ...
   0x00000013 => q{Home Server Edition},
   0x00000018 => q{Server For Small Business Edition},
   0x00000009 => q{Small Business Server},
   0x00000019 => q{Small Business Server Premium Edition},
   0x00000007 => q{Server Standard Edition Full Installation},
   0x0000000D => q{Server Standard Edition Core Installation},
   0x00000017 => q{Storage Server Enterprise Edition},
   0x00000014 => q{Storage Server Express Edition},
   0x00000015 => q{Storage Server Standard Edition},
   0x00000016 => q{Storage Server Workgroup Edition},
   0x00000011 => q{Web Server Edition},
);

sub _cpu_arch {
    my $self = shift;
    require Sys::Info::Device;
    my $cpu = Sys::Info::Device->new( 'CPU' );
    foreach my $cpu ( $cpu->identify ) {
        # get the first available one
        return $cpu->{architecture} if $cpu->{architecture};
    }
    return;
}

sub _xp_or_03 {
    my $self = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;

    my $mask   = $OSV->{RAW}{SUITEMASK};
    my $pt     = $OSV->{RAW}{PRODUCTTYPE};
    my $arch   = $self->_cpu_arch || q{};
    my $metric = GetSystemMetrics( SM_SERVERR2 );

    ${$osname_ref} = 'Windows Server 2003';

    my $id = $mask & 0x00000080 ? 1
           : $mask & 0x00000002 ? 2
           :                      3
           ;
    my $dispatch = '_xp_or_03_case' . $id;
    return $self->$dispatch( $metric, $arch, $edition_ref, $osname_ref, $pt );
}

sub _xp_or_03_case1 {
    my($self, $metric, $arch, $edition_ref) = @_;
    if ( $metric ) {
        ${$edition_ref} = $arch =~ RE_X86   ? 'R2 Datacenter Edition'
                        : $arch =~ RE_AMD64 ? 'R2 x64 Datacenter Edition'
                        :                     'unknown';
    }
    else {
        ${$edition_ref} = $arch =~ RE_X86   ? 'Datacenter Edition'
                        : $arch =~ RE_AMD64 ? 'Datacenter x64 Edition'
                        : $arch =~ RE_IA64  ? 'Datacenter Edition Itanium'
                        :                     'unknown';
    }
    return;
}

sub _xp_or_03_case2 {
    my($self, $metric, $arch, $edition_ref) = @_;
    if ( $metric ) {
        ${$edition_ref} = $arch =~ RE_X86   ? 'R2 Enterprise Edition'
                        : $arch =~ RE_AMD64 ? 'R2 x64 Enterprise Edition'
                        :                     'unknown';
    }
    else {
        ${$edition_ref} = $arch =~ RE_X86   ? 'Enterprise Edition'
                        : $arch =~ RE_AMD64 ? 'Enterprise x64 Edition'
                        : $arch =~ RE_IA64  ? 'Enterprise Edition Itanium'
                        :                     'unknown';
    }
    return;
}

sub _xp_or_03_case3 {
    my($self, $metric, $arch, $edition_ref, $osname_ref, $pt) = @_;
    if ( $metric ) {
        ${$edition_ref} = $arch =~ RE_X86   ? 'R2 Standard Edition'
                        : $arch =~ RE_AMD64 ? 'R2 x64 Standard Edition'
                        :                     'unknown';
    }
    elsif ( $pt > 1 ) {
        ${$edition_ref} = $arch =~ RE_X86   ? 'Standard Edition'
                        : $arch =~ RE_AMD64 ? 'Standard x64 Edition'
                        :                     'unknown';
    }
    elsif ( $pt == 1 ) {
        ${$osname_ref}  = 'Windows XP';
        ${$edition_ref} = $arch =~ RE_IA64  ? '64 bit Edition Version 2003'
                        : $arch =~ RE_AMD64 ? 'Professional x64 Edition'
                        :                     'unknown';
    }
    else {
        ${$edition_ref} = 'unknown';
    }
    return;
}

sub _xp_editions {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;
    my $arch        = $self->_cpu_arch;

    ${$osname_ref}  = 'Windows XP';
    ${$edition_ref} = GetSystemMetrics(SM_TABLETPC)    ? 'Tablet PC Edition'
                    : GetSystemMetrics(SM_MEDIACENTER) ? 'Media Center Edition'
                    : GetSystemMetrics(SM_STARTER)     ? 'Starter Edition'
                    : $arch =~ RE_X86                  ? 'Professional'
                    : $arch =~ RE_IA64                 ? '64-bit Edition for Itanium systems'
                    :                                    q{};
    return;
}

sub _2k_03_xp {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;
    my $mask        = $OSV->{RAW}{SUITEMASK};
    my $pt          = $OSV->{RAW}{PRODUCTTYPE};
    ${$osname_ref}  = 'Windows 2000';

    if ( $mask & 0x00000080 ) { ## no critic (ControlStructures::ProhibitCascadingIfElse)
        ${$edition_ref} = 'Datacenter Server';
    }
    elsif ( $mask & 0x00000002) {
        ${$edition_ref} = 'Advanced Server';
    }
    elsif (! $mask && $pt == 1 ) {
        ${$edition_ref} = 'Professional';
    }
    elsif (! $mask && $pt > 1 ) {
        ${$edition_ref} = 'Server';
    }
    elsif ( $mask & 0x00000400 ) {
        ${$osname_ref}  = 'Windows Server 2003';
        ${$edition_ref} = GetSystemMetrics(SM_SERVERR2) ? 'R2 Web Edition'
                                                        : 'Web Edition';
    }
    elsif ( $mask & 0x00004000) {
        ${$osname_ref}  = 'Windows Server 2003';
        ${$edition_ref} = GetSystemMetrics(SM_SERVERR2) ? 'R2 Compute Cluster Edition'
                                                        : 'Compute Cluster Edition';
    }
    elsif ( $mask & 0x00002000) {
        ${$osname_ref}  = 'Windows Server 2003';
        ${$edition_ref} = GetSystemMetrics(SM_SERVERR2) ? 'R2 Storage'
                                                        : 'Storage';
    }
    elsif ($mask & 0x00000040 ) {
        ${$osname_ref}  = 'Windows XP';
        ${$edition_ref} = 'Embedded';
    }
    elsif ($mask & 0x00000200) {
        ${$osname_ref}  = 'Windows XP';
        ${$edition_ref} = 'Home Edition';
    }
    else {
        warn "Unable to identify this Windows version\n";
    }
    return;
}

sub _vista_or_08 {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $WMI_OS      = WMI_FOR('Win32_OperatingSystem');
    return if ! $WMI_OS;

    # fall-back
    my $item    = ( in $WMI_OS )[0];
    my $SKU     = $item->OperatingSystemSKU;
    my $caption = $item->Caption;

    if ( my $vista = $VISTA_EDITION{ $SKU } ) {
        ${$edition_ref} = $vista;
        ${$osname_ref}  = 'Windows Vista';
    }
    elsif ( my $ws08 = $SERVER08_EDITION{ $SKU } ) {
        ${$edition_ref} = $ws08;
        ${$osname_ref}  = 'Windows Server 2008'; # oh yeah!
    }
    else {
        warn "Unable to identify this Windows version 6. Marking as Vista\n";
        ${$osname_ref} = 'Windows Vista';
    }
    return;
}

sub _win7 {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $WMI_OS      = WMI_FOR('Win32_OperatingSystem');
    return if ! $WMI_OS;

    # fall-back
    my $item    = ( in $WMI_OS )[0];
    my $SKU     = $item->OperatingSystemSKU;

    ${$osname_ref} = 'Windows 7';
    if ( my $win7 = $VISTA_EDITION{ $SKU } ) {
        ${$edition_ref} = $win7;
    }
    else {
        (my $caption = $item->Caption) =~ s{ .+? Windows \s 7 \s? }{}xms;
        ${$edition_ref} = $self->trim($caption) if $caption;
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Windows::OS::Editions - Interface to identify Windows editions

=head1 SYNOPSIS

None. Used internally.

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows::OS::Editions>
released on C<17 April 2011>.

Although there are not much Windows versions, there are ridiculously lots of
editions of Windows versions after Windows 2000. This module uses C<WMI>,
C<GetSystemMetrics> and CPU architecture to define the correct operating
system name and edition.

=head1 SEE ALSO

L<Win32>,
L<Sys::Info>,
L<Sys::Info::Driver::Windows>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
