use Test::Most;
use Test::FailWarnings;
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Moneyness;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $underlying_config = Quant::Framework::Utils::Test::create_underlying_config('IBEX35');

Quant::Framework::Utils::Test::create_doc(
    'currency',
    {
        symbol           => 'EUR',
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'index',
    {
        symbol           => 'IBEX35',
        date             => Date::Utility->new,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'volsurface_moneyness',
    {
        underlying_config => $underlying_config,
        recorded_date     => Date::Utility->new('12-Sep-12'),
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    });

subtest creates_moneyness_object => sub {
    plan tests => 4;
    lives_ok {
        Quant::Framework::VolSurface::Moneyness->new({
                underlying_config => $underlying_config,
                chronicle_reader  => $chronicle_r,
                chronicle_writer  => $chronicle_w,
            })
    }
    'creates moneyness surface with symbol hash';

    lives_ok {
        Quant::Framework::VolSurface::Moneyness->new({
                underlying_config => 'IBEX35',
                chronicle_reader  => $chronicle_r,
                chronicle_writer  => $chronicle_w,
            })
    }
    'symbol is not required';

    throws_ok {
        Quant::Framework::VolSurface::Moneyness->new(
            underlying_config => $underlying_config,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
            recorded_date     => '12-Sep-12'
        );
    }
    qr/Must pass both "surface_data" and "recorded_date" if passing either/, 'throws exception if only pass in recorded_date';

    throws_ok {
        Quant::Framework::VolSurface::Moneyness->new(
            underlying_config => $underlying_config,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
            surface           => {});
    }
    qr/Must pass both "surface_data" and "recorded_date" if passing either/, 'throws exception if only pass in surface';
};

subtest fetching_volsurface_data_from_db => sub {
    plan tests => 2;

    my $fake_surface = {1 => {smile => {100 => 0.1}}};
    my $fake_date = Date::Utility->new('12-Sep-12');

    Quant::Framework::Utils::Test::create_doc(
        'volsurface_moneyness',
        {
            underlying_config => $underlying_config,
            chronicle_reader  => $chronicle_r,
            chronicle_writer  => $chronicle_w,
            surface           => $fake_surface,
            recorded_date     => $fake_date,
        });

    my $vs = Quant::Framework::VolSurface::Moneyness->new({
        underlying_config => $underlying_config,
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
    });

    is_deeply($vs->surface, $fake_surface, 'surface is fetched correctly');
    is($vs->recorded_date->epoch, $fake_date->epoch, 'surface recorded_date is fetched correctly');
};

done_testing;
