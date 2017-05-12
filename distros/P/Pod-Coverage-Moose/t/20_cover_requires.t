use warnings;
use strict;

use Test::More;
use lib 't/lib';

use_ok  'TestCoverRequires_Consumer',    'consumer test class loaded ok';
use_ok  'Pod::Coverage::Moose',             'pcm loaded ok';

my $pcm = Pod::Coverage::Moose->new(package => 'TestCoverRequires_Consumer', cover_requires => 1);
isa_ok $pcm, 'Pod::Coverage::Moose',
    'Moose package coverage object';

is_deeply [sort $pcm->covered], [qw( bar foo )], 'methods from role are covered';
is_deeply [sort $pcm->uncovered], [qw( baz )], 'new method is not covered';

done_testing;
