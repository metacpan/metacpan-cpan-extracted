use Test::Most;
use Test::FailWarnings;
use Test::MockTime qw( set_absolute_time );
use Test::MockModule;
use File::Spec;
use JSON qw(decode_json);

use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::VolSurface::Utils;
use Quant::Framework::VolSurface::Delta;
use Quant::Framework::VolSurface::Moneyness;

my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();

my $date = Date::Utility->new('2016-05-25');
subtest "NY1700_rollover_date_on" => sub {
    plan tests => 2;
    my $date_apr = Date::Utility->new('12-APR-12 16:00');
    my $util     = Quant::Framework::VolSurface::Utils->new();
    is($util->NY1700_rollover_date_on($date_apr)->datetime, '2012-04-12 21:00:00', 'Correct rollover time in April');
    my $date_nov = Date::Utility->new('12-NOV-12 16:00');
    is($util->NY1700_rollover_date_on($date_nov)->datetime, '2012-11-12 22:00:00', 'Correct rollover time in November');
};

subtest "effective_date_for" => sub {
    plan tests => 2;
    my $date_apr = Date::Utility->new('12-APR-12 16:00');
    my $util     = Quant::Framework::VolSurface::Utils->new();
    is($util->effective_date_for($date_apr)->date, '2012-04-12', 'Correct effective date in April');
    my $date_nov = Date::Utility->new('12-NOV-12 16:00');
    $util = Quant::Framework::VolSurface::Utils->new();
    is($util->effective_date_for($date_nov)->date, '2012-11-12', 'Correct effective date in November');
};

done_testing;
