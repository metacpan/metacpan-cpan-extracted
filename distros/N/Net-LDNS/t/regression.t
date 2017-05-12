use Test::More;
use Test::Fatal;

use strict;
use warnings;

BEGIN { use_ok("Net::LDNS")}

my $s = Net::LDNS->new( '8.8.8.8' );
isa_ok( $s, 'Net::LDNS' );
like( exception { $s->query( 'xx--example..', 'A' ) }, qr/Invalid domain name: xx--example../, 'Died on invalid name');

done_testing;