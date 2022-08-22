#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

use Test::More;

my $TEST_NAME = 'COMMAND';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_Command_test->runtests();
    exit(0);
}

package Term_CLI_Command_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use FindBin 1.50;
use Term::CLI::ReadLine;
use Term::CLI::Command;
use Term::CLI::Argument::Enum;

my $CMD_NAME = 'show';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;

    my $cmd = Term::CLI::Command->new(
        name => $CMD_NAME,
        options => ['long|l', 'level|L', 'verbose|v+'],
        commands => [
            Term::CLI::Command->new(name => 'time'),
            Term::CLI::Command->new(name => 'date',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ]
            ),
            Term::CLI::Command->new(name => 'debug',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ],
            ),
            Term::CLI::Command->new(name => 'parameter',
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'param',
                        value_list => [qw( timeout maxlen prompt )]
                    ),
                    Term::CLI::Argument::Enum->new(name => 'channel',
                        value_list => [qw( in out )]
                    ),
                ]
            ),
        ]
    );

    isa_ok( $cmd, 'Term::CLI::Command',
            'Term::CLI::Command->new' );

    $self->{cmd} = $cmd;
    return;
}

sub check_constructor: Test(2) {
    my $self = shift;

    throws_ok
        { Term::CLI::Command->new() }
        qr/Missing required arguments: name/,
        'error on missing name';

    my $obj = Term::CLI::Command->new(
        name => $CMD_NAME,
        options => ['long|l', 'level|L', 'verbose|v+'],
        commands => [ Term::CLI::Command->new(name => 'parameter') ],
        arguments => [
            Term::CLI::Argument::Enum->new(name => 'param',
                value_list => [qw( timeout maxlen prompt )]
            ),
        ]
    );
    ok($obj, 'command takes both commands and arguments');
    return;
}

sub check_state: Test(3) {
    my $self = shift;
    my $cmd = $self->{cmd};

    my $got = $cmd->state;
    is_deeply( $got, {}, 'state returns an empty HashRef' );

    $cmd->state->{'flag'} = 123;

    is( $cmd->state->{'flag'}, 123,
        'state is stored and retrieved correctly' );

    $cmd->clear_state;
    is( int(keys %{$cmd->state}), 0,
        'state is cleared on clear_state');
}

sub check_arguments: Test(4) {
    my $self = shift;
    my $cmd = $self->{cmd};

    my $sub = $cmd->find_command('param');
    ok($sub, 'command has sub-command "param"');

    my @got;
    @got = $cmd->argument_names;
    is(scalar(@got), 0, 'top-level command has no arguments');

    ok(!defined $sub->find_command('x'),
        'command with no sub-commands will find_command nothing');

    @got = $sub->argument_names;
    is_deeply(\@got, [qw(param channel)],
            'sub-command has arguments: (param channel)')
    or diag("argument_names returned: (", join(", ", map {"'$_'"} @got), ")");
    return;
}


sub simple_command: Test(4) {
    my $self = shift;
    my $cmd = Term::CLI::Command->new( name => $CMD_NAME );
    isa_ok( $cmd, 'Term::CLI::Command', 'Term::CLI::Command->new' );
    is_deeply( [$cmd->command_names], [], 'simple command has no command_names' );
    is_deeply( [$cmd->option_names], [], 'simple command has no option_names' );
    is_deeply( [$cmd->argument_names], [], 'simple command has no argument_names' );
    return;
}


sub check_attributes: Test(1) {
    my $self = shift;
    my $cmd = $self->{cmd};
    is( $cmd->name, $CMD_NAME, "name attribute is $CMD_NAME" );
    return;
}


sub check_complete_command: Test(5) {
    my $self = shift;
    my $cmd = $self->{cmd};

    my @command_names = $cmd->command_names;

    my ($text, @cmd_line);
    my @got;

    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, \@command_names,
        "complete returns (@command_names) for ()")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @cmd_line = (q{});
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, \@command_names,
        "complete returns (@command_names) for ''")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @cmd_line = (q{d});
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [qw(date debug)],
        "complete returns (date debug) for 'd'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @cmd_line = (q{t});
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [qw(time)],
        "complete returns (time) for 't'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @cmd_line = (q{X});
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [],
        "complete returns () for 'X'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");
    return;
}


sub check_complete_options: Test(5) {
    my $self = shift;
    my $cmd = $self->{cmd};

    my @option_names = $cmd->option_names;

    my @got;

    @got = $cmd->complete('-');
    is_deeply( \@got, \@option_names,
        "complete returns (@option_names) for '-'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @got = $cmd->complete('--');
    @option_names = grep { /^--/ } $cmd->option_names;
    is_deeply( \@got, \@option_names,
        "complete returns (@option_names) for '--'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    @got = $cmd->complete('--v');
    @option_names = grep { /^--v/ } $cmd->option_names;
    is_deeply( \@got, \@option_names,
        "complete returns (@option_names) for '--v'")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");

    # The "--" should end the list of options, so a complete should
    # return the list of sub-commands.
    @got = $cmd->complete('', { unprocessed => ['--'] } );
    my @command_names = $cmd->command_names;
    is_deeply( \@got, \@command_names,
        "complete returns (@command_names) for ('-- ')")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");


    # After a "--", the "--v" should not be seen as a (partial) option,
    # and "normal" completion should commence; in this case, it should
    # result in an empty list.
    @got = $cmd->complete('--v', { unprocessed => ['--'] });
    is_deeply( \@got, [],
        "complete returns () for ('-- --v')")
    or diag("complete returned: (", join(", ", map {"'$_'"} @got), ")");
    return;
}


sub check_ambiguous_complete: Test(3) {
    my $self = shift;
    my $cmd = $self->{cmd};

    # "show debug|date";

    my ($text, @cmd_line);
    my @got;

    @cmd_line = qw( d );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [qw( date debug )],
        "complete returns (date debug) for (d)" );

    @cmd_line = qw( d o );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [],
        "complete returns () for (d o)" );

    @cmd_line = qw( de o );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, ['out'],
        "complete returns (out) for (de o)" );
    return;
}


sub check_complete_show_param: Test(3) {
    my $self = shift;
    my $cmd = $self->{cmd};

    # "show param {timeout|maxlen|prompt}";

    my @got;
    my @cmd_line;
    my $text;

    @cmd_line = qw( --verbose param time );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, ['timeout'],
        "complete returns (timeout) for (--verbose param time)" );

    @cmd_line = qw( --verbose param time i );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, ['in'],
        "complete returns (in) for (--verbose param time i)" );

    @cmd_line = qw( --verbose param time in useless );
    $text = pop @cmd_line;
    @got = $cmd->complete($text, { unprocessed => [@cmd_line] });
    is_deeply( \@got, [],
        "complete returns () for (--verbose param time in useless)" );
    return;
}

}
Main();
