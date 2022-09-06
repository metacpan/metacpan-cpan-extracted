use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Log::Any::Test;
use Log::Any qw($log);
use Log::Any::Adapter qw(TAP);

BEGIN { *CORE::GLOBAL::exit = sub(;$) { pass("called exit"); } }

use Myriad::Config;

my %defaults = %Myriad::Config::DEFAULTS;
my @regular_config = grep !ref $defaults{$_}, keys %defaults;
my %shortcuts = %Myriad::Config::FULLNAME_FOR;

subtest 'It should parse commandline args correctly' => sub {
    my $config = Myriad::Config->new();
    my $args = ['--bad-key', 'value'];

    # Bad keys
    exception { $config->lookup_from_args($args) };
    $log->contains_ok(qr/don't know how to deal with.*bad-key/, 'bad-key was reported');

    # Parse full options
    $args = [ map { "--" . $_ => 'test_value' } @regular_config ];
    $config->lookup_from_args($args);

    is($config->key($_), 'test_value' , "config $_ has been set correctly") for @regular_config;

    # Parse short
    $args = [ map { "-" . $_ => 'test_value' } keys %shortcuts ];
    $config->lookup_from_args($args);

    is($config->key($_), 'test_value' , "config $_ has been set correctly from shortcut") for values %shortcuts;

    # key=value format should be accepted
    $args = ['--transport=anything'];
    $config->lookup_from_args($args);

    is($config->key('transport'), 'anything', 'key=value format is parsed correctly');

    # Stops at the correct place
    $args = ['--transport', 'memory', '-lib', '/code', 'service'];

    $config->lookup_from_args($args);
    cmp_deeply($args, ['service'], 'only args has been consumed');

    subtest 'It should parse service related config correctly' => sub {

        # We try to configure the same
        my $is_service_config_ok = sub {
            my $args = shift;
            $config->lookup_from_args($args);
            my $service_config = $config->key('services');
            ok($service_config->{'fake.name'}, 'service name been captured correctly');
            is($service_config->{'fake.name'}->{config}->{key}, 'value', 'service config been parsed correctly') or note explain $service_config;
        };

        # Dynamically parsing service config using . format
        $config = Myriad::Config->new;
        $args = ['--service.fake.name.config.key', 'value'];
        $is_service_config_ok->($args);

        # Dynamically parsing service config using _ format
        $config = Myriad::Config->new;
        $args = ['--service_fake_name_config_key', 'value'];
        $is_service_config_ok->($args);

        my $is_service_instance_ok = sub {
            my $args = shift;
            $config->lookup_from_args($args);
            my $service_config = $config->key('services');
            ok($service_config->{'fake.name'}, 'service name been captured correctly');
            my $instance_config = $service_config->{'fake.name'}->{instance};

            ok($instance_config->{demo}, 'instance name been captured correctly');
            is($instance_config->{demo}->{config}->{new_key}, 'value', 'service config been parsed correctly');
        };

        # Dynamically parse instance config using . format
        $config = Myriad::Config->new;
        $args = ['--service.fake.name.instance.demo.config.new_key', 'value'];
        $is_service_instance_ok->($args);

        # Dynamically parsing instance config using _ format
        $config = Myriad::Config->new;
        $args = ['--service_fake_name_instance_demo_config_new_key', 'value'];
        $is_service_instance_ok->($args);

        # We should be able to use service (single) and instnace (single)
        $config = Myriad::Config->new;
        $args = ['--service_fake_name_instance_demo_config_new_key', 'value'];
        $is_service_instance_ok->($args);

    };
    done_testing;
};

subtest 'It should read config from ENV correctly' => sub {
    my $config = Myriad::Config->new;
    $config->clear_all;

    # To detect standard config from ENV
    local %ENV = %ENV;
    $ENV{"MYRIAD_$_"} = 'test_value' for map {uc($_)} @regular_config;
    is(exception {
        $config->lookup_from_env();
    }, undef, 'handle global configuration from environment');

    is($config->key($_), 'test_value' , "config $_ has been set correctly") for @regular_config;

    # To pass services' config
    $ENV{'MYRIAD_SERVICE_FAKE_NAME_CONFIG_ENV_KEY'} = 'value from env';
    is(exception {
        $config->lookup_from_env();
    }, undef, 'handle service configuration from environment');

    my $services_config = $config->key('services');
    ok($services_config->{'fake.name'}, 'service name parsed correctly');
    is($services_config->{'fake.name'}->{config}->{env_key}, 'value from env', 'service config has been parsed correctly');

    $config->clear_all();

    # To parse instance config
    $ENV{'MYRIAD_SERVICE_FAKE_NAME_INSTANCE_DEMO_CONFIG_ENV_KEY'} = 'instance value from env';
    $config->lookup_from_env();

    $services_config = $config->key('services');
    ok($services_config->{'fake.name'}, 'service name parsed correctly');
    ok(my $instance_config = $services_config->{'fake.name'}->{instance}->{demo}, 'service instance has been parsed correctly');
    is($instance_config->{config}->{env_key}, 'instance value from env', 'instance config has been parsed correctly');
    done_testing;
};

subtest 'It should read config from config file correctly' => sub {
    my $config = Myriad::Config->new;

    $config->clear_key('transport');
    $config->clear_key('services');
    $config->lookup_from_file('t/config.yml');

    is($config->key('transport'), 'value_from_file', 'framework config has been passed correctly');
    is($config->key('services')->{'fake.name'}->{config}->{key}, 'value from file', 'services config has been passed correctly');
    is($config->key('services')->{'fake.name'}->{instance}->{demo}->{config}->{key}, 'instance value from file', 'instance config has been passed correctly');
    done_testing;
};

subtest 'It should keep config source priority correct' => sub {
    local %ENV = %ENV;
    # commandline args should take over ENV
    $ENV{MYRIAD_TRANSPORT} = 'env_prio';
    my $args = ['--transport', 'cmd_prio'];

    my $config = Myriad::Config->new(commandline => $args);
    is($config->key('transport'), 'cmd_prio', 'command line priority is more than the env variables');

    # Env should take over file
    $args = ['--config_path', 't/config.yml'];
    $ENV{MYRIAD_TRANSPORT} = 'env_prio';

    $config = Myriad::Config->new(commandline => $args);
    is($config->key('transport'), 'env_prio', 'env variables priority is more than the file data');

    # File take over defaults
    $args = ['--config_path', 't/config.yml'];
    delete $ENV{MYRIAD_TRANSPORT};

    $config = Myriad::Config->new(commandline => $args);
    is($config->key('transport'), 'value_from_file', 'config file priority is more than the default values');

    # Default by default
    $config = Myriad::Config->new();
    is($config->key('transport'), $defaults{'transport'}, 'default is correct');
    done_testing;
};

subtest 'Special config shortcuts' => sub {
    subtest 'framework config should be returend as Ryu::Obvervable' => sub {
        my $config = Myriad::Config->new();
        isa_ok($config->key('transport'), 'Ryu::Observable', 'correct config container');
        done_testing;
    };

    subtest 'It should infer transport and address' => sub {
        my $args = ['--transport', 'redis://somehost:1111'];
        my $config = Myriad::Config->new(commandline => $args);

        is($config->key('transport'), 'redis', 'correct transport type');
        is($config->key('transport_redis'), 'redis://somehost:1111', 'correct uri for the correct transport');
        done_testing;
    };

    subtest 'It should configure all transport type implicitly' => sub {
        my $args = ['--transport', 'memory'];
        my $config = Myriad::Config->new(commandline => $args);

        is($config->key('rpc_transport'), 'memory', 'correct rpc transport');
        is($config->key('subscription_transport'), 'memory', 'correct subscription transport');
        is($config->key('storage_transport'), 'memory', 'correct storage transport');
        done_testing;
    };
    done_testing;
};

done_testing;

