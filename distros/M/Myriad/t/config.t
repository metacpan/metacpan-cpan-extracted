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
my %shortcuts = %Myriad::Config::FULLNAME_FOR;

subtest 'It should parse commandline args correctly' => sub {
    my $configs = Myriad::Config->new();
    my $args = ['--bad-key', 'value'];

    # Bad keys
    exception { $configs->lookup_from_args($args) };
    $log->contains_ok(qr/don't know how to deal with.*bad-key/, 'bad-key was reported');

    # Parse full options
    $args = [ map { "--" . $_ => 'test_value' } keys %defaults ];
    $configs->lookup_from_args($args);

    is($configs->key($_), 'test_value' , "config $_ has been set correctly") for keys %defaults;

    # Parse short
    $args = [ map { "-" . $_ => 'test_value' } keys %shortcuts ];
    $configs->lookup_from_args($args);

    is($configs->key($_), 'test_value' , "config $_ has been set correctly from shortcut") for values %shortcuts;

    # key=value format should be accepted
    $args = ['--transport=anything'];
    $configs->lookup_from_args($args);

    is($configs->key('transport'), 'anything', 'key=value format is parsed correctly');

    # Stops at the correct place
    $args = ['--transport', 'memory', '-lib', '/code', 'service'];

    $configs->lookup_from_args($args);
    cmp_deeply($args, ['service'], 'only args has been consumed');

    subtest 'It should parse service related config correctly' => sub {

        # We try to configure the same
        my $is_service_config_ok = sub {
            my $args = shift;
            $configs->lookup_from_args($args);
            my $service_configs = $configs->key('services');
            ok($service_configs->{'fake.name'}, 'service name been captured correctly');
            is($service_configs->{'fake.name'}->{configs}->{key}, 'value', 'service config been parsed correctly');
        };

        # Dynamically parsing services config using . format
        $configs = Myriad::Config->new;
        $args = ['--services.fake.name.configs.key', 'value'];
        $is_service_config_ok->($args);

        # Dynamically parsing services config using _ format
        $configs = Myriad::Config->new;
        $args = ['--services_fake_name_configs_key', 'value'];
        $is_service_config_ok->($args);

        # We should be able to use service (single) and config (single)
        $configs = Myriad::Config->new;
        $args = ['--service_fake_name_config_key', 'value'];
        $is_service_config_ok->($args);

        my $is_service_instance_ok = sub {
            my $args = shift;
            $configs->lookup_from_args($args);
            my $service_configs = $configs->key('services');
            ok($service_configs->{'fake.name'}, 'service name been captured correctly');
            my $instance_configs = $service_configs->{'fake.name'}->{instances};

            ok($instance_configs->{demo}, 'instance name been captured correctly');
            is($instance_configs->{demo}->{configs}->{new_key}, 'value', 'service config been parsed correctly');
        };

        # Dynamically parse instance config using . format
        $configs = Myriad::Config->new;
        $args = ['--services.fake.name.instances.demo.configs.new_key', 'value'];
        $is_service_instance_ok->($args);

        # Dynamically parsing instance config using _ format
        $configs = Myriad::Config->new;
        $args = ['--services_fake_name_instances_demo_configs_new_key', 'value'];
        $is_service_instance_ok->($args);

        # We should be able to use service (single) and instnace (single)
        $configs = Myriad::Config->new;
        $args = ['--service_fake_name_instance_demo_config_new_key', 'value'];
        $is_service_instance_ok->($args);

    };
};

subtest 'It should read config from ENV correctly' => sub {
    my $configs = Myriad::Config->new;
    $configs->clear_all;

    # To detect standard config from ENV
    $ENV{"MYRIAD_$_"} = 'test_value' for map {uc($_)} keys %defaults;
    $configs->lookup_from_env();

    is($configs->key($_), 'test_value' , "config $_ has been set correctly") for keys %defaults;

    # To pass services' configs
    $ENV{'MYRIAD_SERVICES_FAKE_NAME_CONFIGS_ENV_KEY'} = 'value from env';
    $configs->lookup_from_env();

    my $services_config = $configs->key('services');
    ok($services_config->{'fake.name'}, 'service name parsed correctly');
    is($services_config->{'fake.name'}->{configs}->{env_key}, 'value from env', 'service config has been parsed correctly');

    $configs->clear_all();

    # To parse instances config
    $ENV{'MYRIAD_SERVICES_FAKE_NAME_INSTANCES_DEMO_CONFIGS_ENV_KEY'} = 'instance value from env';
    $configs->lookup_from_env();

    $services_config = $configs->key('services');
    ok($services_config->{'fake.name'}, 'service name parsed correctly');
    ok(my $instance_configs = $services_config->{'fake.name'}->{instances}->{demo}, 'service instance has been parsed correctly');
    is($instance_configs->{configs}->{env_key}, 'instance value from env', 'instance config has been parsed correctly');
};

subtest 'It should read config from config file correctly' => sub {
    my $configs = Myriad::Config->new;

    $configs->clear_key('transport');
    $configs->clear_key('services');
    $configs->lookup_from_file('t/config.yml');

    is($configs->key('transport'), 'value_from_file', 'framework config has been passed correctly');
    is($configs->key('services')->{'fake.name'}->{configs}->{key}, 'value from file', 'services config has been passed correctly');
    is($configs->key('services')->{'fake.name'}->{instances}->{demo}->{configs}->{key}, 'instance value from file', 'instance config has been passed correctly');
};

subtest 'It should keep configs source priority correct' => sub {
    # commandline args should take over ENV
    $ENV{MYRIAD_TRANSPORT} = 'env_prio';
    my $args = ['--transport', 'cmd_prio'];

    my $configs = Myriad::Config->new(commandline => $args);
    is($configs->key('transport'), 'cmd_prio', 'command line priority is more than the env variables');

    # Env should take over file
    $args = ['--config_path', 't/config.yml'];
    $ENV{MYRIAD_TRANSPORT} = 'env_prio';

    $configs = Myriad::Config->new(commandline => $args);
    is($configs->key('transport'), 'env_prio', 'env variables priority is more than the file data');

    # File take over defaults
    $args = ['--config_path', 't/config.yml'];
    delete $ENV{MYRIAD_TRANSPORT};

    $configs = Myriad::Config->new(commandline => $args);
    is($configs->key('transport'), 'value_from_file', 'config file priority is more than the default values');

    # Default by default
    $configs = Myriad::Config->new();
    is($configs->key('transport'), $defaults{'transport'}, 'default is correct');
};

subtest 'Special config shortcuts' => sub {
    subtest 'framework config should be returend as Ryu::Obvervable' => sub {
        my $configs = Myriad::Config->new();
        isa_ok($configs->key('transport'), 'Ryu::Observable', 'correct config container');
    };

    subtest 'It should infer transport and address' => sub {
        my $args = ['--transport', 'redis://somehost:1111'];
        my $configs = Myriad::Config->new(commandline => $args);

        is($configs->key('transport'), 'redis', 'correct transport type');
        is($configs->key('transport_redis'), 'redis://somehost:1111', 'correct uri for the correct transport');
    };

    subtest 'It should configure all transport type implicitly' => sub {
        my $args = ['--transport', 'memory'];
        my $configs = Myriad::Config->new(commandline => $args);

        is($configs->key('rpc_transport'), 'memory', 'correct rpc transport');
        is($configs->key('subscription_transport'), 'memory', 'correct subscription transport');
        is($configs->key('storage_transport'), 'memory', 'correct storage transport');
    };
};

done_testing;

