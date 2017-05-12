use strictures 1;
use Test::More;
use Test::Fatal;

{
  package MooSetOnce;
  use Moo;
  use MooX::SetOnce;

  has one => (is => 'rw');
  has two => (is => 'rw', once => 1);
  has three => (is => 'rwp', once => 1);
  has four => (is => 'rw', writer => 'set_four', once => 1);
  has five => (is => 'rw', lazy => 1, default => sub { 1 }, once => 1);
  has six => (is => 'rw', predicate => 'six_exists', once => 1);
  has seven => (is => 'rw', clearer => 'clear_seven', predicate => 'has_seven', once => 1);
}

{
  package MooSetOnceRole;
  use Moo::Role;
  use MooX::SetOnce;

  has one => (is => 'rw');
  has two => (is => 'rw', once => 1);
  has three => (is => 'rwp', once => 1);
  has four => (is => 'rw', writer => 'set_four', once => 1);
  has five => (is => 'rw', lazy => 1, default => sub { 1 }, once => 1);
  has six => (is => 'rw', predicate => 'six_exists', once => 1);
  has seven => (is => 'rw', clearer => 'clear_seven', predicate => 'has_seven', once => 1);
}

{
  package MooSetOnceFromRole;
  use Moo;
  with 'MooSetOnceRole';
}

if (!caller) {
  test_object(MooSetOnce->new);
  test_object(MooSetOnceFromRole->new);
  done_testing;
}

sub test_object {
  my $o = shift;
  is exception {
    $o->one(1);
    $o->one(2);
  }, undef, "SetOnce doesn't apply unless specified";

  is exception {
    $o->two(1);
  }, undef, "first set works";

  like exception {
    $o->two(1);
  }, qr/cannot change value of SetOnce attribute two/, "second set dies";

  is exception {
    $o->_set_three(1);
  }, undef, "rwp: first set works";

  like exception {
    $o->_set_three(1);
  }, qr/cannot change value of SetOnce attribute three/, "rwp: second set dies";

  is exception {
    $o->set_four(1);
  }, undef, "explicit writer: first set works";

  like exception {
    $o->set_four(1);
  }, qr/cannot change value of SetOnce attribute four/, "explicit writer: second set dies";

  is exception {
    $o->five;
  }, undef, "lazy set by default works";

  like exception {
    $o->five(1);
  }, qr/cannot change value of SetOnce attribute five/, "lazy changed after set dies";

  is exception {
    $o->six(1);
  }, undef, "explicit predicate: first set works";

  like exception {
    $o->six(1);
  }, qr/cannot change value of SetOnce attribute six/, "explicit predicate: second set dies";

  $o->seven(1);
  $o->clear_seven;
  is exception {
    $o->seven(1);
  }, undef, "set after clear allowed";
}
