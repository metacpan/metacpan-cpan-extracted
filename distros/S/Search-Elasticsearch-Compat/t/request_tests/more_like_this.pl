#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### MORE LIKE THIS
is $es->mlt(
    index         => 'es_test_1',
    type          => 'type_1',
    id            => 1,
    mlt_fields    => ['text'],
    min_term_freq => 1,
    min_doc_freq  => 1
    )->{hits}{total}, 4,
    'more_like_this';

1
