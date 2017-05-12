use strict;
use warnings;

use 5.010;
use Test::Most;

use List::Util qw( max );
use Test::MockObject::Extends;
use Test::Warn;
use Scalar::Util qw( looks_like_number );
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Format::Util::Numbers qw(roundnear);
use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Delta;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

Quant::Framework::Utils::Test::create_doc(
    'currency',
    {
        symbol           => $_,
        recorded_date    => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    }) for (qw/EUR JPY USD/);

my @mocked_builders;

subtest 'get_volatility for different expiries ' => sub {
    my $surface = _get_surface();

    my $now = Date::Utility->new;
    throws_ok { $surface->get_volatility({delta => 50, days => undef}) }
    qr/Must pass two dates/i,
        "throws exception when period is undef in get_vol";
    throws_ok { $surface->get_volatility({delta => 50, from => $now}) }
    qr/Must pass two dates/i,
        "throws exception when \$to is undef in get_vol";
    throws_ok { $surface->get_volatility({delta => 50, to => $now}) }
    qr/Must pass two dates/i,
        "throws exception when \$from is undef in get_vol";
    throws_ok { $surface->get_volatility({delta => 50, to => $now->minus_time_interval('1s'), from => $now}) }
    qr/Inverted dates/i,
        "throws exception when \$from and \$to are inverted in get_vol";
    $now = $surface->recorded_date;
    lives_ok {
        my $vol = $surface->get_volatility({delta => 50, to => $now->plus_time_interval('1s'), from => $now->minus_time_interval('1s')});
        is $vol, 0.01, '1% volatility';
        like ($surface->validation_error, qr/Invalid request for get volatility/, 'volsurface validation error is set.');
    } "do not die if requested date for volatility is in the past";
    lives_ok {
        my $vol = $surface->get_volatility({delta => 50, to => $now, from => $now});
        is $vol, 0.01, '1% volatility';
        like ($surface->validation_error, qr/Invalid request for get volatility/, 'volsurface validation error is set.');
    } "do not die if requested dates for volatility are equal";
    lives_ok { $surface->get_volatility({delta => 50, from => $now, to => $now->plus_time_interval('1s')}) }
    "can get volatility when mandatory arguments are provided";
};

subtest 'get_volatility for different sought points' => sub {
    my $surface = _get_surface();

    throws_ok { $surface->get_volatility({strike => 76.8, delta => 50, days => 1}) }
    qr/exactly one of/i,
        "throws exception when more than on sough points are parsed in get_volatility";
    throws_ok { $surface->get_volatility({strike => undef, days => 1}) } qr/exactly one/i, "throws exception if strike is undef";
    my $from = $surface->recorded_date;
    my $to   = $from->plus_time_interval('1s');
    lives_ok { $surface->get_volatility({strike    => 76.5, from => $from, to => $to, spot => 101}) } "can get_vol for strike";
    lives_ok { $surface->get_volatility({delta     => 50,   from => $from, to => $to}) } "can get_vol for delta";
    lives_ok { $surface->get_volatility({moneyness => 100,  from => $from, to => $to}) } "can get_vol for moneyness";
};

subtest 'get_smile' => sub {
    my $surface = _get_surface();
    my $from    = $surface->recorded_date;
    my $to      = $from->plus_time_interval('1d');

    my $smile = $surface->get_smile($from, $to);
    is $smile->{25}, 0.158943882847805,  'volatility for 25D';
    is $smile->{50}, 0.0794719414239026, 'volatility for 50D';
    is $smile->{75}, 0.238415824271708,  'volatility for 75D';

    my $later_date = $from->plus_time_interval('3d');
    my $smile3 = $surface->get_smile($from, $later_date);
    cmp_ok $smile3->{25}, '!=', $smile->{25}, 'volatility for 25D is different when both dates of the requested date is on different period';
    cmp_ok $smile3->{50}, '!=', $smile->{50}, 'volatility for 50D is different when both dates of the requested date is on different period';
    cmp_ok $smile3->{75}, '!=', $smile->{75}, 'volatility for 75D is different when both dates of the requested date is on different period';
};

subtest 'get_surface_smile' => sub {
    my $surface = _get_surface();

    ok keys %{$surface->get_surface_smile(7)},  'return smile if present on surface';
    ok !keys %{$surface->get_surface_smile(2)}, 'return empty hash if smile is not present on surface';
};

