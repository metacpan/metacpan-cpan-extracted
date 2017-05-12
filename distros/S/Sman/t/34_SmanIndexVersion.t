# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use_ok( "Sman::IndexVersion" );
use_ok( "Sman::Config" );

my $config = new Sman::Config();
ok( $config, "new Sman::Config" );

my $indexversion = new Sman::IndexVersion( $config );
ok( $indexversion, "indexversion" );

ok(1); # If we made it this far, we're ok.

