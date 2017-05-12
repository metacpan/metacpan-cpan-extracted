# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MooseX-Types-IP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Test::Exception;

{
  package MyClass;
  use Moose;
  use MooseX::Types::IPv4 qw/ip4/;
  use namespace::autoclean;

  has ip => ( isa => ip4, required => 1, is => 'ro' );
}

lives_ok { MyClass->new( ip => '192.168.99.1' ) }
  '192.168.99.1 is a valid ip address';
throws_ok { MyClass->new( ip => '192.168.256.1' ) }
  qr/is not a valid ip address/, 'Throws as "192.168.256.1" is not a valid ip address';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

