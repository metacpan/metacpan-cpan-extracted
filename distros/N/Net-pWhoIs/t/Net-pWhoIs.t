use strict;
use warnings;

use Test::More tests => 4;

use_ok('Net::pWhoIs', 'Loaded Net::pWhoIs');
ok( my $obj = Net::pWhoIs->new({req => 'cpan.org'}), 'Can create instance of Net::pWhoIs');
isa_ok( $obj, 'Net::pWhoIs' );
ok($obj->pwhois(), 'Can call Net::pWhoIs::pwhois()')
