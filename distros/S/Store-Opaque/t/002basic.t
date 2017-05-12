use strict; use warnings;
use Test::More;
BEGIN { use_ok('Store::Opaque') };
use Data::Dumper qw(Dumper);

package # hide from dep scanners just in case
  HidingSomething;

our @ISA = ('Store::Opaque');

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new;
  return $obj;
}

sub get_hidden_info {
  my $self = shift;
  return $self->_get("cannot see this");
}

sub set_hidden_info {
  my $self = shift;
  my $val = shift;
  return $self->_set("cannot see this", $val);
}

package
  main;

my $n = 1;
if (grep {/--loop/} @ARGV) {
  $n = 100000;
}
foreach (1..$n) {
  my $opaque = HidingSomething->new;
  isa_ok($opaque, 'HidingSomething');
  isa_ok($opaque, 'Store::Opaque');

  can_ok($opaque, $_) for qw(set_hidden_info get_hidden_info new _get _set);

  is($opaque->_get("Does not exist"), undef);

  $opaque->set_hidden_info("foobar");
  is($opaque->get_hidden_info(), 'foobar');
  
  my $dump = Dumper($opaque);
  ok($dump !~ /cannot see this/);
  ok($dump !~ /foobar/);
}

pass("alive");

done_testing;
