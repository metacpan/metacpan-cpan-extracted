package t::Server;
use base 'Test::HTTP::Server';
sub Test::HTTP::Server::Request::boop { "hey world" }
1;
