#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

# Libraries for Respite
require_ok('Respite');
require_ok('Respite::AutoDoc');
require_ok('Respite::Base');
require_ok('Respite::Client');
require_ok('Respite::CommandLine');
require_ok('Respite::Server::Test');
require_ok('Respite::Server');
require_ok('Respite::Validate');
