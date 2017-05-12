
use strict;
use MultiProcFactory; 
use Test::More tests => 18; 

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
  work_by => 'MultiProcFactory::Generic', 
  do_child => $do_child,
  do_parent_final => $do_parent_final,
  partition_list => [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
  ]
);

isa_ok($obj1, 'MultiProcFactory::Generic');
is($obj1->run(), 1, 'does $obj1->run() return 1 ?');
is($obj1->get_scalar(), 8, "does shared scalar value == 8 ?");
ok((-e 't/generic_t1.log'), "parent log created by default with default log name");
ok((! -e 't/generic_t1_1.log'), "child log not created by default");
is(test_shared_hash($obj1), 1, "is each prockey defined and numeric ?");

## Clean up shared memory

IPC::Shareable->clean_up;
unlink(<t/*log>);

my $obj2 = MultiProcFactory->factory(
  log_file => 't/test2',
  log_children => 1,
  log_parent => 0,
  work_by => 'MultiProcFactory::Generic',
  do_child => $do_child2,
  do_parent_final => $do_parent_final,
  partition_list => [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
  ]
);

isa_ok($obj2, 'MultiProcFactory::Generic');
is($obj2->run(), 1, 'does $obj2->run() returned 1 ?');
is($obj2->get_scalar(), 8, "does shared scalar value == 8 ?");
ok((! -e 't/test2.log'), "parent log not created");
ok((-e 't/test2_1.log'), 'child log created with log_file => test2 as base log name ');
is(test_shared_hash($obj2), 1, "is each prockey defined and numeric ?");

IPC::Shareable->clean_up;
unlink(<t/*log>);

my $obj3 = MultiProcFactory->factory(
    log_file => 't/test3',
    work_by => 'MultiProcFactory::Generic',
    do_child => $do_child3,
    do_parent_final => $do_parent_final,
    partition_list => [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
    ]
);

isa_ok($obj3, 'MultiProcFactory::Generic');
is($obj3->run(), 1, 'does $obj3->run() return 1 ?');
is($obj3->get_scalar(), -8, "does shared scalar value == -8");
ok((-e 't/test3.log'), "parent log created with log_file => test3 as base log_name");
ok((! -e 't/test3_1.log'), "child log not created");
is(test_shared_hash($obj3), 1, "is each prockey defined and numeric ?");

## Cleanup log files
unlink(<t/*log>);

sub test_shared_hash {
  my $obj = shift;

  my $ret = 1;
  foreach my $key ($obj->get_prockeys()) {
    my $value = $obj->get_hash_element($key);

    $ret = 0 unless($value =~ /^\-*?\d+$/);
  }

  return $ret;
}
