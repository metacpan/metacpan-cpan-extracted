#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

BEGIN {
	use_ok('POE');
	use_ok('POE::Component::XUL');
	use_ok('POE::XUL::SessionManager');
	use_ok('POE::XUL::Session');
	use_ok('POE::XUL::ChangeManager');
	use_ok('POE::XUL::EventManager');
}
