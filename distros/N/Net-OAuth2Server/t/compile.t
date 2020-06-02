use strict; use warnings;

use Net::OAuth2Server;
use Net::OAuth2Server::Request;
use Net::OAuth2Server::Request::Authorization;
use Net::OAuth2Server::Request::Resource;
use Net::OAuth2Server::Request::Token;
use Net::OAuth2Server::Request::Token::AuthorizationCode;
use Net::OAuth2Server::Request::Token::ClientCredentials;
use Net::OAuth2Server::Request::Token::Password;
use Net::OAuth2Server::Request::Token::RefreshToken;
use Net::OAuth2Server::Response;
use Net::OAuth2Server::Set;

print <<".";
1..1
ok 1
.
