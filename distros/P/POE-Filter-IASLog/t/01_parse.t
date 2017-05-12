use Test::More tests => 31;

BEGIN { use_ok('POE::Filter::IASLog') };

my $original = [ '10.10.10.10,client,06/04/1999,14:42:19,IAS,CLIENTCOMP,6,2,7,1,5,9,61,5,64,1,65,1,31,1' ];

my $orig = POE::Filter::IASLog->new( enumerate => 0 );
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

  isa_ok( $filter, 'POE::Filter::IASLog' );
  isa_ok( $filter, 'POE::Filter' );

  my $records = $filter->get( $original );

  my $record1 = shift @$records;

  ok( $record1->{'NAS-IP-Address'} eq '10.10.10.10', 'NAS-IP-Address' );
  ok( $record1->{'User-Name'} eq 'client', 'User-Name' );
  ok( $record1->{'Record-Date'} eq '06/04/1999', 'Record-Date' );
  ok( $record1->{'Record-Time'} eq '14:42:19', 'Record-Time' );
  ok( $record1->{'Service-Name'} eq 'IAS', 'Service-Name' );
  ok( $record1->{'Computer-Name'} eq 'CLIENTCOMP', 'Computer-Name' );

  ok( $record1->{'NAS-Port-Type'} eq '5', 'NAS-Port-Type' );
  ok( $record1->{'Service-Type'} eq '2', 'Service-Type' );
  ok( $record1->{'Tunnel-Medium-Type'} eq '1', 'Tunnel-Medium-Type' );
  ok( $record1->{'Tunnel-Type'} eq '1', 'Tunnel-Type' );
  ok( $record1->{'Framed-Protocol'} eq '1', 'Framed-Protocol' );
  ok( $record1->{'NAS-Port'} eq '9', 'NAS-Port' );
  ok( $record1->{'Calling-Station-ID'} eq '1', 'Calling-Station-ID' );

}
