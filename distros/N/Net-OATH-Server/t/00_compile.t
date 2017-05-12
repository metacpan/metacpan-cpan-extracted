use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Net::OATH::Server
    Net::OATH::Server::Lite::DataHandler
    Net::OATH::Server::Lite::Error
    Net::OATH::Server::Lite::Model::User
    Net::OATH::Server::Lite::Endpoint::Login
    Net::OATH::Server::Lite::Endpoint::User
);

done_testing;

