use Test::Most qw(-Test::Deep);
use Test::MockObject::Extends;
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Moneyness;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $underlying_config = Quant::Framework::Utils::Test::create_underlying_config('SPC');

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
        symbol           => 'USD',
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'index',
    {
        symbol           => 'SPC',
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

my $recorded_date = Date::Utility->new('12-Jun-11');
my $surface       = {
    7 => {
        smile => {
            30    => 0.9044,
            40    => 0.8636,
            60    => 0.6713,
            80    => 0.4864,
            90    => 0.3348,
            95    => 0.2444,
            97.5  => 0.2017,
            100   => 0.1639,
            102.5 => 0.136,
            105   => 0.1501,
            110   => 0.2011,
            120   => 0.2926,
            150   => 0.408,
        },
        vol_spread => {100 => 0.1},
    },
    14 => {
        smile => {
            90  => 0.4,
            95  => 0.3,
            100 => 0.2,
            105 => 0.4,
            110 => 0.5
        },
        vol_spread => {100 => 0.1}
    },
};

my $v = Quant::Framework::VolSurface::Moneyness->new(
    underlying_config => $underlying_config,
    recorded_date     => $recorded_date,
    surface           => $surface,
    spot_reference    => 101,
    chronicle_reader  => $chronicle_r,
    chronicle_writer  => $chronicle_w,
);
my $from = $v->recorded_date;
my $to   = $from->plus_time_interval('7d');

subtest "can get volatility for strike, delta, and moneyness" => sub {
    plan tests => 3;
    lives_ok { $v->get_volatility({from => $from, to => $to, delta     => 25}) } "can get_volatility for delta point on a moneyness surface";
    lives_ok { $v->get_volatility({from => $from, to => $to, moneyness => 104}) } "can get_volatility for moneyness point on a moneyness surface";
    lives_ok { $v->get_volatility({from => $from, to => $to, strike    => 304.68}) } "can get_volatility for strike point on a moneyness surface";
};

subtest "cannot get volatility when underlying spot is undef" => sub {
    plan tests => 4;
    Quant::Framework::Utils::Test::create_doc(
        'volsurface_moneyness',
        {
            underlying_config => $underlying_config,
            spot_reference    => 101,
            recorded_date     => Date::Utility->new,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
        });
    throws_ok {
        Quant::Framework::VolSurface::Moneyness->new(
            underlying_config => $underlying_config,
            recorded_date     => $recorded_date,
            surface           => $surface,
            spot_reference    => undef,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
        );
    }
    qr/Attribute \(spot_reference\) does not pass the type constraint/, 'cannot get_volatility when spot for underlying is undef';
    my $v_new2;
    lives_ok {
        $v_new2 = Quant::Framework::VolSurface::Moneyness->new(
            underlying_config => $underlying_config,
            recorded_date     => $recorded_date,
            surface           => $surface,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
        );
    }
    'creates moneyness surface without spot reference';
    is($v_new2->spot_reference, 101, 'spot reference retrieved from database');
    lives_ok { $v_new2->get_volatility({from => $from, to => $to, delta => 35}) } "can get_volatility";
};

subtest "cannot get volatility for anything other than [strike, delta, moneyness]" => sub {
    plan tests => 1;
    throws_ok { $v->get_volatility({from => $from, to => $to, garbage => 25}) } qr/exactly one of/i,
        "cannot get_volatility for garbage point on a moneyness surface";
};

subtest "uses smile of the smallest available term structure when we need price for that" => sub {
    plan tests => 1;
    is(
        $v->get_volatility({
                moneyness => 100,
                from      => $from,
                to        => $from->plus_time_interval('1d'),
            }
        ),
        0.1639,
        "correct volatility value"
    );
};

subtest 'get volatility with invalid period' => sub {
    lives_ok {
        is $v->get_volatility({
                moneyness => 100,
                from      => $from,
                to        => $from,
            }), 0.01, 'get default 1% volatility';
        like ($v->validation_error, qr/Invalid request for get volatility/, 'volsurface validation error is set.');
    } 'do not die if get volatility is called with invalid period';
};

done_testing;
