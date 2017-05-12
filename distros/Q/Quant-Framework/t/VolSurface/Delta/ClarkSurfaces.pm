package ClarkSurfaces;

=head1 NAME

ClarkSurfaces

=head1 DESCRIPTION

A helper class that gives vol surfaces grabbed from examples in
Iain M Clark books. See Foreign Exchange Option Pricing,
A Practitioner's Guide page 73 for more details.

=cut

use strict;
use warnings;

use Moose;

use Date::Utility;
use Quant::Framework::VolSurface::Delta;

has chronicle_reader => (
    is       => 'ro',
    isa      => 'Data::Chronicle::Reader',
    required => 1,
);

has chronicle_writer => (
    is       => 'ro',
    isa      => 'Data::Chronicle::Writer',
    required => 1,
);

has _underlying_config => (
    is      => 'ro',
    isa     => 'Quant::Framework::Utils::UnderlyingConfig',
    default => sub {
        return Quant::Framework::Utils::Test::create_underlying_config('frxEURUSD');
    },
);

sub get {
    my $self = shift;

    return Quant::Framework::VolSurface::Delta->new(
        underlying_config => $self->_underlying_config,
        recorded_date     => Date::Utility->new('2012-01-13 00:00:00'),
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
        market_points     => {
            smile      => [3, 7, 14, 21, 28],
            vol_spread => [3, 7, 14, 21, 28],
        },
        surface => {
            3 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.0815},
            },    # ON
            4 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.0999},
            },
            5 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1095},
            },
            6 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1155},
            },
            7 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1195},
            },    # 1W
            8 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1118},
            },
            9 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1054},
            },
            10 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1096},
            },
            11 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1129},
            },
            12 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1156},
            },
            13 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1178},
            },
            14 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1197},
            },    # 2W
            15 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1156},
            },
            16 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1120},
            },
            17 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1134},
            },
            18 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1146},
            },
            19 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1157},
            },
            20 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1166},
            },
            21 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1175},
            },    # 3W
            22 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1148},
            },
            23 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1123},
            },
            24 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1136},
            },
            25 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1149},
            },
            26 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1160},
            },
            27 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1171},
            },
            28 => {
                vol_spread => {50 => 0},
                smile      => {50 => 0.1180},
            },    # 1M
        },
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
