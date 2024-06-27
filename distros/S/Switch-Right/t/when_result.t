use v5.36;
use warnings;

use Test2::V0;

use Switch::Right;
use builtin qw< true false >;
use experimental 'builtin';

sub result ($data) {
    given ($data) {
        when (0) { 'zero' }
        when (1) { 'one'  }
        default  { 'many' }
    }
}

sub contextual_result ($data) {
    given ($data) {
        when (0) { qw< zero  nil   nada  > }
        when (1) { qw< one   eins  uno   > }
        default  { qw< many  lots  heaps > }
    }
}

is result(0), 'zero' => 'zero';
is result(1), 'one'  => 'one';
is result(2), 'many' => 'many';

is scalar(contextual_result(0)), 'nada'  => 'scalar - zero';
is scalar(contextual_result(1)), 'uno'   => 'scalar - one';
is scalar(contextual_result(2)), 'heaps' => 'scalar - many';

is [contextual_result(0)], [qw< zero  nil   nada  >] => 'list - zero etc.';
is [contextual_result(1)], [qw< one   eins  uno   >] => 'list - one etc.';
is [contextual_result(2)], [qw< many  lots  heaps >] => 'list - many etc.';

done_testing();


