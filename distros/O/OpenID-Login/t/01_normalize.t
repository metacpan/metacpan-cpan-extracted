use Test::More tests => 7;

use OpenID::Login;

is( OpenID::Login::normalize('example.com'),              'http://example.com/' );
is( OpenID::Login::normalize('http://example.com'),       'http://example.com/' );
is( OpenID::Login::normalize('https://example.com'),      'https://example.com/' );
is( OpenID::Login::normalize('https://example.com/'),     'https://example.com/' );
is( OpenID::Login::normalize('http://example.com/user'),  'http://example.com/user' );
is( OpenID::Login::normalize('http://example.com/user/'), 'http://example.com/user/' );
is( OpenID::Login::normalize('http://example.com/'),      'http://example.com/' );

