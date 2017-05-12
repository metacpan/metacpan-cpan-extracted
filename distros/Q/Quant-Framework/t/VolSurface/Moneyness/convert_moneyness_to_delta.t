use Test::Most;
use Test::FailWarnings;

use List::Util qw(shuffle);
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Moneyness;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $underlying_config = Quant::Framework::Utils::Test::create_underlying_config('IBEX35');

my $when = Date::Utility->new;

my $r = {
    7   => 0.44,
    30  => 0.41,
    90  => 0.71,
    180 => 1.01,
    270 => 0.87,
    365 => 0.98,
};
my $q = {
    7   => 0.32249,
    30  => 0.200438,
    90  => 0.120704,
    180 => 0.071955,
    270 => 0.083472,
    365 => 0.065841,
};

Quant::Framework::Utils::Test::create_doc(
    'currency',
    {
        symbol           => 'EUR',
        rates            => $r,
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });
Quant::Framework::Utils::Test::create_doc(
    'index',
    {
        symbol           => 'IBEX35',
        date             => Date::Utility->new,
        rates            => $q,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });
Quant::Framework::Utils::Test::create_doc(
    'volsurface_delta',
    {
        underlying_config => $underlying_config,
        recorded_date     => Date::Utility->new,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    });

subtest "convert moneyness to delta" => sub {
    plan tests => 6;

    my $smile = {
        100 => 0.2781706925,
        101 => 0.2745433458,
        102 => 0.2709204185,
        103 => 0.2673091695,
        104 => 0.2637163519,
        105 => 0.182182369,
        106 => 0.1878046744,
        107 => 0.195581881,
        108 => 0.2050003166,
        109 => 0.2154778087,
        110 => 0.2264321512,
        90  => 0.3110673914,
        91  => 0.3084866463,
        92  => 0.3056723805,
        93  => 0.3026373821,
        94  => 0.2994163006,
        95  => 0.2960460985,
        96  => 0.2925637385,
        97  => 0.2890061831,
        98  => 0.2854096085,
        99  => 0.2817951997,
    };
    my $surface = {
        7  => {smile => $smile},
        14 => {smile => $smile},
    };
    my $calculated_delta_from_csv = {
        75 => 0.2875,
        50 => 0.2779,
        25 => 0.2668,
    };

    my $recorded_date = Date::Utility->new;
    my $v             = Quant::Framework::VolSurface::Moneyness->new(
        underlying_config => $underlying_config,
        recorded_date     => $recorded_date,
        surface           => $surface,
        spot_reference    => 7099.7,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    );

    lives_ok { $v->_convert_moneyness_smile_to_delta(7) } "can convert moneyness smile to delta smile";
    throws_ok { $v->_convert_moneyness_smile_to_delta('asd') } qr/must be a number/,
        "from and to dates must be defined";

    my $deltas = $v->_convert_moneyness_smile_to_delta(7);

    my $BOM_25 = $v->get_volatility({
        delta => 25,
        from  => $v->recorded_date,
        to    => $v->effective_date->plus_time_interval('7d'),
    });
    my $BOM_50 = $v->get_volatility({
        delta => 50,
        from  => $v->recorded_date,
        to    => $v->effective_date->plus_time_interval('7d'),
    });
    my $BOM_75 = $v->get_volatility({
        delta => 75,
        from  => $v->recorded_date,
        to    => $v->effective_date->plus_time_interval('7d'),
    });
    cmp_ok(abs($BOM_25 - $calculated_delta_from_csv->{25}), "<=", 0.0005, "correct 25D vol");
    cmp_ok(abs($BOM_50 - $calculated_delta_from_csv->{50}), "<=", 0.0005, "correct 50D vol");
    cmp_ok(abs($BOM_75 - $calculated_delta_from_csv->{75}), "<=", 0.0005, "correct 75D vol");
    my @shuffled_deltas = shuffle(keys %{$deltas});
    is(
        $v->get_volatility({
                delta => $shuffled_deltas[0],
                from  => $v->recorded_date,
                to    => $v->recorded_date->plus_time_interval('7d'),
            }
        ),
        $deltas->{$shuffled_deltas[0]},
        "return corresponding volatility if sought delta is on smile"
    );

};

done_testing;
