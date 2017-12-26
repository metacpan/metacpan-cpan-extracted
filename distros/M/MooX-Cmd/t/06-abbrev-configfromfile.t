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
    eval "use Text::Abbrev; use MooX::ConfigFromFile 0.006; use ConfigAbbrevApp";
    $@ and plan skip_all => "Need Text::Abbrev and MooX::ConfigFromFile 0.006 -- $@" and exit(0);
}

diag(   "Testing MooX::Cmd version "
      . MooX::Cmd->VERSION
      . " using MooX::ConfigFromFile version "
      . MooX::ConfigFromFile->VERSION
      . " and Text::Abbrev version "
      . Text::Abbrev->VERSION);

my @tests = (
    [[], "ConfigAbbrevApp", "ConfigAbbrevApp", {}],
    [
        [qw(thuruksp)],
        "ConfigAbbrevApp",
        "ConfigAbbrevApp::Cmd::ThuruksPride",
        {
            race           => "Split",
            security_level => "Core"
        }
    ],
    [
        [qw(thuruksb)],
        "ConfigAbbrevApp",
        "ConfigAbbrevApp::Cmd::ThuruksBeard",
        {
            race           => "Split",
            security_level => "Border"
        }
    ],
);

SKIP:
for (@tests)
{
    my ($args, $class, $cmd_class, $attrs) = @{$_};
    ref $args or $args = [split(' ', $args)];
    my $rv = test_cmd($class => $args);
    #diag(explain($rv));

    my $test_ident = "$class => " . join(" ", "[", @$args, "]");
    ok($rv->cmd, "got cmd for $test_ident") or diag(explain($rv));
    isa_ok($rv->cmd, $class) or skip("Cannot do attribute testing without command", 2);
    isa_ok($rv->cmd->command_chain_end, $cmd_class)
      or skip("Cannot do attribute testing without specific command", 1)
      if scalar @$args;
    my $cmd = scalar @$args ? $rv->cmd->command_chain_end : $rv->cmd;
    foreach my $k (keys %$attrs)
    {
        my $cmd_attr = $cmd->$k;
        ref $attrs->{$k} or is($attrs->{$k}, $cmd_attr, "Attribute $k for $test_ident");
        "CODE" eq ref $attrs->{$k} and ok($attrs->{$k}->($cmd_attr), "Attribute $k ok for $test_ident");
        ref $attrs->{$k}
          and "CODE" ne ref $attrs->{$k}
          and is_deeply($attrs->{$k}, $cmd_attr, "Attribute $k for $test_ident");
    }
}

done_testing;
