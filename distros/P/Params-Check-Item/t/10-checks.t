#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Params::Check::Item;

plan tests => 56;

sub checkOn  { $ENV{PARAMS_CHECK_ITEM_OFF} = undef; }
sub checkOff { $ENV{PARAMS_CHECK_ITEM_OFF} = 1; }

#checkNumber - 10
{
  checkOn;
  ok(checkNumber(3));
  ok(checkNumber("3"));
  ok(checkNumber(3e10));
  ok(checkNumber(-2.0));

  ok(checkNumber(3), "message");

  dies_ok(sub { checkNumber("no"); });
  dies_ok(sub { checkNumber("no", "message"); });

  #toggle check
  checkOff; ok(checkNumber("no"));
  checkOn;  dies_ok(sub { checkNumber("no"); });
}


#checkInteger - 7
{
  ok(checkInteger(3));
  ok(checkInteger("3"));
  ok(checkInteger(-3.0));
  ok(checkInteger(0.0));

  ok(checkInteger(3), "message");

  dies_ok(sub { checkInteger(1.5); });
  dies_ok(sub { checkInteger(2.0001, "message"); });
}

#checkIndex - 7
{
  ok(checkIndex(3));
  ok(checkIndex("3"));
  ok(checkIndex(0));
  ok(checkIndex(0.0));

  ok(checkIndex(3), "message");

  dies_ok(sub { checkIndex(1.5); });
  dies_ok(sub { checkIndex(-2, "message"); });
}

#checkClass - 7
{
  my $x = bless({}, "AA::BB::CC");

  ok(checkClass($x, "AA::BB::CC"));
  ok(checkClass($x, "AA::BB::CC", "message"));

  dies_ok(sub { checkClass(1); });
  dies_ok(sub { checkClass({}); });
  dies_ok(sub { checkClass([]); });
  dies_ok(sub { checkClass(); });
  dies_ok(sub { checkClass("object"); });
}

#checkNumEQ  - 4
{
  ok(checkNumEQ(5, 5.0));
  ok(checkNumEQ(5, 5.0, "message"));

  dies_ok(sub { checkNumEQ(5, 4); });
  dies_ok(sub { checkNumEQ(5, 4, "message"); });
}

#checkNumNEQ  - 4
{
  ok(checkNumNEQ(5, 5.1));
  ok(checkNumNEQ(5, 5.1, "message"));

  dies_ok(sub { checkNumNEQ(5, 5); });
  dies_ok(sub { checkNumNEQ(5, 5, "message"); });
}

#checkNumLT  - 4
{
  ok(checkNumLT(5, 5.1));
  ok(checkNumLT(5, 5.1, "message"));

  dies_ok(sub { checkNumLT(5, 5); });
  dies_ok(sub { checkNumLT(5, 5, "message"); });
}

#checkNumLTE  - 5
{
  ok(checkNumLTE(5, 5));
  ok(checkNumLTE(5, 5.1));
  ok(checkNumLTE(5, 5.1, "message"));

  dies_ok(sub { checkNumLTE(5, 3); });
  dies_ok(sub { checkNumLTE(5, 3, "message"); });
}

#checkOneOf - 5
{
  ok(checkOneOf(3, ["1", "2", "3"]));
  ok(checkOneOf(3, [1,2,3]));
  ok(checkOneOf(3, ["1", "2", "3"], "message"));

  dies_ok(sub { checkOneOf(3, [1,2]); });
  dies_ok(sub { checkOneOf(3, [1,2], "message"); });
}

#checkImpl - 2
{
  checkOn;
  dies_ok(sub { checkImpl(); }); 
  dies_ok(sub { checkImpl("message"); }); 

  #toggle check
  checkOff; ok(checkImpl("no"));
  checkOn;  dies_ok(sub { checkImpl("no"); });
}






