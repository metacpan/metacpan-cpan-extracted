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
    Term_CLI_Role_HelpText_test->runtests();
    exit(0);
}

package Term_CLI_Role_HelpText_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use FindBin 1.50;
use Term::CLI;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub check_usage : Test(no_plan) {
    my $self = shift;
    my @commands;

    my $cmd_1 = Term::CLI::Command->new(
        name => 'mv',
        summary => 'move files/directories',
        description => 'Move I<path1> to I<path2>.',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'path', occur => 2),
        ],
    );

    my $txt = $cmd_1->usage_text();
    my $expected = 'B<mv> I<path1> I<path2>';
    is($txt, $expected,
        'usage text for simple command is correct'
    );

    $cmd_1->options( [ 'verbose|v', 'debug|d=i', 'run|r:i' ] );

    $txt = $cmd_1->usage_text();
    $expected = 'B<mv> [B<--verbose>]'
              . ' [B<--debug>=I<i>] [B<-d>I<i>]'
              . ' [B<--run>[=I<i>]] [B<-r>[I<i>]]'
              . ' [B<-v>]'
              . ' I<path1> I<path2>';
    is($txt, $expected,
        'usage text for command with options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'short' );
    $expected = 'B<mv> [B<-d>I<i>] [B<-r>[I<i>]] [B<-v>] I<path1> I<path2>';
    is($txt, $expected,
        'usage text for command with short options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'long' );
    $expected = 'B<mv> [B<--verbose>] [B<--debug>=I<i>]'
              . ' [B<--run>[=I<i>]] I<path1> I<path2>';
    is($txt, $expected,
        'usage text for command with long options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'none' );
    $expected = 'B<mv> I<path1> I<path2>';
    is($txt, $expected,
        'usage text for command without options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'none', with_arguments => 0 );
    $expected = 'B<mv>';
    is($txt, $expected,
        'usage text for command without options or arguments is correct'
    );

    $cmd_1->usage( 'B<this> I<that>' );
    $txt = $cmd_1->usage_text();
    $expected = 'B<this> I<that>';
    is($txt, $expected,
        'usage text for command with explicit usage'
    );


    my $cmd_2 = Term::CLI::Command->new(
        name => 'foo',
        summary => 'do foo',
        description => 'Do some foo.',
    );

    my $arg = Term::CLI::Argument::Filename->new(name => 'path', occur => 0);
    $cmd_2->set_arguments($arg);

    $arg->min_occur(0);
    $arg->max_occur(1);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> [I<path>]';
    is($txt, $expected,
        'usage text for command with optional argument is correct'
    );

    $arg->max_occur(0);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> [I<path> ...]';
    is($txt, $expected,
        'usage text for command with optional unlimited argument is correct'
    );

    $arg->occur(3);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> I<path1> I<path2> I<path3>';
    is($txt, $expected,
        'usage text for command with three arguments is correct'
    );

    $arg->min_occur(0);
    $arg->max_occur(2);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> [I<path1> [I<path2>]]';
    is($txt, $expected,
        'usage text for command with 0-2 arguments is correct'
    );

    $arg->min_occur(1);
    $arg->max_occur(2);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> I<path1> [I<path2>]';
    is($txt, $expected,
        'usage text for command with 1-2 arguments is correct'
    );

    $arg->min_occur(2);
    $arg->max_occur(3);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> I<path1> I<path2> [I<path3>]';
    is($txt, $expected,
        'usage text for command with 2-3 arguments is correct'
    );

    $arg->min_occur(1);
    $arg->max_occur(6);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> I<path1> [I<path2> ... I<path6>]';
    is($txt, $expected,
        'usage text for command with 1-6 arguments is correct'
    );

    $arg->min_occur(2);
    $arg->max_occur(6);
    $txt = $cmd_2->usage_text();
    $expected = 'B<foo> I<path1> I<path2> [I<path3> ... I<path6>]';
    is($txt, $expected,
        'usage text for command with 2-6 arguments is correct'
    );

    my $cmd_3 = Term::CLI::Command->new(
        name => 'foo',
        summary => 'do foo',
        description => 'Do some foo.',
        commands => [
            Term::CLI::Command->new(
                name => 'bar',
                summary => 'do bar',
                description => 'Do some bar.',
            ),
        ],
    );

    $txt = $cmd_3->usage_text();
    $expected = 'B<foo> B<bar>';
    is($txt, $expected,
        'usage text for command with single sub-command is correct'
    );

    my $cmd_4 = Term::CLI::Command->new(
        name => 'foo',
        summary => 'do foo',
        description => 'Do some foo.',
    );

    $txt = $cmd_4->usage_text();
    $expected = 'B<foo>';
    is($txt, $expected,
        'usage text for command with no argument/sub-command/option is correct'
    );

    my $cmd_5 = Term::CLI::Command->new(
        name => 'foo',
        summary => 'do foo',
        description => 'Do some foo.',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'path', occur => 1)
        ],
        commands => [
            Term::CLI::Command->new(
                name => 'bar',
                summary => 'do foo bar',
                description => 'Do some foo bar.',
            ),
            Term::CLI::Command->new(
                name => 'baz',
                summary => 'do foo baz',
                description => 'Do some foo baz.',
            ),
        ],
    );
    $txt = $cmd_5->usage_text();
    $expected = 'B<foo> I<path> {B<bar>|B<baz>}';
    is($txt, $expected,
        'usage text for command with both argument and sub-command is correct'
    );
    return;
}

}
Main();
