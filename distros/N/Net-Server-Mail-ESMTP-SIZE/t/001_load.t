# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Server::Mail::ESMTP::SIZE' ); }

my $object = Net::Server::Mail::ESMTP::SIZE->new ();
isa_ok ($object, 'Net::Server::Mail::ESMTP::SIZE');


