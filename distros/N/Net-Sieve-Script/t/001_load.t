# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use lib qw(lib);

BEGIN { use_ok( 'Net::Sieve::Script' ); }

my $object = Net::Sieve::Script->new (name => "test");
isa_ok ($object, 'Net::Sieve::Script');


