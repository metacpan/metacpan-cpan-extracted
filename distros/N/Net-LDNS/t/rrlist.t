use Test::More;
use Devel::Peek;

use Net::LDNS;

my $s = Net::LDNS->new( '8.8.8.8' );
my $p = $s->query( 'iis.se', 'SOA' );

my $rrl = $p->all;
isa_ok( $rrl, 'Net::LDNS::RRList' );

is( $rrl->count, 1, 'one RR in list' );
my $rr = $rrl->pop;
isa_ok( $rr, 'Net::LDNS::RR::SOA' );
is( $rrl->count, 0, 'zero RRs in list' );

my $rr1 = Net::LDNS::RR->new_from_string( 'nic.se IN NS a.ns.se' );
my $rr2 = Net::LDNS::RR->new_from_string( 'mic.se IN NS a.ns.se' );
my $rr3 = Net::LDNS::RR->new_from_string( 'nic.se IN NS b.ns.se' );

ok( $rrl->push( $rr1 ), 'Push OK' );
ok( $rrl->push( $rr3 ), 'Second push OK' );
ok( $rrl->is_rrset,     'Is an RRset' );
ok( $rrl->push( $rr2 ), 'Third push OK' );
is( $rrl->count, 3, 'Three RRs in list' );

ok( !$rrl->is_rrset, 'Is not an RRset' );

while ( my $rr = $rrl->pop ) {
    isa_ok( $rr, 'Net::LDNS::RR::NS' );
}
is( $rrl->count, 0, 'zero RRs in list' );
ok( !$rrl->is_rrset, 'Is not an RRset' );

done_testing;
