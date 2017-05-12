use strict;
use warnings;
use Test::More tests => 5;

use_ok('SWISH::3');
ok( my $s3    = SWISH::3->new(), "new s3" );
ok( my $stash = $s3->get_stash,  "get_stash" );
is( ref $stash, 'SWISH::3::Stash', "stash isa SWISH::3::Stash object" );
ok( exists $stash->{sp_handler}, "sp_handler isa key" );
