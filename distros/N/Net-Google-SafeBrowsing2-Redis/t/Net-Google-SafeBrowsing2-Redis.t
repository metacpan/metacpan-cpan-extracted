use Test::More qw(no_plan);

BEGIN { use_ok('Net::Google::SafeBrowsing2::Redis') };

require_ok( 'Net::Google::SafeBrowsing2::Redis' );

# done_testing();