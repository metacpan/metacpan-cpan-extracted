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

my $TEST_NAME = 'CLI';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_test->runtests();
    exit(0);
}

package Term_CLI_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use Test::Output 1.02;
use Test::MockModule 0.05;

use FindBin 1.50;
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
        prompt      => 'test> ',
        commands    => [],
        skip        => qr/^\s*(?:#.*)?$/,
        filehandles => []
    );
    isa_ok( $cli, 'Term::CLI', 'Term::CLI->new' );
    ok(!$cli->has_commands, 'empty commands array -> has_commands == false');

    $cli->add_command(@commands);

    $self->{dfl_callback} = $cli->callback;
    $cli->callback(undef);

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
    return;
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
    return;
}


sub check_command_names: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};

    my @commands = sort { $a cmp $b } map { $_->name } @{$self->{commands}};
    my @got = $cli->command_names();
    is_deeply(\@got, \@commands,
            "commands are (@commands)")
    or diag("command_names returned: (", join(", ", map {"'$_'"} @got), ")");
    return;
}


sub check_delete_command: Test(3) {
    my ($self) = @_;
    my $cli = $self->{cli};

    my @commands = sort { $a cmp $b } map { $_->name } @{$self->{commands}};

    my $target_index = int( (@commands - 1) /2 );
    my @expected = @commands;
    my $target_name = splice @expected, $target_index, 1;

    my @deleted = $cli->delete_command($target_name);

    if ( ! is( int(@deleted), 1, 'delete_command returns one element' ) ) {
        diag("cannot test further");
        return;
    }

    is( $deleted[0]->name, $target_name,
        'delete_command deleted the correct command' )
    or return;

    my @leftover = $cli->command_names;
    is_deeply( \@leftover, \@expected,
            'delete_command leaves correct set of commands' );

}

sub check_state: Test(2) {
    my $self = shift;
    my $cli = $self->{cli};

    my $got = $cli->state;
    is_deeply( $got, {}, 'state returns an empty HashRef' );

    $cli->state->{'flag'} = 123;

    is( $cli->state->{'flag'}, 123,
        'state is stored and retrieved correctly' );
}

sub check_attributes: Test(1) {
    my $self = shift;
    my $cli = $self->{cli};
    is( $cli->prompt, 'test> ', "prompt attribute is 'test> '" );
    return;
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
    return;
}

sub check__is_escaped: Test(6) {
    my $self = shift;
    my $cli = $self->{cli};

    my $bs = '\\';
    my $line = 'foo bar';

    #ok(!$cli->term->Attribs->{char_is_quoted_p}->($line, index($line, ' ')),
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
    return;
}

sub check_readline: Test(3) {
    my $self = shift;
    my $cli;

    my ($line, $text, $start, @got, @expected);

    # Mock out Term::ReadLine's "readline".

    my @test_lines = ( '# comment - should be skipped', '', 'show version');
    my ($expected, $got, @lines);

    my $rl_mock = Test::MockModule->new('Term::ReadLine');
    $rl_mock->mock('readline' => sub { return shift @lines });

    @lines = @test_lines;
    $expected = $lines[0];
    my $skip = qr/^\s*(?:#.*)?$/;

    $cli = Term::CLI->new();
    $got = $cli->readline(prompt => 'test> ');
    is($got, $expected, qq{default does not skip comments and empty lines})
            or diag("Term::CLI::readline returned: '$got'");

    $expected = $lines[-1];
    $got = $cli->readline(prompt => 'test> ', skip => $skip );
    is($got, $expected, qq{readline with skip argument skips comments and empty lines})
            or diag("Term::CLI::readline returned: '$got'");

    $cli = Term::CLI->new(skip => qr/^\s*(?:#.*)?$/);
    @lines = @test_lines;
    $expected = $lines[-1];

    $got = $cli->readline();
    is($got, $expected, qq{Term::CLI with skip set skips comments and empty lines})
            or diag("Term::CLI::readline returned: '$got'");
    return;
}

sub check_complete_line: Test(12) {
    my $self = shift;
    my $cli = $self->{cli};

    my ($line, $text, $start, @got, @expected);

    $line = '';
    $text = '';
    $start = length($line);
    #@got = $cli->term->Attribs->{completion_function}->($text, $line.$text, $start);
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
    or diag("complete_line('$text','$line$text',$start) returned: (",
            join(", ", map {"'$_'"} @got), ")");

    $line = 'show ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( date debug parameter time );
    is_deeply(\@got, \@expected,
            "'show' commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    {
        # Try quoted strings for completion... We need to make sure that
        # Term::CLI::ReadLine's `completion_quote_character` returns a quote char,
        # so temporarily mock it.
        my $quote_char = '"';
        my $rl_mock = Test::MockModule->new('Term::CLI::ReadLine');
        $rl_mock->mock('completion_quote_character' => $quote_char);

        $line = "show $quote_char";
        $text = 'd';
        $start = length($line);
        @got = $cli->complete_line($text, $line.$text, $start);
        @expected = qw( date debug );
        is_deeply(\@got, \@expected, qq{'$line$text' completions are (@expected)})
            or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");
    }

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
    return;
}

sub check_execute: Test(49) {
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
    
    $cli->callback($self->{dfl_callback});
        $line = 'file --verbose cp aap noot';
        combined_is(
            sub { %result = $cli->execute($line) },
            '',
            'Successful command prints nothing'
        );
        is($result{status}, 0, 'successful command execution');
    $cli->callback(undef);

    $line .= "\t";
    %result = $cli->execute($line);
    is($result{status}, 0, 'successful command execution with trailing whitespace');

    $cli->callback($self->{dfl_callback});
        $line = 'file --wtf cp aap noot';
        stderr_like(
            sub { %result = $cli->execute($line) },
            qr/Unknown option: wtf/,
            'default callback prints error to STDERR',
        );
        is($result{status}, -1, 'failed command execution: bad option');
        like($result{error}, qr/Unknown option: wtf/, 'error message bad option');
    $cli->callback(undef);

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
    return;
}

}
Main();
