#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Warnings 0.005 qw(warning);
use Test::Differences;

delete @ENV{qw{PATH ENV IFS CDPATH BASH_ENV}};

my $d = 't/basic-dummy';

use_ok( 'Run::Parts' );

like(warning { eval { Run::Parts->new($d, 'foobar'); }},
     qr/Unknown backend foobar in use/,
     "Warn's about unknown backends");

done_testing();
