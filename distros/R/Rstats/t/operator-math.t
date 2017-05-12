use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;
use POSIX();

# operation - pow
{
  my $z1 = r->c_complex({re => 1, im => 2});
  my $z2 = r->c_complex({re => 3, im => 0});
  my $z3 = r->pow($z1, $z2);
  is($z3->value->{re}, -11);
  is($z3->value->{im}, -2);
}

# pow
{
  # pow - dim
  {
    my $x1 = array(c_(5), 2);
    my $x2 = array(c_(2), 2);
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [25, 25]);
  }
  
  # pow - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 ** $x2};
    like($@, qr#\QError in ** : non-numeric argument#);
  }

  # pow - complex
  {
    my $x1 = 1 + 2*i_;
    my $x2 = 3 + 0*i_;
    my $x3 = $x1 ** $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => -11, im => -2}]);
  }

  # pow - double
  {
    my $x1 = c_(5);
    my $x2 = c_(2);
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [25]);
  }

  # pow - integer
  {
    my $x1 = r->as->integer(c_(5));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [25]);
  }

  # pow - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [1]);
  }

  # pow - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # pow - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 ** $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
  
  # pow - different number elements
  {
    my $x1 = c_(5, 3);
    my $x2 = c_(2, 2, 3, 1);
    my $x3 = $x1 ** $x2;
    is_deeply($x3->values, [25, 9, 125, 3]);
  }

  # pow - auto upgrade type
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3);
    my $x3 = $x1 ** $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => -11, im => -2}]);
  }
  
  # pow - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 ** 2;
    is_deeply($x2->values, [1, 4, 9]);
  }

  # pow - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 2 ** $x1;
    is_deeply($x2->values, [2, 4, 8]);
  }
}

# add
{
  # add - dim
  {
    my $x1 = array(c_(1 + 2*i_), 2);
    my $x2 = array(c_(3 + 4*i_), 2);
    my $x3 = $x1 + $x2;
    ok(r->is->complex($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [{re => 4, im => 6}, {re => 4, im => 6}]);
  }
  
  # add - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 + $x2};
    like($@, qr/\QError in + : non-numeric argument/);
  }
  
  # add - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3 + 4*i_);
    my $x3 = $x1 + $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => 4, im => 6}]);
  }
  
  # add - double
  {
    my $x1 = c_(1);
    my $x2 = c_(2);
    my $x3 = $x1 + $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [3]);
  }

  # add - integer
  {
    my $x1 = r->as->integer(c_(1));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 + $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [3]);
  }

  # add - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 + $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [2]);
  }

  # add - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 + $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # add - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 + $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
      
  # add - different number elements
  {
    my $x1 = c_(1, 2);
    my $x2 = c_(3, 4, 5, 6);
    my $x3 = $x1 + $x2;
    is_deeply($x3->values, [4, 6, 6, 8]);
  }

  # add - auto upgrade type
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3);
    my $x3 = $x1 + $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => 4, im => 2}]);
  }
  
  # add - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 + 1;
    is_deeply($x2->values, [2, 3, 4]);
  }

  # add - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 1 + $x1;
    is_deeply($x2->values, [2, 3, 4]);
  }
}

# subtract
{
  # subtract - dim
  {
    my $x1 = array(c_(1), 2);
    my $x2 = array(c_(2), 2);
    my $x3 = $x1 - $x2;
    ok(r->is->double($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [-1, -1]);
  }
  
  # subtract - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 - $x2};
    like($@, qr/\QError in - : non-numeric argument/);
  }
  
  # subtract - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3 + 4*i_);
    my $x3 = $x1 - $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => -2, im => -2}]);
  }
  
  # subtract - double
  {
    my $x1 = c_(1);
    my $x2 = c_(2);
    my $x3 = $x1 - $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [-1]);
  }

  # subtract - integer
  {
    my $x1 = r->as->integer(c_(1));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 - $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [-1]);
  }

  # subtract - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 - $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [0]);
  }

  # subtract - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 - $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # subtract - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 - $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
      
  # subtract - different number elements
  {
    my $x1 = c_(1, 2);
    my $x2 = c_(3, 4, 5, 6);
    my $x3 = $x1 - $x2;
    is_deeply($x3->values, [-2, -2, -4, -4]);
  }

  # subtract - auto upgrade type
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3);
    my $x3 = $x1 - $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => -2, im => 2}]);
  }
  
  # subtract - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 - 1;
    is_deeply($x2->values, [0, 1, 2]);
  }

  # subtract - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 1 - $x1;
    is_deeply($x2->values, [0, -1, -2]);
  }
}

