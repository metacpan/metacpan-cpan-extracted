use Test::MockTime qw/:all/;
use Test::Most qw(-Test::Deep);
use Scalar::Util qw( looks_like_number );
use Test::MockObject::Extends;
use Test::FailWarnings;
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Moneyness;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $underlying_config = Quant::Framework::Utils::Test::create_underlying_config('HSI');

my $underlying_config_spot = 100;

Quant::Framework::Utils::Test::create_doc(
    'volsurface_moneyness',
    {
        underlying_config => $underlying_config,
        recorded_date     => Date::Utility->new,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'currency',
    {
        symbol           => $_,
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    }) for (qw/HKD USD/);

Quant::Framework::Utils::Test::create_doc(
    'index',
    {
        symbol           => $_,
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    }) for (qw(SPC HSI));

subtest 'get available strikes on surface' => sub {
    plan tests => 2;
    my $now     = Date::Utility->new('2012-06-14 08:00:00');
    my $surface = {
        'ON' => {smile => {100 => 0.1}},
        '1W' => {smile => {100 => 0.2}}};
    my $volsurface = Quant::Framework::VolSurface::Moneyness->new(
        underlying_config => $underlying_config,
        spot_reference    => $underlying_config_spot,
        surface           => $surface,
        recorded_date     => $now,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    );
    my $moneyness_points;
    lives_ok { $moneyness_points = $volsurface->smile_points } 'can call smile_points';
    is_deeply($moneyness_points, [100], 'get correct value for moneyness points');
};

subtest 'get surface spot reference' => sub {
    plan tests => 3;
    my $date = Date::Utility->new('2012-06-14 08:00:00');

    my $surface = {
        'ON' => {smile => {100 => 0.1}},
        '1W' => {smile => {100 => 0.2}},
    };
    my $volsurface = Quant::Framework::VolSurface::Moneyness->new(
        underlying_config => $underlying_config,
        surface           => $surface,
        recorded_date     => $date,
        spot_reference    => 100,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    );

    my $spot;
    lives_ok { $spot = $volsurface->spot_reference } 'can call spot reference of the surface';
    is($spot, 100, 'Got what I put in');
    ok(looks_like_number($spot), 'spot is a number');
};

subtest 'get_market_rr_bf' => sub {
    my $volsurface = Quant::Framework::VolSurface::Moneyness->new(
        underlying_config => $underlying_config,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    );
    lives_ok {
        my $rr_bf = $volsurface->get_market_rr_bf(7);
        ok exists $rr_bf->{ATM}, 'ATM exists';
        ok exists $rr_bf->{RR_25}, 'RR_25 exists';
        ok exists $rr_bf->{BF_25}, 'BF_25 exists';
    } 'get_market_rr_bf';
};

subtest 'minimum volatility spread' => sub {
    my $surface = {
        'ON' => {smile => {100 => 0.1}, vol_spread => {100 => 0.03, 90 => 0.04}},
        '2M' => {smile => {100 => 0.2}, vol_spread => {100 => 0.03, 90 => 0.02}},
    };
    my $volsurface = Quant::Framework::VolSurface::Moneyness->new(
        underlying_config => $underlying_config,
        surface           => $surface,
        recorded_date     => Date::Utility->new('2016-08-12'),
        spot_reference    => 100,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    );
    is $volsurface->get_smile_spread(1)->{100}, 0.03, 'returns untouched spread';
    is $volsurface->get_smile_spread(29)->{100}, 0.03, 'returns untouched spread';
    is $volsurface->get_spread({day => 29, sought_point => 'atm'}), 0.061, 'got the extra spread on top of raw spread';
    is $volsurface->get_spread({day => 30, sought_point => 'atm'}), 0.03, 'no extra spread if duration is 30 days or more';
    is $volsurface->get_spread({day => 1, sought_point => 'max'}), 0.04, 'got no extra spread is max is more than min spread';
    is $volsurface->get_spread({day => 29, sought_point => 'max'}), 0.0310344827586207, 'got the extra spread on top of raw spread';
};

done_testing;
