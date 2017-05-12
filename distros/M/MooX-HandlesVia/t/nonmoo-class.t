BEGIN {
{
  package inherit;

  sub new {
    return bless +{}, shift;
  }
}

{
  package Ex1;

  use Moo;
  use MooX::HandlesVia;

  extends 'inherit';

  has foos => (
    is => 'ro',
    handles_via => 'Hash',
    handles => {
      'get_foo' => 'get',
      'set_foo' => 'set',
    },
  );
}
};

use Test::More;

my $ex = Ex1->new(
  foos => { a => 'b' },
);
my $isa = $ex->isa('Moo::Object');
ok !$ex->isa('Moo::Object'), 'class doesnt inherit from moo';

ok $ex->get_foo('a') eq 'b', 'handlesVia still applied';

done_testing;
