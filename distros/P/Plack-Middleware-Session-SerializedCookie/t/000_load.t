#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok('Plack::Middleware::Session::SerializedCookie') || BAIL_OUT;
