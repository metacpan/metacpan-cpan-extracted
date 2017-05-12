use Test::More tests => 7;

use OAuth::Lite::AuthMethod qw(
	AUTH_HEADER
	POST_BODY
	URL_QUERY
);

is(AUTH_HEADER, 'auth_header', 'imported AUTH_HEADER collectly');
is(POST_BODY, 'post_body', 'imported POST_BODY collectly');
is(URL_QUERY, 'url_query', 'imported URL_QUERY collectly');

my $result1 = OAuth::Lite::AuthMethod->validate_method( AUTH_HEADER );
ok($result1, 'validation for AUTH_HEADER results true');
my $result2 = OAuth::Lite::AuthMethod->validate_method( POST_BODY );
ok($result2, 'validation for POST_BODY results true');
my $result3 = OAuth::Lite::AuthMethod->validate_method( URL_QUERY );
ok($result3, 'validation for URL_QUERY results true');
my $result4 = OAuth::Lite::AuthMethod->validate_method( 'unknown' );
ok(!$result4, 'validation for unknown method results true');

