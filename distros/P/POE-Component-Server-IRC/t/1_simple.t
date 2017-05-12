use strict;
use warnings;
use Test::More tests => 6;
use_ok('POE::Component::Server::IRC');
use_ok('POE::Component::Server::IRC::Common');
use_ok('POE::Component::Server::IRC::Plugin');
use_ok('POE::Component::Server::IRC::Backend');
use_ok('POE::Component::Server::IRC::Plugin::OperServ');
use_ok('POE::Component::Server::IRC::Plugin::Auth');
