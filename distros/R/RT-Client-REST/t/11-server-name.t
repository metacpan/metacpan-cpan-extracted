#!perl

use strict;
use warnings;
use Test::More tests => 5;
use RT::Client::REST;

my $rt = RT::Client::REST->new(server => 'http://localhost/');

is $rt->server, 'http://localhost', 'Trailing slash stripped';
is $rt->_rest, 'http://localhost/REST/1.0', 'rest uri ok';


$rt = RT::Client::REST->new(server => 'http://localhost/bts/',
                            timeout => '10/', # bogus
                           );

is $rt->server, 'http://localhost/bts', 'Trailing slash stripped';
is $rt->_rest, 'http://localhost/bts/REST/1.0', 'rest uri ok';
is $rt->timeout, '10/', 'trailing slash on timeout preserved, even if bogus';
