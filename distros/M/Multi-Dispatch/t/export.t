use v5.22;
use warnings;


use Test::More;
use lib qw< t/tlib tlib >;

plan tests => 4;

use Multi::Dispatch;
no warnings;

multi other ($x, $y, $z) { 'three args' }
use Other;
multi other () { 'no args' }

is other(),                      'no args'    => 'no args';
is other('one'),                 'one arg'    => 'one arg';
is other('one', 'two'),          'two args'   => 'two args';
is other('one', 'two', 'three'), 'three args' => 'three args';

done_testing();


