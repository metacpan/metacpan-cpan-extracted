use strict;
use warnings;
use Test::More qw[no_plan];
use POE::Filter::DNS::TCP;
use Net::DNS::Packet;

my $orig = POE::Filter::DNS::TCP->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {
  isa_ok( $filter, 'POE::Filter::DNS::TCP' );
  isa_ok( $filter, 'POE::Filter' );
  {
    my $pckt = Net::DNS::Packet->new('example.com');
    my $raw = $filter->put( [ $pckt ] );
    isa_ok( $raw, 'ARRAY' );
    my $foo = $filter->get( $raw );
    isa_ok( $foo, 'ARRAY' );
    isa_ok( $foo->[0], 'Net::DNS::Packet' );
    my ($q) = $foo->[0]->question;
    isa_ok( $q, 'Net::DNS::Question' );
    is( $q->qname, 'example.com', 'Haz domain' );
    is( $q->qtype, 'A', 'Haz record type' );
    is( $q->qclass, 'IN', 'Haz record class' );
  }
}