# multiply
{
  # multiply - double
  {
    my $x1 = array(c_(3), 2);
    my $x2 = array(c_(2), 2);
    my $x3 = $x1 * $x2;
    ok(r->is->double($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [6, 6]);
  }

  # multiply - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 * $x2};
    like($@, qr/\QError in * : non-numeric argument/);
  }
  
  # multiply - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3 + 4*i_);
    my $x3 = $x1 * $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => -5, im => 10}]);
  }
  
  # multiply - double
  {
    my $x1 = c_(3);
    my $x2 = c_(2);
    my $x3 = $x1 * $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [6]);
  }

  # multiply - integer
  {
    my $x1 = r->as->integer(c_(3));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 * $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [6]);
  }

  # multiply - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 * $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [1]);
  }

  # multiply - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 * $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # multiply - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 * $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
  
  # multiply - different number elements
  {
    my $x1 = c_(1, 2);
    my $x2 = c_(3, 4, 5, 6);
    my $x3 = $x1 * $x2;
    is_deeply($x3->values, [3, 8, 5, 12]);
  }

  # multiply - auto upgrade type
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3);
    my $x3 = $x1 * $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => 3, im => 6}]);
  }
  
  # multiply - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 * 2;
    is_deeply($x2->values, [2, 4, 6]);
  }

  # multiply - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 2 * $x1;
    is_deeply($x2->values, [2, 4, 6]);
  }
}

# divide
{
  # divide - dim
  {
    my $x1 = array(c_(5), 2);
    my $x2 = array(c_(2), 2);
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [5/2, 5/2]);
  }
  
  # divide - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 / $x2};
    like($@, qr#\QError in / : non-numeric argument#);
  }

  # divide - complex
  {
    my $x1 = 5 + -6*i_;
    my $x2 = 3 + 2*i_;
    my $x3 = $x1 / $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => 3/13, im => -28/13}]);
  }

  # divide - double
  {
    my $x1 = c_(5);
    my $x2 = c_(2);
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [5/2]);
  }

  # divide - integer
  {
    my $x1 = r->as->integer(c_(5));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [5/2]);
  }

  # divide - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [1]);
  }

  # divide - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # divide - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 / $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
  
  # divide - different number elements
  {
    my $x1 = c_(24, 12);
    my $x2 = c_(2, 3, 4, 6);
    my $x3 = $x1 / $x2;
    is_deeply($x3->values, [12, 4, 6, 2]);
  }

  # divide - auto upgrade type
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = c_(3);
    my $x3 = $x1 / $x2;
    ok(r->is->complex($x3));
    is_deeply($x3->values, [{re => 1/3, im => 2/3}]);
  }
  
  # divide - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 / 2;
    is_deeply($x2->values, [1/2, 1, 3/2]);
  }

  # divide - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 2 / $x1;
    is_deeply($x2->values, [2, 1, 2/3]);
  }
}

# remainder
{
  # remainder - double
  {
    my $x1 = array(c_(5), 2);
    my $x2 = array(c_(2), 2);
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    ok(r->dim($x3)->values, [2]);
    is_deeply($x3->values, [1, 1]);
  }

  # remainder - character
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3;
    eval { $x3 = $x1 % $x2};
    like($@, qr#\QError in % : non-numeric argument#);
  }

  # remainder - complex
  {
    my $x1 = 5 + -6*i_;
    my $x2 = 3 + 2*i_;
    my $x3;
    eval { $x3 = $x1 % $x2 };
    like($@, qr#\QError in % : unimplemented complex operation#);
  }

  # remainder - double
  {
    my $x1 = c_(5, 5, 2, 2);
    my $x2 = c_(2, 3, 2/5, 0);
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [1, 2, POSIX::fmod(2, 2/5), "NaN"]);
  }

  # remainder - integer
  {
    my $x1 = r->as->integer(c_(5));
    my $x2 = r->as->integer(c_(2));
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [1]);
  }

  # remainder - logical
  {
    my $x1 = c_(T_);
    my $x2 = c_(T_);
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [0]);
  }

  # remainder - NULL, left
  {
    my $x1 = NULL;
    my $x2 = c_(1);
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }

  # remainder - NULL, right
  {
    my $x1 = c_(1);
    my $x2 = NULL;
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, []);
  }
  
  # remainder - different number elements
  {
    my $x1 = c_(24, 12);
    my $x2 = c_(3, 5, 7, 9);
    my $x3 = $x1 % $x2;
    is_deeply($x3->values, [0, 2, 3, 3]);
  }

  # remainder - auto upgrade type
  {
    my $x1 = c_(5);
    my $x2 = r->as->integer(c_(3));
    my $x3 = $x1 % $x2;
    ok(r->is->double($x3));
    is_deeply($x3->values, [2]);
  }
  
  # remainder - perl number
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = $x1 % 2;
    is_deeply($x2->values, [1, 0, 1]);
  }

  # remainder - perl number,reverse
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = 5 % $x1;
    is_deeply($x2->values, [0, 1, 2]);
  }
}

# negate
{
  # negate - dimention
  {
    my $x1 = array(c_(1, 2, 3));
    my $x2 = -$x1;
    ok(r->is->double($x2));
    is_deeply($x2->values, [-1, -2, -3]);
    is_deeply($x2->dim->values, [3]);
  }
  
  # negate - double
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = -$x1;
    ok(r->is->double($x2));
    is_deeply($x2->values, [-1, -2, -3]);
  }

  # negate - double,NaN
  {
    my $x1 = NaN;
    my $x2 = -$x1;
    ok(r->is->double($x2));
    ok(r->is->nan($x2)->value);
  }
  
  # negate - double,-Inf
  {
    my $x1 = -Inf;
    my $x2 = -$x1;
    ok(r->is->double($x2));
    ok($x2->value, 'Inf');
  }

  # negate - double,Inf
  {
    my $x1 = Inf;
    my $x2 = -$x1;
    ok(r->is->double($x2));
    is($x2->value, '-Inf');
  }

  # negate - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = -$x1;
    ok(r->is->complex($x2));
    is($x2->value->{re}, -1);
    is($x2->value->{im}, -2);
  }
  
  # negate - logical,true
  {
    my $x1 = c_(T_);
    my $x2 = -$x1;
    ok(r->is->integer($x2));
    is($x2->value, -1);
  }

  # negate - logical,false
  {
    my $x1 = c_(F_);
    my $x2 = -$x1;
    ok(r->is->integer($x2));
    is($x2->value, 0);
  }
  
  # negate - NA
  {
    my $x1 = NA;
    my $x2 = r->negate($x1);
    ok(r->is->integer($x2));
    ok(r->is->na($x2));
  }
}

# logical operator
{
  # logical operator - &
  {
    my $x1 = c_(TRUE, FALSE, TRUE, FALSE);
    my $x2 = c_(TRUE, TRUE, FALSE, FALSE);
    my $x3 = $x1 & $x2;
    my $proxy = r->is;
    ok(r->is->logical($x3));
    ok($x3->is->logical);
    ok(r->is->logical($x3));
    ok($x3->is->logical);
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/1 0 0 0/]);
  }
  
  # logical operator - |
  {
    my $x1 = c_(TRUE, FALSE, TRUE, FALSE);
    my $x2 = c_(TRUE, TRUE, FALSE, FALSE);
    my $x3 = $x1 | $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/1 1 1 0/]);
  }
}

# bool
{
  {
    my $x1 = array(1);
    if ($x1) {
      pass;
    }
    else {
      fail;
    }
  }
  
  # bool - one argument, false
  {
    my $x1 = array(0);
    if ($x1) {
      fail;
    }
    else {
      pass;
    }
  }

  # bool - two argument, true
  {
    my $x1 = array(3, 3);
    if ($x1) {
      pass;
    }
    else {
      fail;
    }
  }

  # bool - two argument, true
  {
    my $x1 = r->NULL;
    eval {
      if ($x1) {
      
      }
    };
    like($@, qr/zero/);
  }

  # bool - logical,TRUE
  {
    my $x1 = TRUE;
    ok($x1);
  }
  
  # bool - logical,FALSE
  {
    my $x1 = FALSE;
    ok(!$x1);
  }
}

# numeric operator auto upgrade
{
  # numeric operator auto upgrade - complex
  {
    my $x1 = array(c_(r->complex(1,2), r->complex(3,4)));
    my $x2 = array(c_(1, 2));
    my $x3 = $x1 + $x2;
    ok(r->is->complex($x3));
    is($x3->values->[0]->{re}, 2);
    is($x3->values->[0]->{im}, 2);
    is($x3->values->[1]->{re}, 5);
    is($x3->values->[1]->{im}, 4);
  }

  # numeric operator auto upgrade - integer
  {
    my $x1 = r->as->integer(c_(3, 5));
    my $x2 = c_(TRUE, FALSE);
    my $x3 = $x1 + $x2;
    ok(r->is->integer($x3));
    is_deeply($x3->values, [4, 5])
  }
    
  # numeric operator auto upgrade - numeric
  {
    my $x1 = array(c_(1.1, 1.2));
    my $x2 = r->as->integer(array(c_(1, 2)));
    my $x3 = $x1 + $x2;
    ok(r->is->numeric($x3));
    is_deeply($x3->values, [2.1, 3.2])
  }

  # numeric operator auto upgrade - character, +
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 + $x2 };
    like($@, qr/non-numeric argument/);
  }

  # numeric operator auto upgrade - character, -
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 - $x2 };
    like($@, qr/non-numeric argument/);
  }

  # numeric operator auto upgrade - character, *
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 * $x2 };
    like($@, qr/non-numeric argument/);
  }

  # numeric operator auto upgrade - character, /
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 / $x2 };
    like($@, qr/non-numeric argument/);
  }

  # numeric operator auto upgrade - character, ^
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 ** $x2 };
    like($@, qr/non-numeric argument/);
  }

  # numeric operator auto upgrade - character, %
  {
    my $x1 = array(c_("1", "2", "3"));
    my $x2 = array(c_(1, 2, 3));
    eval { my $ret = $x1 % $x2 };
    like($@, qr/non-numeric argument/);
  }
}

# numeric operator
{
  # numeric operator - -Inf + 2i
  {
    my $x2 = c_(2*i_);
    my $x1 = c_(-Inf);
    my $x3 = $x1 + $x2;
    is($x3->value->{re}, '-Inf');
    is($x3->value->{im}, 2);
  }

  # numeric operator - -0.2 * -Inf
  {
    my $x1 = c_(-0.2);
    my $x2 = c_(-Inf);
    my $x3 = $x1 * $x2;
    is_deeply($x3->values, ['Inf']);
  }
}
