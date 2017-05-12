#!perl

use Test::More;

use strict;
use warnings;
no warnings 'redefine';

our $es;
my $r;

### ANALYZER ###
is $es->analyze(
    index        => 'es_test_1',
    text         => 'tHE BLACK and white! AND red',
    format       => 'text',
    prefer_local => 0,
    )->{tokens},
    "[black:4->9:<ALPHANUM>]\n\n4: \n[white:14->19:<ALPHANUM>]\n\n6: \n[red:25->28:<ALPHANUM>]\n",
    'Analyzer';

is_deeply tokens( text => 'Foo Bar' ), [ 'foo', 'bar' ], '- no opts';

is_deeply tokens(
    text      => 'Foo Bar',
    tokenizer => 'keyword',
    filters   => 'lowercase'
    ),
    ['foo bar'],
    ' - tokenizer filters';

is_deeply tokens(
    index => 'es_test_1',
    field => 'type_1.text',
    text  => 'Foo Bar'
    ),
    [ 'foo', 'bar' ],
    '- index field';

sub tokens {
    my $result = $es->analyze(@_)->{tokens};
    [ map { $_->{token} } @$result ];
}

1;

