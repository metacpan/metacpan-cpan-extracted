#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib', '../lib';
use Test::More tests => 6;

use_ok('Net::OAuth2');
diag( "Testing Net::OAuth2 $Net::OAuth2::VERSION, Perl $], $^X" );

use_ok('Net::OAuth2::Client');
use_ok('Net::OAuth2::AccessToken');
use_ok('Net::OAuth2::Profile');
use_ok('Net::OAuth2::Profile::WebServer');
use_ok('Net::OAuth2::Profile::Password');
