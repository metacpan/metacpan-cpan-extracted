#!perl -T

use Test::More tests => 1;
use Config;
use lib qw ( lib );
BEGIN {
  use_ok( 'Parse::Flash::Cookie' );
}

diag( "Testing Parse::Flash::Cookie $Parse::Flash::Cookie::VERSION, Perl $], $^X, archname=$Config{archname}, byteorder=$Config{byteorder}" );

__END__
