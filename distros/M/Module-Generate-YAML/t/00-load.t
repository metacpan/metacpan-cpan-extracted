#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Module::Generate::YAML' ) || print "Bail out!\n";
}

diag( "Testing Module::Generate::YAML $Module::Generate::YAML::VERSION, Perl $], $^X" );
