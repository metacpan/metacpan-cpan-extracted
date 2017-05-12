# -*- perl -*-

# t/04_role_config.t - Test config role

use Test::Most tests => 4+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test01;

subtest 'Command with config' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --config t/config.pl)]);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');

    is($test01->global,'234','Arg from command config');
    is($test01->command_local1,'22','Arg from command config');
    isa_ok($test01->config,'Path::Class::File');
    is($test01->_config_data->{global}{global},'123','Config loaded');
};

subtest 'Another command with config' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_b --config t/config.pl --param_b bbb)]);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandB');
    is($test01->global,'123','Arg from command config');
};

subtest 'Command with config and argv' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --config t/config.pl --global 1234)]);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->global,'1234','Arg from command config');
    is($test01->command_local1,'22','Arg from command config');
};

subtest 'Missing config' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --config t/nosuchfile.pl --global 1234)]);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    like($test01->blocks->[0]->header,qr/Could not find/,'Error message set');
};
