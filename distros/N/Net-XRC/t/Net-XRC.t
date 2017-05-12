# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-XRC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test;
#BEGIN { plan tests => 3 };

#use Test::More tests => 17;
use Test::More skip_all => 'test account no longer valid';
BEGIN{ use_ok('Net::XRC', qw(:types)) }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

  $Net::XRC::DEBUG = 0;

  my $clientID = '1551978';
  my $password = 'password';

  my $xrc = new Net::XRC (
    'clientID' => $clientID,
    'password' => $password,
  );

  my $domain = 'SISD.EVERY1.NET';

  # noop

  my $res = $xrc->noop;
  ok( $res->is_success, 'noop sucessful' )
    or diag( $res->error );
  ok( ! defined($res->content), 'noop returns undef' );

  # lookupMXReadyClientIDByEmailDomain

  $res = $xrc->lookupMXReadyClientIDByEmailDomain($domain);
  ok( $res->is_success, 'lookupMXReadyClientIDByEmailDomain sucessful' )
    or diag( $res->error );
  my $domain_clientID = $res->content;
  ok( $domain_clientID != -1, 'lookupMXReadyClientIDByEmailDomain' );

  # isAccountName

  my @set = ( 'a'..'z', '0'..'9' );
  my $username = join('', map { $set[int(rand(scalar(@set)))] } ( 1..32 ) );
  $res = $xrc->isAccountNameAvailable( $domain_clientID, $username );
  ok( $res->is_success, 'isAccountName sucessful' )
    or diag( $res->error );
  ok( $res->content, 'isAccountName returns true' );

  # isAccountName (numeric)

  my @nset = ( '0'..'9' );
  my $nusername = join('', map { $nset[int(rand(scalar(@nset)))] } ( 1..32 ) );
  $res = $xrc->isAccountNameAvailable( $domain_clientID, string($nusername) );
  ok( $res->is_success, 'isAccountName (numeric) sucessful' )
    or diag( $res->error );
  ok( $res->content, 'isAccountName (numeric) returns true' );

  # createUser

  $res = $xrc->createUser( $domain_clientID, [], $username, 'password' );
  ok( $res->is_success, 'createUser sucessful' )
    or diag( $res->error );
  ok( $res->content, 'createUser returns uid' );

  # createUser (numeric)

  $res = $xrc->createUser( $domain_clientID, [], string($nusername), 'password' );
  ok( $res->is_success, 'createUser (numeric) sucessful' )
    or diag( $res->error );
  ok( $res->content, 'createUser (numeric) returns uid' );


  # setUserPassword 

  $res = $xrc->setUserPassword ( $domain_clientID, $username, 'newpassword' );
  ok( $res->is_success, 'setUserPassword sucessful' )
    or diag( $res->error );

  # suspendUser

  $res = $xrc->suspendUser( $domain_clientID, $username );
  ok( $res->is_success, 'suspendUser sucessful' )
    or diag( $res->error );

  # unsuspendUser

  $res = $xrc->unsuspendUser( $domain_clientID, $username );
  ok( $res->is_success, 'unsuspendUser sucessful' )
    or diag( $res->error );


  # deleteUser

  $res = $xrc->deleteUser( $domain_clientID, $username );
  ok( $res->is_success, 'deleteUser sucessful' )
    or diag( $res->error );


