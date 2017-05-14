use Test::More tests => 18;

BEGIN {
    use_ok('Riak::Light');
    use_ok('Riak::Light::PBC');
    use_ok('Riak::Light::Connector');
    use_ok('Riak::Light::Driver');
    use_ok('Riak::Light::Timeout');
    use_ok('Riak::Light::Timeout::Alarm');
    use_ok('Riak::Light::Timeout::Select');
    use_ok('Riak::Light::Timeout::SelectOnRead');
    use_ok('Riak::Light::Timeout::TimeOut');
}

require_ok('Riak::Light');
require_ok('Riak::Light::PBC');
require_ok('Riak::Light::Connector');
require_ok('Riak::Light::Driver');
require_ok('Riak::Light::Timeout');
require_ok('Riak::Light::Timeout::Alarm');
require_ok('Riak::Light::Timeout::Select');
require_ok('Riak::Light::Timeout::SelectOnRead');
require_ok('Riak::Light::Timeout::TimeOut');
