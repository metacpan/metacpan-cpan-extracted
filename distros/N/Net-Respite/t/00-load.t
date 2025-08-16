#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;

# Libraries for Respite
require_ok('Net::Respite');
require_ok('Net::Respite::AutoDoc');
require_ok('Net::Respite::Common');
require_ok('Net::Respite::Base');
require_ok('Net::Respite::Client');
require_ok('Net::Respite::CommandLine');
require_ok('Net::Respite::Server::Test');
require_ok('Net::Respite::Server');
require_ok('Net::Respite::Validate');
