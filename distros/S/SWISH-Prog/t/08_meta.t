use strict;
use warnings;
use Test::More tests => 4;

use_ok('SWISH::Prog::InvIndex');

# use test dir as mock invindex since we just want header file
ok( my $invindex = SWISH::Prog::InvIndex->new( path => 't/' ),
    "new invindex" );

ok( my $meta = $invindex->meta, "get meta()" );

is( $meta->Index->{Format}, 'Native', "Native index format" );
