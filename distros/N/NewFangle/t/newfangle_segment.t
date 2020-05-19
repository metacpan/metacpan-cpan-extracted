use Test2::V0 -no_srand => 1;
use lib 't/lib';
use LiveTest;
use NewFangle;

my $app = NewFangle::App->new;

my $txn = $app->start_web_transaction("web3");

is(
  $txn->start_segment("foo",undef),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
    call [ set_timing => 44, 500 ] => T();
    call end => T();
  },
);


is(
  $txn->start_datastore_segment(["MySQL",undef,undef,undef,undef,undef,"SELECT * FROM foo"]),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
  },
);

is(
  $txn->start_external_segment(["http://foo.com", "GET", undef]),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
  },
);

is(
  $txn->start_segment("new-root", undef),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
    call set_parent_root => T();
  },
);

my $middle;

is(
  $middle = $txn->start_segment("middle", undef),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
  },
);

is(
  $txn->start_segment("new-child1", undef),
  object {
    call [ isa => 'NewFangle::Segment' ] => T();
    call [ set_parent => $middle ] => T();
  },
);

done_testing;
