#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Test::More;
use_ok 'Mojolicious::Plugin::SPNEGO';

done_testing;
