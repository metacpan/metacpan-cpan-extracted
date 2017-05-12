#!/usr/bin/env perl

use Test::More tests => 1;
use FindBin '$Bin';
use lib "$Bin/../lib";

use_ok('Mojolicious::Plugin::RelativeUrlFor');

__END__
