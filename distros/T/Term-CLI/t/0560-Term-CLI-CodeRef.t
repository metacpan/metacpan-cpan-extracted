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

use FindBin 1.50;
use Term::CLI;
use Term::CLI::Command;
use Term::CLI::L10N;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

my $Cmd_Created = 0;
my @Sub_Commands = sort qw( clock info );

sub mk_sub_commands {
    my ($self) = shift;

    $Cmd_Created++;

    my @commands = map
        { Term::CLI::Command->new( name => $_ ) }
        @Sub_Commands ;

    return \@commands;
}

sub startup : Test(startup) {
    my $self = shift;
    my @commands;

    Term::CLI::L10N->set_language('en');

    push @commands, Term::CLI::Command->new(
        name => 'cp',
        options => ['interactive|i', 'force|f'],
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'src'),
            Term::CLI::Argument::Filename->new(name => 'dst'),
        ],
    );

    push @commands, Term::CLI::Command->new(
        name => 'show',
        commands => \&mk_sub_commands,
    );

    my $cli = Term::CLI->new(
        prompt => 'test> ',
        commands => [],
        skip => qr/^\s*(?:#.*)?$/,
        commands => \@commands,
    );

    $cli->callback(undef);
    $self->{cli} = $cli;

    return;
}

sub check_complete_line: Test(5) {
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
    or diag( "complete_line('','',0) returned: (", 
            join(", ", map {"'$_'"} @got), ")"
    );

    is( $Cmd_Created, 0, 'sub-commands have not yet been created.' );

    $line = 'show ';
    $text = '';
    $start = length($line);
    @got = $cli->complete_line($text, $line.$text, $start);
    @expected = @Sub_Commands;
    is_deeply(\@got, \@expected,
            "'show' commands are (@expected)")
    or diag("complete_line('$text','$line$text',$start) returned: (",
        join(", ", map {"'$_'"} @got), ")");

    is( $Cmd_Created, 1, 'sub-commands have been created.' );

    @got = $cli->complete_line($text, $line.$text, $start);

    is( $Cmd_Created, 1, 'sub-commands have been created only once.' );
}

}
Main();
