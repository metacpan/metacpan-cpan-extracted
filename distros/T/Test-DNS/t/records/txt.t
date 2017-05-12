#!perl

use strict;
use warnings;

use Test::More;
use Test::DNS;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns = Test::DNS->new();

# TXT in hash
$dns->is_txt( {
    'godaddy.com' => 'v=spf1 include:spf.secureserver.net -all',
} );

done_testing();

