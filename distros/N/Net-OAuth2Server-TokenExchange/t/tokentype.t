use strict; use warnings;

use Test::More;
use Net::OAuth2Server::TokenType ();

my @k = sort keys %Net::OAuth2Server::TokenType::TOKEN_TYPE;

plan tests => 3 + @k;

isnt @k, 0, '%TOKEN_TYPE is populated';

ok exists $Net::OAuth2Server::TokenType::TOKEN_TYPE{'TOKEN_TYPE_ACCESS_TOKEN'}, '... and looks promising';

exit if not @k;

eval { Net::OAuth2Server::TokenType->import( @k ) };
ok !$@, 'import works';
( diag "$@" ), exit if $@;

for my $k ( @k ) {
	no strict 'refs';
	is eval { &$k }, $Net::OAuth2Server::TokenType::TOKEN_TYPE{ $k }, $k;
}
