use strict;
use warnings;

use Test::More;
use Test::Exception;

# test invalid input

lives_ok {
  package foo;
  use Moo;
  use MooX::HandlesVia;

  has asdf => (
    is => 'rw',
    handles => [qw/a b/],
  );

} 'invalid handles ref passed along cleanly';

lives_ok {
  package boo;
  use MooX::HandlesVia;
} 'noop if has() is not found in the samespace';

lives_ok {
  package bop;
  use Moo;
  use MooX::HandlesVia;

  has foo => (is => 'rw');
} 'noop on runs with no handles_via';


lives_ok {
  package baz;
  use Moo;
  use MooX::HandlesVia;

  has asdf => (
    is => 'rw',
    handles_via => 'Hash',
    handles => {
      'existing' => 'get',
      'fake' => 'this_shouldnt_do_anything',
    }
  );

} 'Missing target methods just get ignored';


done_testing;
