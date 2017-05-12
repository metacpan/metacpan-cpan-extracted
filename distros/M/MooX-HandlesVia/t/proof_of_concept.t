{
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
    handles => {
      'get_foo' => 'get',
      'set_foo' => 'set',
    },
  );

  has bars => (
    is => 'ro',
    handles => {
      'get_bar' => '${\Data::Hash->can("get")}',
      'set_bar' => '${\Data::Hash->can("set")}',
    },
  );
}

my $ex = Ex1->new(
  foos => Data::Hash->new(one => 1),
  bars => { one => 1 },
);

use Test::More;

foreach my $name (qw(foo bar)) {

  is($ex->${\"get_${name}"}('one'), 1);

  $ex->${\"set_${name}"}('two', 2);

  is($ex->${\"${name}s"}->{'two'}, 2);
}

done_testing;
