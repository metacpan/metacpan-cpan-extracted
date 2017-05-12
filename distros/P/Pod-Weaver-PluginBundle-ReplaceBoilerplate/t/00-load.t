#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pod::Weaver::PluginBundle::ReplaceBoilerplate' ) || print "Bail out!
";
}

diag( "Testing Pod::Weaver::PluginBundle::ReplaceBoilerplate $Pod::Weaver::PluginBundle::ReplaceBoilerplate::VERSION, Perl $], $^X" );
