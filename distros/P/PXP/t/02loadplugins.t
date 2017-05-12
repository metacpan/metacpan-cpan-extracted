#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

# test that each plugin can load without compile errors
use PXP;
PXP::init();

use PXP::PluginRegistry;
ok(1, "PXP::PluginRegistry");

my $plugin = PXP::Plugin->new('filename'   => 'testplugin.xml',
			      'directory'  => './t',
			     );
ok($plugin, "can load plugin");

ok($plugin->providerName eq 'IDEALX'
   && $plugin->id eq 'PXP::TestPlugin',
   'plugin enveloppe looks ok');

$plugin->instantiateExtensions();
ok(1, 'loading extensions works');
PXP::PluginRegistry::registerPlugin($plugin);
ok(1, 'can register plugin');

$MAIN::pxp_plugin_started = 123;
PXP::PluginRegistry::startupPlugin($plugin);
ok($MAIN::pxp_plugin_started != 123, 'can startup plugin');

PXP::PluginRegistry::startupPlugin($plugin);
ok(1, "startup didn't fail");