subtest get_spread => sub {
    plan tests => 13;

    my $surface = _get_surface({
            surface => {
                7 => {
                    smile => {
                        25 => 0.11,
                        50 => 0.1,
                        75 => 0.101
                    },
                    vol_spread => {50 => 0.05}
                },
                14 => {
                    smile => {
                        25 => 0.11,
                        50 => 0.1,
                        75 => 0.101
                    }
                },
                21 => {
                    smile => {
                        25 => 0.11,
                        50 => 0.1,
                        75 => 0.101
                    },
                    vol_spread => {50 => 0.05}
                },
            }});
    cmp_ok(
        $surface->get_spread({
                sought_point => 'atm',
                day          => 7
            }
        ),
        '==', 0.05,
        'Cause get_spread to interpolate.'
    );

    $surface = _get_surface();
    my $spread;
    lives_ok { $spread = $surface->get_spread({sought_point => 'atm', day => '1W'}) } 'can get spread for tenor';
    ok(looks_like_number($spread),    'spread looks like number');
    ok(exists $surface->surface->{7}, '7-day smile exists');
    lives_ok { $spread = $surface->get_spread({sought_point => 'atm', day => 7}) } "can get spread from spread that already exist on the smile";
    is($spread, 0.15, "get the right spread");
    lives_ok { $spread = $surface->get_spread({sought_point => 'atm', day => 4}) } "can get interpolated spread";
    cmp_ok($spread, '<', 0.2,  "interpolated spread < 0.2");
    cmp_ok($spread, '>', 0.15, "interpolated spread > 0.15");
    lives_ok { $spread = $surface->get_spread({sought_point => 'atm', day => 0.5}) }
    "can get the extrapolated spread when seek is smaller than the minimum of all terms";
    is(roundnear(0.01, $spread), 0.2, "correct extrapolated atm_spread");
    lives_ok { $spread = $surface->get_spread({sought_point => 'atm', day => 366}) }
    "can get the extrapolated spread when seek is larger than the maximum of all terms";
    is($spread, 0.1, "correct extrapolated atm_spread");
};

subtest get_day_for_tenor => sub {
    plan tests => 5;
    my $surface = _get_surface({
            surface => {
                '1W' => {
                    smile => {
                        50 => 0.1,
                    },
                    vol_spread => {50 => 0.1}}}});
    is_deeply(
        $surface->surface,
        {
            7 => {
                smile      => {50 => 0.1},
                tenor      => '1W',
                vol_spread => {50 => 0.1}}});
    my $day;
    lives_ok { $day = $surface->get_day_for_tenor('1W') } "can get day for tenor that is already present on the surface";
    is($day, 7, "returns the day on smile if present");

    my $surface2 = _get_surface({recorded_date => Date::Utility->new('12-Jun-12')});
    lives_ok { $day = $surface2->get_day_for_tenor('1W') } "can get day for tenor that does not exist on the surface";
    is($day, 7, "returns the calculated day for tenor");
};

subtest get_market_rr_bf => sub {
    plan tests => 6;
    my $surface = _get_surface({
            surface => {
                7 => {
                    smile => {
                        10 => 0.25,
                        25 => 0.2,
                        50 => 0.1,
                        75 => 0.22,
                        90 => 0.4
                    }}}});

    my $value;
    lives_ok { $value = $surface->get_market_rr_bf(7) }
    "can get market RR and BF values";
    ok(looks_like_number($value->{RR_25}), "RR_25 is a number");
    ok(looks_like_number($value->{BF_25}), "BF_25 is a number");
    ok(looks_like_number($value->{ATM}),   "ATM is a number");
    ok(looks_like_number($value->{RR_10}), "RR_10 is a number");
    ok(looks_like_number($value->{BF_10}), "BF_10 is a number");
};

