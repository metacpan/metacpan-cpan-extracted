#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin;

use Salvation::PluginCore ();

use Test::More tests => 3;


my $core = new_ok( 'Salvation::PluginCore', [], '$core' );


my $plugin = $core -> load_plugin( infix => 'Plugin', base_name => 'test_plugin' );

isa_ok( $plugin, 'Salvation::PluginCore::Plugin::TestPlugin' );


my $deep_plugin = $plugin -> deep_plugin();

isa_ok( $deep_plugin, 'Salvation::PluginCore::Plugin::TestPlugin::Deep::DeepPlugin' );


exit 0;

__END__
