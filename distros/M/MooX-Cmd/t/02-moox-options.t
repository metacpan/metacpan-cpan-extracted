#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Moo;
use MooX::Cmd::Tester;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN
{
    eval "use MooX::Options 4.100; use OptionTestApp";
    $@ and plan skip_all => "Need MooX::Options 4.100 $@" and exit(0);
}

diag("Testing MooX::Cmd version " . MooX::Cmd->VERSION . " using MooX::Options version " . MooX::Options->VERSION);

my @tests = (
    [[qw(--help)], "OptionTestApp", [], qr{\QUSAGE: 02-moox-options.t [-h]\E}, qr{\QSUB COMMANDS AVAILABLE: \E(?:oops|primary)}],
    [[qw(--in-doubt)], "OptionTestApp", [qw(OptionTestApp)]],
    [
        [qw(primary --help)], "OptionTestApp", [],
        qr{\QUSAGE: 02-moox-options.t primary [-h]\E},
        qr{\QSUB COMMANDS AVAILABLE: secondary\E}
    ],
    [[qw(primary --serious)], "OptionTestApp", [qw(OptionTestApp OptionTestApp::Cmd::primary)]],
    [[qw(--in-doubt primary secondary --help)], "OptionTestApp", [], qr{\QUSAGE: 02-moox-options.t primary secondary [-h]\E}],
    [
        [qw(primary secondary --sure)], "OptionTestApp",
        [qw(OptionTestApp OptionTestApp::Cmd::primary OptionTestApp::Cmd::primary::Cmd::secondary)]
    ],
);

for (@tests)
{
    my ($args, $class, $chain, $help, $avail) = @{$_};
    ref $args or $args = [split(' ', $args)];
    my $rv = test_cmd($class => $args);

    my $test_ident = "$class => " . join(" ", "[", @$args, "]");
    $help and like($rv->stdout, $help, "test '$test_ident' help message");
    $help or unlike($rv->stdout, qr{\QUSAGE: 02-moox-options.t\E}, "test '$test_ident' no help message");
    $avail and like($rv->stdout, $avail, "test '$test_ident' avail commands ok");
    $avail or unlike($rv->stdout, qr{\QAvailable commands\E}, "test '$test_ident' no avail commands");

    if (defined($rv->cmd))
    {
        my @cmd_chain = map { ref $_ } @{$rv->cmd->command_chain};
        is_deeply(\@cmd_chain, $chain, "test '$test_ident' command chain ok");
    }
}

done_testing;
