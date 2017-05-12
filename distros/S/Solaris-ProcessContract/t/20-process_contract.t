use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract', qw(:flags) ); }

my $pc = new_ok( 'Solaris::ProcessContract' );


done_testing();
