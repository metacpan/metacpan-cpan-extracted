# -*- perl -*-

# t/01_basic.t - Basic tests

use Test::Most tests => 12+1;
use Test::NoWarnings;

use FindBin qw();
use lib 't/testlib';

use Test01;

subtest 'Excact command with option' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --global 10)]);
    my $test01 = Test01->new_with_command();
    isa_ok($test01,'Test01::CommandA');
    is($test01->global,10,'Param is set');
};

subtest 'Fuzzy command with option' => sub {
    my $test02 = Test01->new_with_command( ARGV => [qw(Command_A --globa 11)]);
    isa_ok($test02,'Test01::CommandA');
    is($test02->global,11,'Param is set');
};

subtest 'Wrong command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(xxxx --global 10)]);
    my $test03 = Test01->new_with_command;
    isa_ok($test03,'MooseX::App::Message::Envelope');
    is($test03->blocks->[0]->header,"Unknown command 'xxxx'",'Message is set');
    is($test03->blocks->[0]->type,"error",'Message is of type error');
    is($test03->blocks->[1]->header,"usage:",'Usage set');
    is($test03->blocks->[1]->body,"    01_basic.t <command> [long options...]
    01_basic.t help
    01_basic.t <command> --help",'Usage body set');
    is($test03->blocks->[3]->header,"global options:",'Global options set');
    is($test03->blocks->[3]->body,"    --global              test [Required; Integer; Important!]
    --config              Path to command config file
    --help -h --usage -?  Prints this usage information. [Flag]",'Global options body set');
    is($test03->blocks->[4]->header,"available commands:",'Available commands set');
    is($test03->blocks->[4]->body,"    command_a   Command A!
    command_b   Test class command B for test 01
    command_c1  Test C1
    command_d   Command A!
    help        Prints this usage information",'Available commands body set');
};

subtest 'Help for command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --help)]);
    my $test04 = Test01->new_with_command;
    isa_ok($test04,'MooseX::App::Message::Envelope');
    is($test04->blocks->[0]->header,"usage:",'Usage is set');
    is($test04->blocks->[0]->body,"    01_basic.t command_a [long options...]
    01_basic.t help
    01_basic.t command_a --help",'Usage body set');
    is($test04->blocks->[1]->header,"description:",'Description is set');
    is($test04->blocks->[1]->body,"    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras dui velit,
    varius nec iaculis vitae, elementum eget mi.
    * bullet1
    * bullet2
    * bullet3
    Cras eget mi nisi. In hac habitasse platea dictumst.",'Description body set');
    is($test04->blocks->[2]->header,"options:",'Options header is set');
    is($test04->blocks->[2]->body,"    --global              test [Required; Integer; Important!]
    --command_local1      some docs about the long texts that seem to occur
                          randomly [Integer; Env: LOCAL1; Important]
    --command_local2      Verylongwordwithoutwhitespacestotestiftextformating
                          worksproperly [Env: LOCAL2]
    --config              Path to command config file
    --help -h --usage -?  Prints this usage information. [Flag]",'Options body is set');
};

subtest 'With extra args' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(Command_b --global 10 --param_b aaa)]);
    my $test02 = Test01->new_with_command( 'param_b' => 'bbb', 'global' => 20, 'private'=>5  );
    isa_ok($test02,'Test01::CommandB');
    is($test02->global,20,'Param global is set');
    is($test02->param_b,'bbb','Param param_b is set');
    is($test02->private,5,'Param private is set');
};

subtest 'Wrapper script' => sub {
    my $output = `$^X $FindBin::Bin/example/test01.pl command_a --command_local2 test --global 10`;
    is($output,'RUN COMMAND-A:test','Output is ok');
};

subtest 'Custom help text' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_b --help)]);
    my $test06 = Test01->new_with_command;
    isa_ok($test06,'MooseX::App::Message::Envelope');
    is($test06->blocks->[0]->header,"usage:",'Usage is set');
    is($test06->blocks->[0]->body,"    use with care",'Usage is ok');
    is($test06->blocks->[1]->header,"description:",'description is set');
    like($test06->blocks->[1]->body,qr/    Some description of \*command B\*/,'Description is ok');
};

subtest 'Input errors missing' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1)]);
    my $test07 = Test01->new_with_command;
    isa_ok($test07,'MooseX::App::Message::Envelope');
    is($test07->blocks->[0]->header,"Missing value for 'command_local1'",'Error message ok');
};

subtest 'Input errors type' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1 sss)]);
    my $test08 = Test01->new_with_command;
    isa_ok($test08,'MooseX::App::Message::Envelope');
    is($test08->blocks->[0]->header,"Invalid value for 'command_local1'",'Error message ok');
    is($test08->blocks->[0]->body,"Value must be an integer (not 'sss')",'Error message ok');
};

subtest 'Global help requested' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(help)]);
    my $test09 = Test01->new_with_command;
    isa_ok($test09,'MooseX::App::Message::Envelope');
    like($test09->blocks->[0]->body,qr/    01_basic\.t <command> \[long options\.\.\.\]/,'Help message ok');
};

subtest 'Missing command' => sub {
    MooseX::App::ParsedArgv->new(argv => []);
    my $test10 = Test01->new_with_command;
    isa_ok($test10,'MooseX::App::Message::Envelope');
    is($test10->blocks->[0]->header,'Missing command','Error message ok');
};

subtest 'Extra params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a something else)]);
    my $test11 = Test01->new_with_command;
    isa_ok($test11,'MooseX::App::Message::Envelope');
    is($test11->blocks->[0]->header,"Unknown parameter 'else'",'Error message ok');
};

