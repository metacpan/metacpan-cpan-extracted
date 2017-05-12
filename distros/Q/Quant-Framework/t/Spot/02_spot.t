use strict;
use warnings;

use Test::More tests => 9;
use Test::Warn;
use Test::Exception;
use Test::NoWarnings;

use Date::Utility;
use Quant::Framework::Utils::Test;
use Quant::Framework::Spot;
use Quant::Framework::Spot::Tick;


Cache::RedisDB::flushall();

my $underlying_config = Quant::Framework::Utils::Test::create_underlying_config('frxUSDJPY');
my $spot_source = Quant::Framework::Spot->new({
        underlying_config => $underlying_config,
    });

#initialize spot cache directly
Cache::RedisDB->set_nw('QUOTE', 'frxUSDJPY', Quant::Framework::Spot::Tick->new({
            quote => 150.192,
            epoch => 1467614365,
        })->as_hash);


is $spot_source->spot_tick->quote, 150.192, "correct fall-back to backup tick storage";
is $spot_source->spot_tick->epoch, 1467614365, "correct fall-back to backup tick storage";

#initialize spot cache through spot_source
$spot_source->set_spot_tick({ quote => 101.192, epoch => 190121 });
is $spot_source->spot_tick->quote, 101.192, "correct saved spot tick";

$spot_source->set_spot_tick(Quant::Framework::Spot::Tick->new({
            symbol => 'frxABCDEF',
            epoch  => 134,
            quote  => 119.102
        }));

is $spot_source->spot_tick->quote, '119.102', "correcty saved spot tick";
is $spot_source->spot_tick->epoch, 134, "correct tick epoch after retrieval";
is $spot_source->spot_quote, '119.102', "correct spot quote";
is $spot_source->spot_time, 134, "correct spot epoch";
is $spot_source->spot_age, time - 134, "correct spot age";



