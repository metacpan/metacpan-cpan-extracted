package Sys::Info::Driver::Windows::Device::CPU::WMI;
use strict;
use warnings;
use constant LOAD_DIV    => 100;
use constant VOLTAGE_DIV =>  10;
use base                       qw( Sys::Info::Base );
use Win32::OLE                 qw( in              );
use Sys::Info::Driver::Windows qw( :WMI            );
use Sys::Info::Driver::Windows::Device::CPU::WMI::Conf;

our $VERSION = '0.78';

my $WMI_INFO           = $CONF{info};
my %RENAME             = %{ $CONF{rename}{cpu}          };
my %CACHE_MEMORY_NAMES = %{ $CONF{rename}{cache_memory} };
my %LCACHE_NAMES       = %{ $CONF{rename}{lcache}       };

# TODO: Only available under Vista
my @VISTA_OPTIONS = qw( L3CacheSpeed L3CacheSize );

my @__JUNK = qw(
    ConfigManagerErrorCode
    ConfigManagerUserConfig
    ErrorCleared
    ErrorDescription
    InstallDate
    L2CacheSpeed
    LastErrorCode
    OtherFamilyDescription
    PNPDeviceID
    PowerManagementCapabilities
    PowerManagementSupported
    UniqueId
    VoltageCaps
);

POPULATE_UNSUPPORTED: {
    for my $j( @__JUNK ){
        $RENAME{ $j } = '____' . $j;
    }
}

sub _from_wmi {
    my $self     = shift;
    local $SIG{__DIE__};
    local $@;

    my %LCACHE;
    my @names = keys %CACHE_MEMORY_NAMES;
    foreach my $f ( in WMI_FOR('Win32_CacheMemory') ) {
        my $purpose = $f->Purpose;
        next if $purpose !~ m{ \A L \d \- Cache }xmsi;
        $LCACHE{ $LCACHE_NAMES{ $purpose } } = {
            map { $CACHE_MEMORY_NAMES{$_} => $f->$_() } @names
        };
    }

    my @attr;
    OUTER: foreach my $cpu (in WMI_FOR('Win32_Processor') ) {
        my %attr;
        INNER: foreach my $name (keys %RENAME) {
            my $val;
            my $eok = eval { $val = $cpu->$name(); 1; };
            if ( $@ || ! $eok ) {
                warn '[WMI ERROR] ' .  ( $@ || '<Unknown error>') . "\n";
                next INNER;
            }
            next INNER if ! defined $val;
            if ( $name eq 'Name' ) {
                $val =~ s{\s+}{ }xmsg;
                $val = $self->trim( $val );
            }
            my $ren = $RENAME{$name};
            $attr{ $ren } = $WMI_INFO->{ $name }{ $val } || $val;
        }
        if ( $attr{bus_speed} && $attr{speed} ) {
            $attr{multiplier} = sprintf '%.2f', $attr{speed} / $attr{bus_speed};
        }
        $attr{current_voltage} /= VOLTAGE_DIV if $attr{current_voltage};
        # LoadPercentage : returns undef
        $attr{load} = sprintf '%.2f', $attr{load} / LOAD_DIV if $attr{load};
        push @attr, {%attr, %LCACHE };
    }
    return @attr;
}

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Windows::Device::CPU::WMI - Fetch CPU metadata through WMI

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows::Device::CPU::WMI>
released on C<17 April 2011>.

WMI plugin.

=head1 SEE ALSO

L<Sys::Info>,
L<http://vbnet.mvps.org/index.html?code/wmi/win32_processor.htm>,
L<http://msdn2.microsoft.com/en-us/library/aa394373.aspx>,
L<http://support.microsoft.com/kb/894569>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
