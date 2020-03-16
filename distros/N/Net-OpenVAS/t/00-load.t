#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Net::OpenVAS');
require_ok('Net::OpenVAS::Error');

require_ok('Net::OpenVAS::OMP');
require_ok('Net::OpenVAS::OMP::Request');
require_ok('Net::OpenVAS::OMP::Response');

done_testing();

diag("Net::OpenVAS $Net::OpenVAS::VERSION, Perl $], $^X");
