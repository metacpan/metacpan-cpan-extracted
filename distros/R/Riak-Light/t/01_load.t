use Test::More tests => 1;

my $ok;
END { BAIL_OUT "Could not load all modules" unless $ok }
use Riak::Light;
use Riak::Light::PBC;
use Riak::Light::Connector;
use Riak::Light::Driver;
use Riak::Light::Timeout;
use Riak::Light::Timeout::Alarm;
use Riak::Light::Timeout::Select;
use Riak::Light::Timeout::SelectOnRead;
use Riak::Light::Timeout::TimeOut;
use Riak::Light::Util;

ok 1, 'All modules loaded successfully';
$ok = 1;
