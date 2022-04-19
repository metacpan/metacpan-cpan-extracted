use strict;
use warnings;

use Test::More tests => 5;

use_ok('Net::pWhoIs', 'Loaded Net::pWhoIs');
ok( my $obj = Net::pWhoIs->new(), 'Can create instance of Net::pWhoIs');
isa_ok( $obj, 'Net::pWhoIs' );
ok($obj->pwhois('perlmonks.org'), 'Can call Net::pWhoIs::pwhois() with passed string');
ok($obj->pwhois(['cpan.org']), 'Can call Net::pWhoIs::pwhois() with passed arrayref');
