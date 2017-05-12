use strict;
use warnings;

use Test::More tests => 5;

require_ok('Moose::Autobox');

use Moose::Autobox;

my $string = 'foo';
my $list = ['foo', 'bar'];

is $string->first, 'foo';
is $string->last, 'foo';

is $list->first, 'foo';
is $list->last, 'bar';
