#!/usr/local/bin/perl

use Test;

BEGIN { plan tests => 17 }

my $myNTuples;


# There are no reasons any of these tests should ever fail.
# But we will see... ... ... :)


##  Test 1 -=- Can we load the NTuples library?
eval { require NTuples; return 1; };
ok($@, '');
croak() if $@;



##  Test 2 -=- Can we instantiate a NTuples ?
$myNTuples = new NTuples( );
ok( $myNTuples->isa('NTuples') );



##  Test 3 -=- Can we register FMT ?
$myNTuples->new_format( 'username', 'password', 'uid' );
ok( $myNTuples->isa('NTuples') );



##  Test 4 -=- Can we register records ?
my @input = (
    ["root", "supersecret", "0"],
    ["daemon", "secret1", "1"],
    ["bin", "secret2", "2"],
    ["sys", "secret3", "3"],
    ["adm", "secret4", "4"],
    ["cmorris", "NTuples", "1185"],
    ["user0", "abc000", "5000"],
    ["user1", "abc001", "5001"],
    ["user2", "abc002", "5002"],
    ["user3", "abc003", "5003"],
    ["user4", "abc004", "5004"],
    ["user5", "abc005", "5005"],
    ["user6", "abc006", "5006"]
  );

$myNTuples->new_data( @input );

ok( $myNTuples->isa('NTuples') );



##  Test 5 -=- Can we SELECT * ?
eval{
  my @result = $myNTuples->select_row( 'username', 'cmorris' );
  if( $result[0] eq 'cmorris' && $result[1] eq 'NTuples' && $result[2] eq '1185' )
  { return 1; }
};

ok($@, '');



##  Test 6 -=- Can we SELECT uid WHERE username='sys' ?
ok( $myNTuples->select_value( 'username', 'sys', 'uid' ) eq '3' );



##  Test 7 -=- Can we SELECT username WHERE uid=3 ?
ok( $myNTuples->select_value( 'uid', '3', 'username' ) eq 'sys' );



##  Test 8 -=- Can we SET uid=17 WHERE username='sys'?
ok( $myNTuples->update_value( 'username', 'sys', 'uid', '17' ) != 1 );



##  Test 9 -=- Can we SELECT username WHERE uid=3 ?
ok( $myNTuples->select_value( 'uid', '3', 'username' ) == undef );



##  Test 10 -=- Can we SELECT uid WHERE username='sys' ?
ok( $myNTuples->select_value( 'username', 'sys', 'uid' ) eq '17' );



##  Test 11 -=- Can we SELECT username WHERE uid='17' ?
ok( $myNTuples->select_value( 'uid', '17', 'username' ) eq 'sys' );



##  Test 12 -=- Can we INSERT INTO ?
$myNTuples->insert_data( ['ibl', 'xxxxxxxx', '62'] );
ok( $myNTuples->isa('NTuples') );



##  Test 13 -=- Can we SELECT username WHERE uid='62' ?
ok( $myNTuples->select_value( 'uid', '62', 'username' ) eq 'ibl' );



##  Test 14 -=- Can we SELECT username WHERE uid='17' ?
ok( $myNTuples->select_value( 'uid', '17', 'username' ) eq 'sys' );



##  Test 15 -=- Can we DELETE FROM NTuples WHERE uid='700'  ?
ok( $myNTuples->delete_row( 'uid', '700' ) eq '0' );



##  Test 16 -=- Can we DELETE FROM NTuples WHERE uid='17'  ?
ok( $myNTuples->delete_row( 'uid', '17' ) eq '1' );



##  Test 17 -=- Can we SELECT password WHERE uid='17'  ?
ok( $myNTuples->select_value( 'uid', '17', 'password' ) == undef );
