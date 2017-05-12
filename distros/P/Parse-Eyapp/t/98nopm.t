#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;

SKIP: {
  skip("Developer test", 1) unless $ENV{DEVELOPER};

     my $files = [ glob('*.pm') ];

     is_deeply($files, [], 'No .pm files were generated during testing');
}

