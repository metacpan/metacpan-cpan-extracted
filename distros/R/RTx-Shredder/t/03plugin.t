#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Test::Deep;
BEGIN { require "t/utils.pl"; }

my @PLUGINS = qw(Attachments Base Objects Tickets Users);
plan tests => 7 + 3 * @PLUGINS;

use_ok('RTx::Shredder::Plugin');
{
    my $plugin = new RTx::Shredder::Plugin;
    isa_ok($plugin, 'RTx::Shredder::Plugin');
    my %plugins = $plugin->List;
    cmp_deeply( [sort keys %plugins], [@PLUGINS], "correct plugins" );
}
{ # test ->List as class method
    my %plugins = RTx::Shredder::Plugin->List;
    cmp_deeply( [sort keys %plugins], [@PLUGINS], "correct plugins" );
}
{ # reblessing on LoadByName
    foreach (@PLUGINS) {
        my $plugin = new RTx::Shredder::Plugin;
        isa_ok($plugin, 'RTx::Shredder::Plugin');
        my ($status, $msg) = $plugin->LoadByName( $_ );
        ok($status, "loaded plugin by name") or diag("error: $msg");
        isa_ok($plugin, "RTx::Shredder::Plugin::$_" );
    }
}
{ # error checking in LoadByName
    my $plugin = new RTx::Shredder::Plugin;
    isa_ok($plugin, 'RTx::Shredder::Plugin');
    my ($status, $msg) = $plugin->LoadByName;
    ok(!$status, "not loaded plugin - empty name");
    ($status, $msg) = $plugin->LoadByName('Foo');
    ok(!$status, "not loaded plugin - not exist");
}

