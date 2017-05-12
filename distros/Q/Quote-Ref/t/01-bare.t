use warnings FATAL => 'all';
no warnings 'qw';
use strict;

use Test::More tests => 6;

use Quote::Ref;

is_deeply qwa(), [];
is_deeply qwh(), {};

is_deeply qwa~a b cee dee~, [qw~a b cee dee~];
is_deeply qwh~a b cee dee~, {qw~a b cee dee~};

is_deeply qwa<f'oo ba"r b<a>z qu#x>, [qw<f'oo ba"r b<a>z qu#x>];
is_deeply qwh<f'oo ba"r b<a>z qu#x>, {qw<f'oo ba"r b<a>z qu#x>};
