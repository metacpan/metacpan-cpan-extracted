#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_test->runtests();
}

package Term_CLI_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI;
use Term::CLI::ReadLine;
use Term::CLI::Command;
use Term::CLI::Argument::Enum;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number::Int;
use Term::CLI::L10N;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 5) {
    my $self = shift;
    my @commands;

    Term::CLI::L10N->set_language('en');

    my $cp_cmd = Term::CLI::Command->new(
        name => 'cp',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
        ],
        callback => sub {
            my ($self, %args) = @_;
            return %args;
        }
    );
    push @commands, $cp_cmd;
    $cp_cmd->add_argument(
        Term::CLI::Argument::Filename->new(name => 'dst'),
    );

    my $mv_cmd = Term::CLI::Command->new(
        name => 'mv',
        options => ['interactive|i', 'force|f'],
        arguments => [],
    );
    push @commands, $mv_cmd;
    ok(!$mv_cmd->has_arguments, 'empty arguments array -> has_arguments == false');
    $mv_cmd->add_argument(
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    );

    push @commands, Term::CLI::Command->new(
        name => 'info',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'file')
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'file',
        options => ['verbose|v+', 'version|V', 'dry-run|D', 'debug|d+'],
        commands =>  [ @commands ]
    );

    my $test_2_test_1 = Term::CLI::Command->new(
        name => 'test_2_test_1',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg1', occur => 2),
        ],
        commands => [
            Term::CLI::Command->new(
                name => 'test_1', 
                arguments => [
                    Term::CLI::Argument::Enum->new(name => 'arg2',
                        max_occur => 0,
                        value_list => [qw( one two three )]
                    ),
                ],
            ),
        ],
    );
    ok(!$test_2_test_1->has_options,
        'has_options returns false for command without options');
    push @commands, $test_2_test_1;

    push @commands, Term::CLI::Command->new(
        name => 'test_0_1',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg',
                min_occur => 0, max_occur => 1),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'test_1_2',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg',
                min_occur => 1, max_occur => 2),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'test_2_2',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg', occur => 2),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'test_1_0',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg',
                min_occur => 1, max_occur => 0),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'test_2_0',
        arguments => [
            Term::CLI::Argument::String->new(name => 'arg',
                min_occur => 2, max_occur => 0),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'sleep',
        options => ['verbose|v+', 'debug|d+'],
        arguments => [
            Term::CLI::Argument::Number::Int->new(
                name => 'time', min => 1, inclusive => 1
            ),
        ]
    );

    push @commands, Term::CLI::Command->new(
        name => 'make',
        options => ['verbose|v+', 'debug|d+'],
        arguments => [
            Term::CLI::Argument::Enum->new(
                name => 'thing', value_list => [qw( money love ), 'not war']
            ),
            Term::CLI::Argument::Enum->new(
                name => 'when', value_list => [qw( always now later never )]
            ),
        ]
    );

    push @commands, Term::CLI::Command->new( name => 'quit' );

    my $show_cmd = Term::CLI::Command->new(
        name => 'show',
        options => ['long|l', 'level|L', 'debug|d+', 'verbose|v+'],
    );

    push @commands, $show_cmd;

    my @show_sub_commands = (
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
            ]
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
    );
    $show_cmd->add_command(@show_sub_commands);

    isa_ok( $commands[0], 'Term::CLI::Command',
            'Term::CLI::Command->new' );

    my $cli = Term::CLI->new(
        prompt => 'test> ',
        callback => undef,
        commands => [],
    );
    isa_ok( $cli, 'Term::CLI', 'Term::CLI->new' );
    ok(!$cli->has_commands, 'empty commands array -> has_commands == false');
    $cli->add_command(@commands);

    # Try out the "add_" methods.
    my $test_2_4 = Term::CLI::Command->new(
        name => 'test_2_4',
    );
    $test_2_4->add_argument(
        Term::CLI::Argument::String->new(name => 'arg',
                min_occur => 2, max_occur => 4),
    );
    push @commands, $test_2_4;
    $cli->add_command($test_2_4);

    $self->{cli} = $cli;
    $self->{commands} = [@commands];
}


sub check_root_node: Test(6) {
    my $self = shift;
    my $cli = $self->{cli};
    my $cmd = $self->{commands}->[0];

    is($cmd->parent, $cli, "command parent node is CLI object");
    is($cmd->root_node, $cli, "command root_node is CLI object");

    my $test_2_test_1 = $cli->find_command('test_2_test_1');
    ok($test_2_test_1, 'found the test_2_test_1 command');
    my $test_1 = $test_2_test_1->find_command('test_1');
    ok($test_2_test_1, 'found the test_2_test_1 test_1 sub-command');

    is($test_1->parent, $test_2_test_1, "sub-command parent node is command object")
        or diag("actual parent is ".$test_1->parent->name);
    is($test_1->root_node, $cli, "sub-command root_node is CLI object")
        or diag("actual root_node is ".$test_1->root_node->name);
}


sub check_command_names: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};

    my @commands = sort { $a cmp $b } map { $_->name } @{$self->{commands}};
    my @got = $cli->command_names();
    is_deeply(\@got, \@commands,
            "commands are (@commands)")
    or diag("command_names returned: (", join(", ", map {"'$_'"} @got), ")");
}


sub check_attributes: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};
    is( $cli->prompt, 'test> ', "prompt attribute is 'test> '" );
}


