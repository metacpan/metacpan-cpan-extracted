#!/usr/bin/perl

# Adapted from Software::License t/basic.t

use strict;
use warnings;

use Test::More tests => 6;

my $class = 'Software::License::PD';
require_ok($class);

my $license = $class->new({ holder => 'X. Ample' });

is($license->holder, 'X. Ample', '(c) holder');
is($license->year, (localtime)[5]+1900, '(c) year');
like($license->name, qr/public domain/i, 'license name');
like($license->fulltext, qr/public domain/i, 'license text');
is($license->url, 'http://edwardsamuels.com/copyright/beyond/articles/public.html', 'URL');
