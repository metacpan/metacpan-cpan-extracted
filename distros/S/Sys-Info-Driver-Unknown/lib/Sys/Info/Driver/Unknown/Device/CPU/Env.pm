package Sys::Info::Driver::Unknown::Device::CPU::Env;
use strict;
use warnings;
use vars qw( $VERSION );
use constant RE_VENDOR => qr/(.+?), \s (?:Genuine(Intel)|Authentic(AMD))/xms;

$VERSION = '0.78';

my(%INTEL, %AMD, %OTHER_ID, %OTHER, %CPU, $INSTALLED);

sub identify {
    my $self = shift;

    if ( ! $self->{META_DATA} ) {
        $self->_INSTALL() if ! $INSTALLED;

        if ( ! $CPU{id} ) {
            $self->{META_DATA} = []; # fake
            return;
        }

        my($cpu, $count, @cpu);
        if ($CPU{id} =~ RE_VENDOR ) {
            my $cid  = $1;
            my $corp = $2 || $3;
            if ( my %info = $self->_parse( $cid ) ) {
                if ( my $mn = $self->_corp( $corp, $info{Family} ) ) {
                    if ( my $name = $mn->{ $info{Model} } ) {
                        $count = ($CPU{number} && $CPU{number} > 1) ? $CPU{number} : q{};
                        $cpu   = "$corp $name";
                    }
                }
            }
        }

        foreach my $other (keys %OTHER_ID) {
            if ($CPU{id} =~ / \Q$other\E /xms) {
                $cpu = $OTHER_ID{$other};
            }
        }

        $count = 1 if !$count;
        for ( 1..$count ) {
            push @cpu, {
                architecture  => ($CPU{id} =~ m{ \A (.+?) \s? Family }xmsi),
                data_width    => undef,
                speed         => undef,
                bus_speed     => undef,
                address_width => undef,
                name          => $cpu,
            };
        }
        $self->{META_DATA} = [@cpu];
    }

    return $self->_serve_from_cache(wantarray);
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _INSTALL {
    my $self   = shift;
    %INTEL     = _INTEL();
    %AMD       = _AMD();
    %OTHER_ID  = _OTHER_ID();
    %OTHER     = _OTHER();
    %CPU       = (                              # PIV 3.0 GHz HT
        id     => $ENV{PROCESSOR_IDENTIFIER},   # x86 Family 15 Model 3 Stepping 3, GenuineIntel
        number => $ENV{NUMBER_OF_PROCESSORS},   # 2
        arch   => $ENV{PROCESSOR_ARCHITECTURE}, # x86
        rev    => $ENV{PROCESSOR_REVISION},     # 0303
        level  => $ENV{PROCESSOR_LEVEL},        # 15
    );

    if ( ! $CPU{id} && $self->can('__env_pi') ) {
        $CPU{id} = $self->__env_pi;
    }
    $INSTALLED = 1;
    return;
}

sub _corp {
    my $self   = shift;
    my $corp   = shift;
    my $family = shift;
    return    $corp eq 'Intel' ? $INTEL{$family}
            : $corp eq 'AMD'   ? $AMD{$family}
            :                    undef;
}

sub _parse {
    my $self = shift;
    my $id   = shift;
    my $arch = $CPU{arch};
    if ($id =~ /$arch\s(.+?) \z/xms) {
        my %h = split /\s+/xms, $1; # Family Model Stepping
        for my $k (keys %h) {
            $h{$k} = q{} unless defined $h{$k};
        }
        return %h;
    }
}

sub _INTEL {
   # Family  Model    Name
   return
    '4'  => {
            '0'     => '486 DX-25/33',
            '1'     => '486 DX-50',
            '2'     => '486 SX',
            '3'     => '486 DX/2',
            '4'     => '486 SL',
            '5'     => '486 SX/2',
            '7'     => '486 DX/2-WB',
            '8'     => '486 DX/4',
            '9'     => '486 DX/4-WB',
    },
    '5'  => {
            '0'     => 'Pentium 60/66 A-step',
            '1'     => 'Pentium 60/66',
            '2'     => 'Pentium 75 - 200',
            '3'     => 'OverDrive PODP5V83',
            '4'     => 'Pentium MMX',
            '7'     => 'Mobile Pentium 75 - 200',
            '8'     => 'Mobile Pentium MMX',
    },
    '6'  => {
            '0'     => 'Pentium Pro A-step',
            '1'     => 'Pentium Pro',
            '3'     => 'Pentium II (Klamath)',
            '5'     => 'Pentium II (Deschutes), Celeron (Covington), Mobile Pentium II (Dixon)',
            '6'     => 'Mobile Pentium II, Celeron (Mendocino)',
            '7'     => 'Pentium III (Katmai)',
            '8'     => 'Pentium III (Coppermine)',
            '9'     => 'Mobile Pentium III',
            '10'    => 'Pentium III (0.18 µm)',
            '11'    => 'Pentium III (0.13 µm)',

            '13'    => 'Celeron M', # ???
            '15'    => 'Core 2 Duo (Merom)', # ???
    },
    '7'  => {
            '0'     => 'Itanium (IA-64)',
    },
    '15' => {
            '0'     => 'Pentium IV (0.18 µm)',
            '1'     => 'Pentium IV (0.18 µm)',
            '2'     => 'Pentium IV (0.13 µm)',
            '3'     => 'Pentium IV (0.09 µm)',
            # Itanium 2 (IA-64)?
    },
}

sub _AMD {
    # Family  Model    Name
    return
    '4'  => {
        '3'     => '486 DX/2',
        '7'     => '486 DX/2-WB',
        '8'     => '486 DX/4',
        '9'     => '486 DX/4-WB',
        '14'    => 'Am5x86-WT',
        '15'    => 'Am5x86-WB',
    },
    '5'  => {
        '0'     => 'K5/SSA5',
        '1'     => 'K5',
        '2'     => 'K5',
        '3'     => 'K5',
        '6'     => 'K6',
        '7'     => 'K6',
        '8'     => 'K6-2',
        '9'     => 'K6-3',
        '13'    => 'K6-2+ or K6-III+',
    },
    '6'  => {
        '0'     => 'Athlon (25 µm)',
        '1'     => 'Athlon (25 µm)',
        '2'     => 'Athlon (18 µm)',
        '3'     => 'Duron',
        '4'     => 'Athlon (Thunderbird)',
        '6'     => 'Athlon (Palamino)',
        '7'     => 'Duron (Morgan)',
        '8'     => 'Athlon (Thoroughbred)',
        '10'    => 'Athlon (Barton)',
    },
    '15' => {
        '4'     => 'Athlon 64',
        '5'     => 'Athlon 64 FX Opteron',
    },
}

sub _OTHER_ID {
    # Vendor          Manufacturer Name
    return
    'CyrixInstead' => 'Cyrix',
    'CentaurHauls' => 'Centaur',
    'NexGenDriven' => 'NexGen',
    'GenuineTMx86' => 'Transmeta',
    'RiseRiseRise' => 'Rise',
    'UMC UMC UMC'  => 'UMC',
    'SiS SiS SiS'  => 'SiS',
    'Geode by NSC' => 'National Semiconductor',
}

sub _OTHER {
    return
    Cyrix => {
    # Family Model Name
        '4' => {
            '4' => 'MediaGX',
        },
        '5' => {
            '2' => '6x86 / 6x86L (Identifying the difference)',
            '4' => 'MediaGX MMX Enhanced',
        },
        '6' => {
            '0' => 'm II (6x86MX)',
            '5' => 'VIA Cyrix M2 core',
            '6' => 'WinChip C5A',
            '7' => 'WinChip C5B ,WinChip C5C',
            '8' => 'WinChip C5N',
            '9' => 'WinChip C5XL, WinChip C5P',
        },
    },
    UMC => {
        '4' => {
            '1' => 'U5D',
            '2' => 'U5S',
        },
    },
    Centaur => {
        '5' => {
            '4' => 'C6',
            '8' => 'C2',
            '9' => 'C3',
        },
    },
    'National Semiconductor' => {
        '5' => {
            '4' => 'GX1, GXLV, GXm',
            '5' => 'GX2',
        },
    },

    NexGen => {
        '5' => {
            '0' => 'Nx586',
        },
    },
    Rise => {
        '5' => {
            '0' => 'mP6',
            '1' => 'mP6',
        },
    },
    SiS => {
        '5' => {
            '0' => '55x',
        }
    },
    Transmeta => {
        '5' => {
            '4' => 'Crusoe TM3x00 and TM5x00',
        },
    },
}

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Unknown::Device::CPU::Env - Fetch CPU information from %ENV

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Unknown::Device::CPU::Env>
released on C<17 April 2011>.

These C<%ENV> keys are recognised by this module:

   PROCESSOR_IDENTIFIER
   NUMBER_OF_PROCESSORS
   PROCESSOR_ARCHITECTURE
   PROCESSOR_REVISION
   PROCESSOR_LEVEL

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>,
L<http://www.sandpile.org/>,
L<http://www.paradicesoftware.com/specs/cpuid/index.htm>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.3 or, 
at your option, any later version of Perl 5 you may have available.

=cut
