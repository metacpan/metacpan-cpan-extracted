use strict;
use warnings;

use Test::More tests => 6;

use Net::Pface;

BEGIN { use_ok('Net::Pface') };

# create object
my $obj_pface = Net::Pface->new( { id => '0', key => '0', cache_time => 300 } );
ok( $obj_pface, "create Net::Pface object" );


#check auth
my $hash = $obj_pface->auth( 0, 0, 0 );
ok( $$hash{'error'}, "check auth" );

#check auth with cache
$hash = $obj_pface->auth( 0, 0, 0 );
ok( $$hash{'is_cache'}, "check auth with cache" );

#check get
$hash = $obj_pface->get( 0, 'id' );
ok( $$hash{'error'}, "check get" );

#check get with cache
$hash = $obj_pface->get( 0, 'id' );
ok( $$hash{'is_cache'}, "check get with cache" );

done_testing;