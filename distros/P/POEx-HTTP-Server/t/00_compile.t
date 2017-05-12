#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { 
    use_ok('POEx::HTTP::Server::Request');
    use_ok('POEx::HTTP::Server::Response');
    use_ok('POEx::HTTP::Server::Connection');
    use_ok('POEx::HTTP::Server::Error');
    use_ok('POEx::HTTP::Server');
}
