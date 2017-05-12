use Test::More      tests => 2;

use_ok( 'Net::Discident' );
my $ident = Net::Discident->new();

isa_ok( $ident, 'Net::Discident' );
