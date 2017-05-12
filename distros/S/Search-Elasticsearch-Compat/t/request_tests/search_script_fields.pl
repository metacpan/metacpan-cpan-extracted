#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# SCRIPT FIELDS
isa_ok $r= $es->search(
    query         => { match_all  => {} },
    script_fields => { double_num => { script => "doc['num'].value * 2" } },
    fields => ['num']
    ),
    'HASH',
    'Script fields query';
is $r->{hits}{hits}[0]{fields}{double_num},
    2 * $r->{hits}{hits}[0]{fields}{num},
    ' - script field calculated';

1;
