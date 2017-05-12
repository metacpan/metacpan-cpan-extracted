use strict;
use warnings;
use Data::Perl::Collection::Hash::MooseLike;
{
  package Ex1;

  use Moo;
  use MooX::HandlesVia;

  has foos => (
    is => 'ro',
    handles => {
      'get_foo' => 'get',
      'set_foo' => 'set',
    },
  );

  has bars => (
    is => 'ro',
    handles => {
      'get_bar' => '${\Data::Perl::Collection::Hash::MooseLike->can("get")}',
      'set_bar' => '${\Data::Perl::Collection::Hash::MooseLike->can("set")}',
    },
  );

  has bazes => (
    is => 'rw',
    handles_via => 'Hash',
    handles => {
      get_baz => 'get',
      bazkeys => 'keys'
    }
  );
}

my $ex = Ex1->new(
  foos => Data::Perl::Collection::Hash::MooseLike->new(one => 1),
  bars => { one => 1 },
  bazes => { ate => 'nine', two => 'five' },
);

use Test::More;
use Test::Exception;

is ($ex->get_foo('one'), 1, 'get_foo worked');
is ($ex->get_bar('one'), 1, 'get_bar worked');

is ($ex->set_foo('two', 2), 2, 'set_foo worked');
is ($ex->set_bar('two', 2), 2, 'set_bar worked');

is ($ex->foos->{'two'}, 2, 'foos accessor worked');

is ($ex->get_baz('ate'), 'nine', 'get_baz worked');
is_deeply([sort $ex->bazkeys], [qw/ate two/] , 'bazkeys worked');

done_testing;
