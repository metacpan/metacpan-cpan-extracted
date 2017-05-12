#!perl

use Test::More tests => 1;

BEGIN {
    use_ok('Server::Control');
}

diag("Testing Server::Control $Server::Control::VERSION, Perl $], $^X");