subtest 'object creaion error check' => sub {
    plan tests => 3;
    my $underlying    = Quant::Framework::Utils::Test::create_underlying_config('frxUSDJPY');
    my $recorded_date = Date::Utility->new();
    my $surface       = {1 => {smile => {50 => 0.1}}};
    throws_ok {
        Quant::Framework::VolSurface::Delta->new({
                surface          => $surface,
                recorded_date    => $recorded_date,
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
            })
    }
    qr/Attribute \(underlying_config\) is required/, 'Cannot create volsurface without underlying_config';
    throws_ok {
        Quant::Framework::VolSurface::Delta->new({
                surface           => $surface,
                underlying_config => $underlying,
                chronicle_reader  => $chronicle_r,
                chronicle_writer  => $chronicle_w,
            })
    }
    qr/Must pass both "surface_data" and "recorded_date" if passing either/, 'Cannot create volsurface without recorded_date';
    lives_ok {
        Quant::Framework::VolSurface::Delta->new({
                surface           => $surface,
                underlying_config => $underlying,
                recorded_date     => $recorded_date,
                chronicle_reader  => $chronicle_r,
                chronicle_writer  => $chronicle_w,
            })
    }
    'can create volsurface';
};

subtest effective_date => sub {
    plan tests => 2;

    my $underlying = Quant::Framework::Utils::Test::create_underlying_config('frxUSDJPY');
    my $surface    = Quant::Framework::Utils::Test::create_doc(
        'volsurface_delta',
        {
            underlying_config => $underlying,
            recorded_date     => Date::Utility->new('2012-03-09 21:15:00'),
            save              => 0,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
        });

    is($surface->_ON_day, 3, 'In winter, 21:15 on Friday is before rollover so _ON_day is 3.');

    $surface = Quant::Framework::Utils::Test::create_doc(
        'volsurface_delta',
        {
            underlying_config => $underlying,
            recorded_date     => Date::Utility->new('2012-03-16 21:15:00'),
            save              => 0,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
        });

    is($surface->_ON_day, 2, 'In summer, 21:15 on Friday is after rollover so _ON_day is 2.');
};

subtest 'variance table' => sub {
    my $monday_bef_ro = Date::Utility->new('2016-07-04 18:00:00');
    my $surface_data  = {
        1 => {
            smile => {
                25 => 0.2,
                50 => 0.19,
                75 => 0.22
            },
            atm_spread => {50 => 0.01}}};
    my $args = {
        underlying_config => Quant::Framework::Utils::Test::create_underlying_config('frxUSDJPY'),
        recorded_date     => $monday_bef_ro,
        surface           => $surface_data,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
        save              => 0,
    };
    my $surface = Quant::Framework::Utils::Test::create_doc('volsurface_delta', $args);
    is $surface->variance_table->{$surface->effective_date->plus_time_interval('1d14h')->epoch}->{50}, 0.19**2 * 1, 'variance is correct';
    is $surface->effective_date->date, $monday_bef_ro->date, 'effective date is on the same day before rollover';
    lives_ok {
        my @expected = ($monday_bef_ro->epoch, $surface->effective_date->plus_time_interval('1d14h')->epoch);
        cmp_bag([keys %{$surface->variance_table}], \@expected, 'correct dates in variance table');
    }
    'variance table';

    $args->{recorded_date} = Date::Utility->new('2016-07-04 23:00:00');
    $surface = Quant::Framework::Utils::Test::create_doc('volsurface_delta', $args);
    is $surface->effective_date->date, $monday_bef_ro->plus_time_interval('1d')->date, 'effective date is next day';
    lives_ok {
        my @expected = ($args->{recorded_date}->epoch, Date::Utility->new('2016-07-06 14:00:00')->epoch);
        cmp_bag([keys %{$surface->variance_table}], \@expected, 'correct dates in variance table');
    }
    'variance table';
};

subtest 'get weight' => sub {
    my $trading_day        = Date::Utility->new('2016-07-04');
    my $weekend            = Date::Utility->new('2016-07-03');
    my $trading_day_weight = 1;
    my $weekend_weight     = 0.5;
    my $surface            = _get_surface();

    is $surface->get_weight($trading_day, $trading_day->plus_time_interval('4h')), 1 / 6, 'correct weight';
    is $surface->get_weight($trading_day, $trading_day->plus_time_interval('6h')), 1 / 4, 'correct weight';
    is $surface->get_weight($weekend->plus_time_interval('18h'), $trading_day->plus_time_interval('6h')), (21600 / 86400 * 0.06) + (1 / 4),
        'correct weight for cross day';
    is $surface->get_weight($weekend->plus_time_interval('23h30m'), $trading_day->plus_time_interval('1h')), ((30*60)/86400 * 0.06) + (1/24), 'less than one hour cross day';
};

