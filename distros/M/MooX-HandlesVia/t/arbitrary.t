{
  # arbitrary class, not leveraging Data::Perl
  package Data::Hash;

  sub new { my $cl = shift; bless({ @_ }, $cl) }

  sub get { $_[0]->{$_[1]} }

  sub set { $_[0]->{$_[1]} = $_[2] }
}

{
  package Ex1;

  use Moo;

  has foos => (
    is => 'ro',
    handles_via => ['Data::Hash'], # test for array deref
    handles => {
      'get_foo' => 'get',
      'set_foo' => 'set',
    },
  );
}

my $ex = Ex1->new(
  foos => Data::Hash->new(one => 1),
);

use Test::More;

is $ex->foos->get('one'), 1, 'getter works with arbitrary class';
is $ex->foos->set('one', 'two'), 'two', 'setter works with arbitrary class';
is $ex->foos->get('one'), 'two', 'getter still works after modification';

done_testing;
