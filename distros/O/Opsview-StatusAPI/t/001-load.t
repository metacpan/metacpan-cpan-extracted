# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Opsview::StatusAPI' ); 
}

my $object = Opsview::StatusAPI->new (user => 'test', password => 'xxx', host => '127.0.0.1');
isa_ok ($object, 'Opsview::StatusAPI' );