subtest 'get variance' => sub {
    my $surface  = _get_surface();
    my $expected = {
        25 => 0.04,
        50 => 0.01,
        75 => 0.09,
    };
    my $effective_date = $surface->effective_date;
    is_deeply $surface->get_variances($effective_date->plus_time_interval('1d14h')), $expected, 'correct variances retrieved';
    # as period decreases, so does variance.
    note('assuming variance is equally distributed');
    ok $surface->get_variances($effective_date->plus_time_interval('1h'))->{50} <
        $surface->get_variances($effective_date->plus_time_interval('2h'))->{50}, 'variance of 1h < variance of 2h';
    ok $surface->get_variances($effective_date->plus_time_interval('2h'))->{50} <
        $surface->get_variances($effective_date->plus_time_interval('3h'))->{50}, 'variance of 2h < variance of 3h';
};

subtest 'save surface to chronicle' => sub {
    plan tests => 1;

    my $surface = _get_surface();
    lives_ok { $surface->save } 'can save surface to chronicle';
};

# PRIVATE METHODS

subtest '_get_points_to_interpolate' => sub {
    plan tests => 15;
    my $surface = _get_surface();

    throws_ok { $surface->_get_points_to_interpolate(7, []) } qr/Need 2 or more/, "throws exception if there's no available points to interpolate";
    throws_ok { $surface->_get_points_to_interpolate(7, [1]) } qr/Need 2 or more/, "throws exception if there's only 1 term structure available";
    lives_ok { $surface->_get_points_to_interpolate(7, [1, 2]) } "can _get_points_to_interpolate with at least two available points";

    my @points;
    lives_ok { @points = $surface->_get_points_to_interpolate(7, [1, 2, 3]) }
    "get the last two points in the array of available points if the seek point is larger than max of availale points";
    is(scalar @points, 2, 'only return 2 closest points with _get_points_to_interpolate');
    is($points[0],     2, "correct first point");
    is($points[1],     3, "correct second point");

    lives_ok { @points = $surface->_get_points_to_interpolate(1, [4, 2, 3]) }
    "get the first two points in the array of avaialble points if the seek point is smaller than min of availale points";
    is(scalar @points, 2, 'only return 2 closest points with _get_points_to_interpolate');
    is($points[0],     2, "correct first point");
    is($points[1],     3, "correct second point");

    lives_ok { @points = $surface->_get_points_to_interpolate(5, [4, 6, 3]) } "get points in between";
    is(scalar @points, 2, 'only return 2 closest points with _get_points_to_interpolate');
    is($points[0],     4, "correct first point");
    is($points[1],     6, "correct second point");
};

subtest _is_between => sub {
    plan tests => 5;
    my $surface = _get_surface();

    lives_ok { $surface->_is_between(2, [1, 3]) } "can call _is_between";
    throws_ok { $surface->_is_between(2, [1]) } qr/less than two available points/, 'throws exception when available points is less that 2';
    throws_ok { $surface->_is_between(2, [1, undef]) } qr/some of the points are not defined/,
        'throws exception if at least one of the points are not defined';
    ok($surface->_is_between(2, [1, 3]), "returns true if seek is between available points");
    ok(!$surface->_is_between(4, [1, 2]), 'returns false if seek if not in between available points');
};

sub _get_surface {
    my $override = shift || {};
    my %override = %$override;
    my $ul       = Quant::Framework::Utils::Test::create_underlying_config(
        'frxUSDJPY',
        {
            default_interest_rate => 0.5,
            default_dividend_rate => 0.5,
        });

    my $surface = Quant::Framework::VolSurface::Delta->new(
        underlying_config => $ul,
        recorded_date     => Date::Utility->new('20-Jun-12'),
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
        surface           => {
            ON => {
                smile => {
                    25 => 0.2,
                    50 => 0.1,
                    75 => 0.3
                },
                vol_spread => {50 => 0.2},
            },
            '1W' => {
                smile => {
                    25 => 0.224,
                    50 => 0.2,
                    75 => 0.35
                },
                vol_spread => {50 => 0.15},
            },
            '2W' => {
                smile => {
                    25 => 0.324,
                    50 => 0.3,
                    75 => 0.45
                },
                vol_spread => {50 => 0.1},
            },
        },
        %override,
    );

    return $surface;
}

done_testing;
