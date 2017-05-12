#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper qw(Dumper);

plan skip_all => "These tests are for authors only!"
    unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

use Pod::Generate::Recursive;    
my $pgr = Pod::Generate::Recursive->new();
$pgr->debug(0);
$pgr->destination("docs/");
$pgr->source("catalyst/");

ok($pgr->source() eq "catalyst/", "Source Directory");
ok($pgr->destination() eq "docs/", "Destination Directory");
is($pgr->debug(), 0, "Debug");

done_testing();
