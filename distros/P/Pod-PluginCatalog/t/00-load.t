#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Pod::PluginCatalog');
}

diag("Testing Pod::PluginCatalog $Pod::PluginCatalog::VERSION");
