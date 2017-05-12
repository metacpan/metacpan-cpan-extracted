use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'Module::Build::Prereqs::FromCPANfile' ) || print "Bail out!\n";
}
 
diag( "Testing Module::Build::Prereqs::FromCPANfile $Module::Build::Prereqs::FromCPANfile::VERSION, Perl $], $^X" );
