# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;


BEGIN { 
use_ok( 'SSN::Validate' );
}


my $ssn = SSN::Validate->new();
isa_ok ($ssn, 'SSN::Validate');
