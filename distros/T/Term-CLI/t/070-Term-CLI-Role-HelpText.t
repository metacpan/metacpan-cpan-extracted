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
    Term_CLI_Role_HelpText_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Role_HelpText_test->runtests();
}

package Term_CLI_Role_HelpText_test {

use parent qw( Test::Class );

use Test::More;
use FindBin;
use Term::CLI;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub check_usage : Test(5) {
    my $self = shift;
    my @commands;

    my $cmd_1 = Term::CLI::Command->new(
        name => 'mv',
        summary => 'move files/directories',
        description => 'Move I<path>1 to I<path>2.',
        arguments => [
            Term::CLI::Argument::Filename->new(name => 'path', occur => 2),
        ],
    );

    my $txt = $cmd_1->usage_text();
    my $expected = 'B<mv> I<path>1 I<path>2';
    is($txt, $expected,
        'usage text for simple command is correct'
    );

    $cmd_1->options( [ 'verbose|v', 'debug|d=i' ] );

    $txt = $cmd_1->usage_text();
    $expected = 'B<mv> [B<--verbose>] [B<--debug>=I<i>]'
              . ' [B<-d>I<i>] [B<-v>] I<path>1 I<path>2';
    is($txt, $expected,
        'usage text for command with options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'short' );
    $expected = 'B<mv> [B<-d>I<i>] [B<-v>] I<path>1 I<path>2';
    is($txt, $expected,
        'usage text for command with short options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'long' );
    $expected = 'B<mv> [B<--verbose>] [B<--debug>=I<i>] I<path>1 I<path>2';
    is($txt, $expected,
        'usage text for command with long options is correct'
    );

    $txt = $cmd_1->usage_text( with_options => 'none' );
    $expected = 'B<mv> I<path>1 I<path>2';
    is($txt, $expected,
        'usage text for command without options is correct'
    );
}

}
Main();