sub check__split_line: Test(6) {
    my $self = shift;
    my $cli = $self->{cli};

    my $line = 'This\ is a "test\"for" split';
    my @expected = ('This is', 'a', 'test"for', 'split');
    my ($error, @got) = $cli->_split_line($line);
    is($error, '', '_split_line returns success');
    is_deeply(\@got, \@expected, '_split_line splits correctly');

    $line = "  \t  \t  ";
    @expected = ();
    ($error, @got) = $cli->_split_line($line);
    is($error, '', '_split_line returns success');
    is_deeply(\@got, \@expected, '_split_line splits correctly');

    $line = 'This is "an unbalanced quote';
    @expected = ();
    ($error, @got) = $cli->_split_line($line);
    is($error, 'unbalanced quotes in input', '_split_line returns correct error');
    is_deeply(\@got, \@expected, '_split_line returns empty list on error');
}

sub check__is_escaped: Test(6) {
    my $self = shift;
    my $cli = $self->{cli};

    my $bs = '\\';
    my $line = 'foo bar';
    ok(!$cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns false});

    $line = "foo$bs bar";
    ok($cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns true});

    $line = "foo$bs$bs bar";
    ok(!$cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns false});

    $line = " foobar";
    ok(!$cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns false});

    $line = "$bs foobar";
    ok($cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns true});

    $line = "$bs$bs foobar";
    ok(!$cli->_is_escaped($line, index($line, ' ')),
        qq{_is_escaped on '$line' returns false});
}


sub check_complete_line: Test(11) {
    my $self = shift;
    my $cli = $self->{cli};

    my ($line, $text, $start, @got, @expected);

    $line = '';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = $cli->command_names();

    is_deeply(\@got, \@expected,
            "commands are (@expected)")
    or diag("complete_line('','',0) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'X ';
    $text = 'X';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'show ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( date debug parameter time );
    is_deeply(\@got, \@expected,
            "'show' commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'file --verbose cp ';
    $text = '--i';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( --interactive );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'file --verbose cp ';
    $text = '-i';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( -i );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'make ';
    $text = 'n';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = ( 'not\ war' );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'make l ';
    $text = 'n';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = ( 'never', 'now' );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");


    $line = 'test_2_test_1 aap noot ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( test_1 );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'test_2_test_1 aap noot test_1 ';
    $text = 'o';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( one );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'test_2_test_1 aap noot test_1 one ';
    $text = 't';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( three two );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'quit ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw();
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");
}

sub check_execute: Test(47) {
    my $self = shift;
    my $cli = $self->{cli};

    my $line;
    my %result;

  # ------
    $line = '';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: missing command');
    like($result{error}, qr/missing command/, 'error message missing command');

  # ------
    $line = 'file --verbose cp aap noot';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful command execution');

    $line .= "\t";
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful command execution with trailing whitespace');

    $line = 'file --wtf cp aap noot';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: bad option');
    like($result{error}, qr/Unknown option: wtf/, 'error message bad option');

    $line = 'file --verbose cp aap noot mies';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too many arguments');
    like($result{error}, qr/too many .* arguments/, 'error message too many args');

    $line = 'file --verbose cp aap "noot';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: unbalanced quote');

    $line = 'file --verbose cpr aap noot';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: unknown sub-command');

    $line = 'file --verbose';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: missing sub-command');

  # ------
    $line = 'xfile --verbose cp aap noot';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: unknown command');
  #
  # ------
    $line = 'make money';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: not enough arguments');
    like($result{error}, qr/missing .* argument/, 'error message too few args');

    $line = 'make money veryfast';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: bad argument value');

  # ------
    $line = 'test_0_1';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 0 args');

    $line = 'test_0_1 foo';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 1 arg');

    $line = 'test_0_1 foo bar';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too many args');
    like($result{error}, qr/too many .* arguments/, 'error message too many args');

  # ------
    $line = 'test_1_0';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too few args');
    like($result{error}, qr/need at least 1 .* argument/,
        'error message too few args');

    $line = 'test_1_0 foo bar';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 2 args');

    $line = 'test_1_0 foo bar baz';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 3 args');

  # ------
    $line = 'test_1_2';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too few args');
    like($result{error}, qr/need \d+ or \d+ .* arguments/,
        'error message too few args');

    $line = 'test_1_2 foo';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 1 arg');

    $line = 'test_1_2 foo bar';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 2 args');

    $line = 'test_1_2 foo bar baz';
    %result = $cli->execute($line);
    like($result{error}, qr/too many .* arguments/, 'error message too many args');
 
  # ------
    $line = 'test_2_0 foo';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too few args');
    like($result{error}, qr/need at least 2 .* arguments/,
        'error message too few args');

    $line = 'test_2_0 foo bar';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 2 args');

    $line = 'test_2_0 foo bar baz';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 3 args');

  # ------
    $line = 'test_2_2 foo';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too few args');
    like($result{error}, qr/need 2 .* arguments/, 'error message too few args');

    $line = 'test_2_2 foo bar';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution with 2 args');

    $line = 'test_2_2 foo bar baz';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too many args');
    like($result{error}, qr/too many .* arguments/, 'error message too many args');

  # ------
    $line = 'test_2_4 foo';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: too few args');
    like($result{error}, qr/need between \d+ and \d+ .* arguments/,
        'error message too few args');

  # ------
    $line = 'test_2_test_1 foo bar test_1 one';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution of test_2_test_1')
    or diag("error: ", $cli->error);

    $line = 'test_2_test_1 foo jack back test_1 bar';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: expected test_1');
    like($result{error}, qr/expected 'test_1'/,
        'error message bad sub-command');

    $line = 'test_2_test_1 foo bar';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: missing test_1');
    like($result{error}, qr/missing 'test_1'/,
        'error message bad sub-command');

  # ------
    $line = 'quit';
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful execution of quit');

    $line = 'quit altogether';
    %result = $cli->execute($line);
    is($result{status}, -1, 'failed command execution: no arguments allowed');
    like($result{error}, qr/no arguments allowed/,
        'error message no args allowed');
}

}
Main();
