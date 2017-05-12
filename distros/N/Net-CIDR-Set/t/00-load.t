use Test::More tests => 3;

BEGIN {
  use_ok( 'Net::CIDR::Set' );
  use_ok( 'Net::CIDR::Set::IPv4' );
  use_ok( 'Net::CIDR::Set::IPv6' );
}

diag( "Testing Net::CIDR::Set $Net::CIDR::Set::VERSION" );
