use strict;
use warnings;

use Test::More;
 
BEGIN {
  use_ok( 'Template::Provider::Pandoc' );
}
 
diag( "Testing Template::Provider::Pandoc $Template::Provider::Pandoc::VERSION, Perl $], $^X" );

done_testing;
