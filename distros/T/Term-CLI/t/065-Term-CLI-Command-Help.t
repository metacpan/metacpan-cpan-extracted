#!/usr/bin/perl
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

sub Main {
    Term_CLI_Command_Help_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Command_Help_test->runtests();
}

package Term_CLI_Command_Help_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Output 1.03;
use Test::Exception 0.35;
use FindBin 1.50;
use Term::CLI;
use Term::CLI::L10N;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my @commands;

    Term::CLI::L10N->set_language('en');

    push @commands,Term::CLI::Command->new(
        name => 'cp',
        summary => 'copy I<src> to I<dst>',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
            Term::CLI::Argument::Filename->new(name => 'dst'),
        ],
    );

    push @commands,Term::CLI::Command->new(
        name => 'mv',
        summary => 'move files/directories',
        description => 'Move I<path1> to I<path2>.',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'path', occur => 2),
        ],
    );

    push @commands,Term::CLI::Command->new(
        name => 'show',
        commands => [
            Term::CLI::Command->new( name => 'clock' ),
            Term::CLI::Command->new( name => 'load' ),
        ],
    );

    my $help = Term::CLI::Command::Help->new(
        pager => [], # Prevent SIGPIPE by dumping to STDOUT directly.
    );

    push @commands, $help;

    my $cli = Term::CLI->new(
        prompt => 'test> ',
        callback => undef,
        commands => \@commands,
    );
    isa_ok( $cli, 'Term::CLI', 'Term::CLI->new' );

    $self->{cli} = $cli;
    $self->{commands} = [@commands];
}


sub check_pager : Test(3) {
    my $self = shift;
    my $cli = $self->{cli};

    my $n = 0;
    my $pager = "$FindBin::Bin/scripts/does_not_exist";
    while (-e $pager) {
        $pager = "$FindBin::Bin/scripts/does_not_exist_".$n++;
    }

    $cli->find_command('help')->pager([ $pager ]);
    my %args = $cli->execute('help');
    ok($args{status} < 0, '"help" with non-existent pager results in an error');
    like($args{error}, qr/cannot run '.*':/,
        'error on non-existent pager is set correctly');

    $pager = "$FindBin::Bin/scripts/pager.pl";
    $cli->find_command('help')->pager([ $^X, $pager, '1' ]);

    %args = $cli->execute('help');
    is($args{status}, 1<<8, 'pager exit status propagates to status')
        or diag("got status=$args{status}; error='$args{error}'");
}


sub check_help : Test(14) {
    my $self = shift;
    my $cli = $self->{cli};

    $cli->find_command('help')->pager( [] );

    stdout_like(
        sub { $cli->execute('help') },
        qr/Commands:.*cp.*help.*mv/sm,
        'help returns command summary'
    );

    stdout_like(
        sub { $cli->execute('help --pod') },
        qr/=head\d Commands:.*B<cp>.*B<help>.*B<mv>/sm,
        'help --pod returns POD command summary'
    );

    stdout_like(
        sub { $cli->execute('help cp') },
        qr/Usage:.*cp.*--force.*src.*dst/sm,
        '"help cp" returns command help'
    );
    stdout_like(
        sub { $cli->execute('help --pod cp') },
        qr/=head\d Usage:.*B<cp>.*B<--force>.*I<src>.*I<dst>/sm,
        '"help --pod cp" returns POD command help'
    );

    stdout_like(
        sub { $cli->execute('help --pod show') },
        qr{
           =head\d \s+ Usage: \s*\n
           B<show> .* \n
           =head\d \s+ Sub-Commands: \s*\n
           .* B<clock> .* B<load>
        }smx,
        "'help --pod show' returns POD command summary with sub-commands'",
    );

    stdout_like(
        sub { $cli->execute('help --pod show load') },
        qr/=head\d Usage:.*B<show> B<load>/sm,
        "'help --pod show load' returns POD command summary with sub-commands'",
    );

    stdout_like(
        sub { $cli->execute('help --pod mv') },
        qr/=head\d Usage:.*B<mv> I<path1> I<path2>/sm,
        "'help --pod mv' returns POD command summary'",
    );


    stdout_like(
        sub { $cli->execute('help --pod --all') },
        qr{
            =head\d \s COMMAND \s SUMMARY \n{2,}
            =over [^\n]*\n{2,}
            =item \s B<cp>   .*\n{2,}
            =item \s B<help> .*\n{2,}
            =item \s B<mv>   .*\n{2,}
            =item \s B<show> .*\n{2,}
            =back\n{2,}
            =head\d \s COMMANDS \n{2,}
            =over [^\n]*\n{2,}
            =item \s B<cp>   .*\n{2,}
            =item \s B<help> .*\n{2,}
            =item \s B<mv>   .*\n{2,}
            =item \s B<show> .*\n{2,}
            =back\n
        }smx,
        '"help --pod --all" returns POD command help'
    );
    my $x=q{
        };

    my %args = $cli->execute('help xp');
    ok($args{status} < 0, '"help xp" results in an error');
    like($args{error}, qr/unknown command/, 'error is set correctly');

    %args = $cli->execute('help cp sub');
    ok($args{status} < 0, '"help cp sub" results in an error');
    like($args{error}, qr/cp: unknown command/, 'error is set correctly');

    %args = $cli->execute('help --bad foo');
    ok($args{status} < 0, '"help --bad foo" results in an error');
    like($args{error}, qr/Unknown option: bad/, 'error is set correctly');

}

sub check_complete : Test(7) {
    my $self = shift;
    my $cli = $self->{cli};

    my (@got, @expected, $line, $text, $start);

    $line = 'help ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( cp help mv show );
    is_deeply(\@got, \@expected,
            "completion for 'help': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help ';
    $text = 'c';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( cp );
    is_deeply(\@got, \@expected,
            "completion for '$line$text': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help cp ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw();
    is_deeply(\@got, \@expected,
            "completion for '$line$text': commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help show ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( clock load );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help show foo ';
    $text = 'bar';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help ';
    $text = '--p';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( --pod );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

    $line = 'help -- ';
    $text = '--p';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = qw( );
    is_deeply(\@got, \@expected,
            "'$line$text' completions are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (", join(", ", map {"'$_'"} @got), ")");

}

}
Main();
