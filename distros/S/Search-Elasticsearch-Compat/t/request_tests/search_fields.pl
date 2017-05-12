#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# FIELDS
like $es->search(
    query => { term => { text => 'foo' } },
    fields => [ 'text', 'num' ]
    )->{hits}{hits}[0]{fields}{text},
    qr/foo/,
    'Fields query';

1
