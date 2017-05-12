# -*- perl -*-

# t/15_subcommands.t

use strict;
use warnings;

use Test::More tests => 3+1;
use Test::NoWarnings;

use lib 't/testlib';

{
    package Test15;
    use MooseX::App;
}

{
    package Test15::Foo;
    use MooseX::App::Command;
    sub run { "running foo" }

    command_short_description "Toplevel command";
}

{
    package Test15::Foo::Bar;
    use MooseX::App::Command;
    sub run { "running bar" }

    command_short_description "Bar subcommand";
}

{
    package Test15::Foo::Baz;
    use MooseX::App::Command;
    sub run { "running baz" }

    command_short_description "Baz subcommand";
}


subtest 'Basic Subcommands' => sub {
    isa_ok(Test15->new_with_command( ARGV => [ 'foo' ] ),'Test15::Foo');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','bar' ] ),'Test15::Foo::Bar');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','baz' ] ),'Test15::Foo::Baz');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','qux' ] ),'Test15::Foo');
};

subtest 'Help Subcommand' => sub {
    my $help = Test15->new_with_command( ARGV => [ 'help' ] );
    isa_ok($help,'MooseX::App::Message::Envelope');
    is($help->blocks->[2]->header,'available commands:','Command headline set');
    is($help->blocks->[2]->body,"    foo      Toplevel command
    foo bar  Bar subcommand
    foo baz  Baz subcommand
    help     Prints this usage information",'Command body set');
};

subtest 'Help Parent' => sub {
    my $help = Test15->new_with_command( ARGV => [ 'foo','--help' ] );
    isa_ok($help,'MooseX::App::Message::Envelope');
    is($help->blocks->[3]->header,'available subcommands:','Command headline set');
    is($help->blocks->[3]->body,"    bar   Bar subcommand
    baz   Baz subcommand
    help  Prints this usage information",'Command body set');
};