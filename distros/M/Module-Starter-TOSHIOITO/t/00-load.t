use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'Module::Starter::TOSHIOITO' ) || print "Bail out!\n";
}
 
diag( "Testing Module::Starter::TOSHIOITO $Module::Starter::TOSHIOITO::VERSION, Perl $], $^X" );
