# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Server::POP3' ); }

my $object = Net::Server::POP3->new ();
isa_ok ($object, 'Net::Server::POP3');


