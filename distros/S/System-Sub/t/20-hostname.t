
use strict;
use warnings;

use Test::More (-x '/bin/hostname' ? (tests => 4)
                                   : (skip_all => 'No /bin/hostname'));

use System::Sub hostname => [ '$0' => '/bin/hostname' ];

my $expected = `hostname`;
chomp $expected;

$_ = 'canary';
my $got = hostname;
is($got, $expected, 'scalar context');
is($_, 'canary', '$_ not changed');

my @got = hostname;
is_deeply(\@got, [ $expected ], 'list context');
is($_, 'canary', '$_ not changed');

# vim:set et sw=4 sts=4:
