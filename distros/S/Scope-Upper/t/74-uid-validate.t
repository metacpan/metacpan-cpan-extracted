#!perl -T

use strict;
use warnings;

use Test::More tests => 6 + 5 + 4 + 1 + 9;

use Scope::Upper qw<uid validate_uid HERE UP>;

{
 local $@;
 my $here = uid;
 eval {
  validate_uid($here);
 };
 is $@, '', 'validate_uid(uid) does not croak';
}

{
 local $@;
 my $here = uid;
 eval {
  validate_uid('123');
 };
 my $line = __LINE__-2;
 like $@, qr/^UID contains only one part at \Q$0\E line $line/,
                                                   'validate_uid("123") croaks';
}

for my $wrong ('1.23-4', 'abc-5') {
 local $@;
 my $here = uid;
 eval {
  validate_uid($wrong);
 };
 my $line = __LINE__-2;
 like $@, qr/^First UID part is not an unsigned integer at \Q$0\E line $line/,
                                              "validate_uid(\"$wrong\") croaks";
}

for my $wrong ('67-8.9', '001-def') {
 local $@;
 my $here = uid;
 eval {
  validate_uid($wrong);
 };
 my $line = __LINE__-2;
 like $@, qr/^Second UID part is not an unsigned integer at \Q$0\E line $line/,
                                              "validate_uid(\"$wrong\") croaks";
}

{
 my $here = uid;
 ok validate_uid($here), '$here is valid (same scope)';
 {
  ok validate_uid($here), '$here is valid (in block)';
 }
 sub {
  ok validate_uid($here), '$here is valid (in sub)';
 }->();
 local $@;
 eval {
  ok validate_uid($here), '$here is valid (in eval block)';
 };
 eval q{
  ok validate_uid($here), '$here is valid (in eval string)';
 };
}

{
 my $here;
 {
  {
   $here = uid(UP);
   ok validate_uid($here), '$here is valid (below)';
  }
  ok validate_uid($here), '$here is valid (exact)';
 }
 ok !validate_uid($here), '$here is invalid (above)';
 {
  ok !validate_uid($here), '$here is invalid (new block)';
 }
}

{
 my $first;
 for (1, 2) {
  if ($_ == 1) {
   $first = uid();
  } else {
   ok !validate_uid($first), 'a new UID for each loop iteration';
  }
 }
}

{
 my $top;
 my $uid;

 sub Scope::Upper::TestUIDDestructor::DESTROY {
  ok !validate_uid($top),
                      '$top defined after the guard is not valid in destructor';
  $uid = uid;
  ok validate_uid($uid), '$uid is valid in destructor';
  my $up;
  {
   $up = uid;
   ok validate_uid($up), '$up is valid in destructor';
  }
  ok !validate_uid($up), '$up is no longer valid in destructor';
 }

 {
  my $guard = bless [], 'Scope::Upper::TestUIDDestructor';
  $top = uid;
  ok validate_uid($top), '$top defined after the guard is valid in block';
 }
 ok !validate_uid($top), '$top is no longer valid outside of the block';
 ok !validate_uid($uid), '$uid is no longer valid outside of the destructor';

 sub Scope::Upper::TestUIDDestructor2::DESTROY {
  ok validate_uid($top), '$top defined before the guard is valid in destructor';
 }

 SKIP: {
  skip 'Destructors are always last before perl 5.8' => 2 if "$]" < 5.008;

  $top = uid;
  my $guard = bless [], 'Scope::Upper::TestUIDDestructor2';
  ok validate_uid($top), '$top defined before the guard is valid in block';
 }
}
