use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Log::Any::Adapter qw(TAP);

use Myriad::Config;

my %defaults = %Myriad::Config::DEFAULTS;
subtest "Test order configuration applying preference" => sub {
    # - commandline parameter
    # - environment
    # - config file
    # - defaults

    # Defaults
    my $config = Myriad::Config->new;
    # Those are meant to be set to transport as default
    @defaults{qw(rpc_transport subscription_transport storage_transport)} = ($defaults{'transport'}) x 3;
    is($config->key($_), $defaults{$_}, "$_ defaults are set fine") for keys %defaults;

    # Config file
    my $test_config_file = 't/config.yml';
    $config = Myriad::Config->new(commandline => ['--config_path', $test_config_file]);
    # Remove config_path from defaults and check it separately
    my $config_file = delete $defaults{'config_path'};
    delete $defaults{transport_cluster};
    is($config->key('transport_cluster'), 1, 'was able to set correct transport_cluster');
    is($config->key($_), 'config_test', "$_ from config_file are set fine") for keys %defaults;
    like($config->key('config_path'), qr/$test_config_file/, 'config_path has been set correctly');
    # Keep it removed since we are still using config_file in next test
    #$defaults{'config_path'} = $config_file;

    # ENV
    $ENV{'MYRIAD_'.uc($_)} = 'ENV' for keys %defaults;
    $config = Myriad::Config->new(commandline => ['--config_path', $test_config_file]);
    # We are still passing config file, but ENV have higher priority
    is($config->key($_), 'ENV', "$_ from ENV are set fine") for keys %defaults;

    # Commandline (Highest priority)
    # Set all parameters to test_command_param
    my $comm_test_string = 'test_command_param';
    $defaults{'config_path'} = $config_file;
    my @command_line = map {('--'.$_, $comm_test_string)} keys %defaults;
    $config = Myriad::Config->new(commandline => \@command_line);
    is($config->key($_),$comm_test_string, "$_ overridden by commandline options" ) for keys %defaults;
};

subtest "Test other functionality" => sub {

    $ENV{'MYRIAD_LIBRARY_PATH'} = '/test/path/included';
    my @before_inc = @INC;
    my $config = new_ok('Myriad::Config');
    my $config_meta = $config->META;

    my $config_slot = $config_meta->get_slot('$config')->value($config);
    isa_ok( $config_slot->{$_}, 'Ryu::Observable', "$_ Config Slot is set") for keys %defaults;

    # test define functionality
    $config->define('test', 'test_value');
    like(exception{ $config->define('config_path', 'will not work') }, qr/already exists/, 'Not allowed to redefine');
    like($config->key('test'), qr/test_value/, 'Able to add new keys to config');

    # Test that we have updated @INC
    push @before_inc, '/test/path/included';
    cmp_set(\@INC, \@before_inc, 'Updated @INC with configured path');
};

done_testing;
