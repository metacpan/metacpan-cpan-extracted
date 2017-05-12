use strict;
use Test::More;

use_ok('Net::Flotum');
ok( my $flotum = Net::Flotum->new( merchant_api_key => 'm-just-testing' ), 'new ok' );

my $cus = eval { $flotum->load_customer( id => '00000000-26ad-4aab-97ac-bb5d068d472a' ) };
is( $@, "Resource does not exists\n", "loading non-existent id error is 'Resource does not exists\\n'" );

$cus = eval { $flotum->load_customer( remote_id => 'x00000000-26ad-4aab-97ac-bb5d068d472a' ) };
is( $@, "Resource does not exists\n", "loading non-existent remote_id error is 'Resource does not exists\\n'" );

done_testing;
