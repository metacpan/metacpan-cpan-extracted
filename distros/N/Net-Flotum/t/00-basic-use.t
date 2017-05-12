use strict;
use Test::More;

use_ok('Net::Flotum');
eval { Net::Flotum->new( merchant_id => 'x' ) };
ok( $@ =~ /merchant_api_key/, 'required merchant_api_key' );
ok( my $new = Net::Flotum->new( merchant_api_key => 'testing' ), 'new ok' );

done_testing;
