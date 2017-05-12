#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Test::Deep;
BEGIN { require "t/utils.pl"; }

plan tests => 8;

my @ARGS = qw(limit status name email replace_relations no_tickets);

use_ok('RTx::Shredder::Plugin::Users');
{
    my $plugin = new RTx::Shredder::Plugin::Users;
    isa_ok($plugin, 'RTx::Shredder::Plugin::Users');
    my @args = $plugin->SupportArgs;
    cmp_deeply(\@args, \@ARGS, "support all args");
    my ($status, $msg) = $plugin->TestArgs( name => 'r??t*' );
    ok($status, "arg name = 'r??t*'") or diag("error: $msg");
    for (qw(any disabled enabled)) {
        my ($status, $msg) = $plugin->TestArgs( status => $_ );
        ok($status, "arg status = '$_'") or diag("error: $msg");
    }
    ($status, $msg) = $plugin->TestArgs( status => '!@#' );
    ok(!$status, "bad 'status' arg value");
}

