use warnings;
use strict;

use Test::More 0.88;
use lib 't/lib';

use TestCoverRequires_Consumer;
use Pod::Coverage::Moose;

my $pcm = Pod::Coverage::Moose->new(package => 'TestCoverRequires_Consumer', cover_requires => 1);
isa_ok $pcm, 'Pod::Coverage::Moose',
    'Moose package coverage object';

is_deeply [sort $pcm->covered], [qw( bar foo )], 'methods from role are covered';
is_deeply [sort $pcm->uncovered], [qw( baz )], 'new method is not covered';

done_testing;
