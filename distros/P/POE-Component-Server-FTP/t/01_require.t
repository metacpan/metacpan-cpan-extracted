#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

BEGIN {
	use_ok('POE');
	use_ok('POE::Component::Server::FTP');
}
