use Test::More tests => 1;

BEGIN {
  use_ok( 'Net::Snarl' ) || print "Bail out!\n";
}

diag( "Testing Net::Snarl $Net::Snarl::VERSION, Perl $], $^X" );
