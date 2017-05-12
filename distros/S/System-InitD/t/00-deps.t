#!/usr/bin/env perl
use strict;

use Test::More tests => 8;

my $p = 'System::InitD';

use_ok($p);
use_ok($p . '::Base');
use_ok($p . '::Const');
use_ok($p . '::GenInit');
use_ok($p . '::Runner');
use_ok($p . '::Template');
# templates
use_ok($p . '::GenInit::Debian');
use_ok($p . '::GenInit::Centos');
