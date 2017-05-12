# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Artera.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test;
BEGIN { plan tests => 8  };
use Net::Artera;
ok(1); # If we made it this far, we're ok.

#########################

#$Net::Artera::WARN = 1;
#$Net::Artera::DEBUG = 1;

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# 2
my $conn = new Net::Artera ( 'username'   => 'CRMAPITEST@API.COM',
                             'password'   => 'CRMAPI',
                             'rid'        => 137044,
                             'production' => 0,
                           );

ok(ref($conn), 'Net::Artera', 'create new Net::Artera object' );

my $base_param = {
  'email'   => 'ivan-net-artera-test-'. time. '@example.com',
  'cname'   => 'Tofu Beast',
  'ref'     => 420,
  #'aid'     => 23,
  'add1'    => '54 Street Rd.',
  'add3'    => 'Tofu Towers',
  'add4'    => 'CA',
  'zip'     => '54321',
  #'cid'     => 'US',
};

# 3
my $param = { %$base_param, 'pid' => 68, 'priceid' => 52, };
my $r_newTrial = $conn->newTrial( $param );
ok( $r_newTrial->{'id'} == 1 || $r_newTrial->{'message'}, 1,
    'newTrial method' );

# 4
$param = { %$base_param, 'pid' => 69, 'priceid' => 53, };
$param->{$_} = $r_newTrial->{$_} foreach (qw(ASN AKC));
my $r_newOrder_convert = $conn->newOrder( $param );
ok( $r_newOrder_convert->{'id'} == 1 || $r_newOrder_convert->{'message'}, 1,
    'newOrder convert method' );

# 5
$param = { %$base_param, 'pid' => 69, 'priceid' => 53, };
my $r_newOrder = $conn->newOrder( $param );
ok( $r_newOrder->{'id'} == 1 || $r_newOrder->{'message'}, 1,
    'newOrder method' );

# 6
my $r_statusChange =
  $conn->statusChange( 'StatusID' => 16,
                       map { $_ => $r_newOrder->{$_} } qw(ASN AKC)
                     );
ok( $r_statusChange->{'id'} == 1 || $r_statusChange->{'message'}, 1,
    'statusChange method' );

# 7
my $r_getProductStatus =
  $conn->getProductStatus( map { $_ => $r_newOrder->{$_} } qw(ASN AKC) );
ok( $r_getProductStatus->{'StatusID'} == 16, 1, 'getProductStatus method' );

# 8
my $r_updateContentControl =
  $conn->updateContentControl( 'UseContentControl' => 1,
                               map { $_ => $r_newOrder->{$_} } qw(ASN AKC) );
ok( $r_getProductStatus->{'id'} == 1, 1, 'getProductStatus method' );


#$param->{'pid'} = 68;
#for my $priceid ( 1 .. 100 ) {
#  $param->{'priceid'} = $priceid;
#  my $r = $conn->newTrial( $param );
#  ok( $r->{'id'} != 1, 1 , "newTrial priceid test $priceid" ); 
#}
#
#$param->{'pid'} = 69;
#for my $priceid ( 1 .. 100 ) {
#  $param->{'priceid'} = $priceid;
#  my $r = $conn->newOrder( $param );
#  ok( $r->{'id'} != 1, 1 , "newOrder priceid test $priceid" ); 
#}




