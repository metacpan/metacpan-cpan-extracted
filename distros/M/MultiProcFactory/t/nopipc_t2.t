
use strict;
use MultiProcFactory; 
use Test::More tests => 3; 

my $do_child = sub {
  my $self = shift;
  $self->inc_scalar();
  $self->set_hash_element($self->get_prockey() => $self->get_scalar());
};

my $do_child2 = sub {
  my $self = shift;
  $self->inc_scalar();
  $self->set_hash_element($self->get_prockey() => $self->get_scalar());
  $self->log_child("$$: " . $self->get_hash_element($self->get_prockey()));
};

my $do_child3 = sub {
  my $self = shift;
  $self->dec_scalar();
  $self->set_hash_element($self->get_prockey() => $self->get_scalar());
  $self->log_child("$$: " . $self->get_hash_element($self->get_prockey()));
};

my $do_parent_final = 
sub {
  my $self = shift;

  foreach my $key ($self->get_prockeys()) {
    my $value = $self->get_hash_element($key);
    $self->log_parent("$key: $value\n");
  }
};

my $obj1 = MultiProcFactory->factory(
  IPC_OFF => 1,
  log_parent => 0,
  work_by => 'MultiProcFactory::Generic', 
  do_child => $do_child,
  do_parent_final => $do_parent_final,
  partition_list => [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
  ]
);

isa_ok($obj1, 'MultiProcFactory::Generic');
is($obj1->get_scalar(), undef, "does shared scalar value eq undef ?");
is(test_shared_hash($obj1), 1, "is shared hash memory off ?");

IPC::Shareable->clean_up;

sub test_shared_hash {
  my $obj = shift;

  my $ret = 1;
  foreach my $key ($obj->get_prockeys()) {
    my $value = $obj->get_hash_element($key);

    $ret = 0 if($value);
  }

  return $ret;
}
