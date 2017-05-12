# -*-cperl-*-
# $Id: 01-load.t,v 1.4 2006/10/23 03:44:29 asc Exp $

use strict;
use Test::More;

plan tests => 15;

use_ok("Net::Delicious");
use_ok("Net::Delicious::Bundle");
use_ok("Net::Delicious::Config");
use_ok("Net::Delicious::Constants");
use_ok("Net::Delicious::Constants::Config");
use_ok("Net::Delicious::Constants::Pause");
use_ok("Net::Delicious::Constants::Response");
use_ok("Net::Delicious::Constants::Uri");
use_ok("Net::Delicious::Date");
use_ok("Net::Delicious::Iterator");
use_ok("Net::Delicious::Object");
use_ok("Net::Delicious::Post");
use_ok("Net::Delicious::Subscription");
use_ok("Net::Delicious::Tag");
use_ok("Net::Delicious::User");
