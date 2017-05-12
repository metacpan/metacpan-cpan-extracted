#!/usr/local/bin/perl -w
use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 1;

use_ok('Software::License::Apathyware') or exit;
