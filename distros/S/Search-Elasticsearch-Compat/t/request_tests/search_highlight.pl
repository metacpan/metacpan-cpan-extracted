#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# HIGHLIGHT
$r = $es->search(
    query     => { term   => { text => 'foo' } },
    highlight => { fields => { text => {} } }
);

like $r->{hits}{hits}[0]{highlight}{text}[0],
    qr{<em>foo</em>},
    'Highlighting';

1
