#!perl -w

use strict;
use Test::More tests => 3;

use_ok('Net::Google::Calendar::Server');
use_ok('Net::Google::Calendar::Server::Backend::ICalendar');
use_ok('Net::Google::Calendar::Server::Auth::Dummy');
#use_ok('Net::Google::Calendar::Server::Handler::Apache');
#use_ok('Net::Google::Calendar::Server::Handler::Apache2');
