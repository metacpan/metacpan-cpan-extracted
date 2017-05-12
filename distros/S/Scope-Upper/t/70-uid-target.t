#!perl -T

use strict;
use warnings;

use Test::More tests => 3 + 6 + 4 + 1 + 5;

use Scope::Upper qw<uid HERE UP>;

{
 local $@;
 eval {
  my $here = uid;
 };
 is $@, '', 'uid() does not croak';
}

{
 local $@;
 eval {
  my $here = uid HERE;
 };
 is $@, '', 'uid(HERE) does not croak';
}

{
 local $@;
 eval {
  my $up = uid UP;
 };
 is $@, '', 'uid(UP) does not croak';
}

{
 my $here = uid;
 is $here, uid(),     '$here eq uid()';
 is $here, uid(HERE), '$here eq uid(HERE)';
 {
  is $here, uid(UP),  '$here eq uid(UP) (in block)';
 }
 sub {
  is $here, uid(UP),  '$here eq uid(UP) (in sub)';
 }->();
 local $@;
 eval {
  is $here, uid(UP),  '$here eq uid(UP) (in eval block)';
 };
 eval q{
  is $here, uid(UP),  '$here eq uid(UP) (in eval string)';
 };
}

{
 my $here;
 {
  {
   $here = uid(UP);
   isnt $here, uid(), 'uid(UP) != uid(HERE)';
  }
  is $here, uid(), '$here defined in an older block is now OK';
 }
 isnt $here, uid(), '$here defined in an older block is no longer OK';
 {
  isnt $here, uid(), '$here defined in an older block has been overwritten';
 }
}

{
 my $first;
 for (1, 2) {
  if ($_ == 1) {
   $first = uid();
  } else {
   isnt $first, uid(), 'a new UID for each loop iteration';
  }
 }
}

{
 my $top;
 my $uid;

 sub Scope::Upper::TestUIDDestructor::DESTROY {
  $uid = uid;
  isnt $uid, $top, '$uid is not the outside UID';
  {
   is uid(UP), $uid, 'uid(UP) in block in destructor is correct';
  }
 }

 {
  my $guard = bless [], 'Scope::Upper::TestUIDDestructor';
  $top = uid;
 }
 isnt $uid, undef, '$uid was set in the destructor';

 {
  isnt $uid, uid(), '$uid is no longer valid (in block)';
  sub {
   isnt $uid, uid(), '$uid is no longer valid (in sub in block)';
  }->();
 }
}
