use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# array upgrade mode
{
  # array decide mode - complex
  {
    my $x0 = r->complex(3, 4);
    my $x0_1 = c_(1, $x0);
    my $x1 = array($x0_1);
    is($x1->values->[0]->{re}, 1);
    is($x1->values->[0]->{im}, 0);
    is($x1->values->[1]->{re}, 3);
    is($x1->values->[1]->{im}, 4);
    ok(r->is->complex($x1));
  }
}

# as->integer
{
  # as->integer - NA
  {
    my $x1 = NA;
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [undef]);
  }

  # as->integer - Inf
  {
    my $x1 = Inf;
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [undef]);
  }
  # as->integer - NULL
  {
    my $x1 = NULL;
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, []);
  }
  
  # as->integer - dim
  {
    my $x1 = array(c_(1, 2));
    my $x2 = r->as->integer($x1);
    is_deeply($x2->dim->values, [2]);
  }

  # as->integer - double,NaN
  {
    my $x1 = NaN;
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [undef]);
  }
  
  # as->integer - character, only real number, no sign
  {
    my $x1 = c_("1.23");
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }

  # as->integer - character, only real number, plus
  {
    my $x1 = c_("+1");
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }
  
  # as->integer - character, only real number, minus
  {
    my $x1 = c_("-1.23");
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], -1);
  }

  # as->integer - character, pre and trailing space
  {
    my $x1 = c_("  1  ");
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }

  # as->integer - error
  {
    my $x1 = c_("a");
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], undef);
  }
  
  # as->integer - complex, 1 + 2*i
  {
    my $x1 = r->complex(1, 2);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }

  # as->integer - complex, Inf + 1*i
  {
    my $x1 = r->complex(Inf, 1);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], undef);
  }

  # as->integer - complex, 1 + Inf*i
  {
    my $x1 = r->complex(1, Inf);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], undef);
  }

  # as->integer - complex,  NaN + 1*i
  {
    my $x1 = r->complex(NaN, 1);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], undef);
  }

  # as->integer - complex,  1 + NaN*i
  {
    my $x1 = r->complex(1, NaN);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], undef);
  }
  
  # as->integer - double
  {
    my $x1 = c_(1.1);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }
  
  # as->integer - integer
  {
    my $x1 = c_(1);
    my $x2 = r->as->integer(r->as->integer($x1));
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
  }
  
  # as->integer - logical
  {
    my $x1 = c_(TRUE, FALSE);
    my $x2 = r->as->integer($x1);
    ok(r->is->integer($x2));
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }
}

# as->double
{
  # as->double - error
  {
    my $x1 = array("a");
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], undef);
  }
  
  # as->double - NULL
  {
    my $x1 = NULL;
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, []);
  }

  # as->double - dim
  {
    my $x1 = array(c_(1.1, 1.2));
    my $x2 = r->as->double($x1);
    is_deeply($x2->dim->values, [2]);
  }
  
  # as->double - Inf
  {
    my $x1 = Inf;
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, ['Inf']);
  }

  # as->double - NA
  {
    my $x1 = array(NA);
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [undef]);
  }

  # as->double - NaN
  {
    my $x1 = NaN;
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, ['NaN']);
  }

  # as->double - character, only real number, no sign
  {
    my $x1 = array("1.23");
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1.23);
  }

  # as->double - character, only real number, plus
  {
    my $x1 = array("+1.23");
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1.23);
  }
  
  # as->double - character, only real number, minus
  {
    my $x1 = array("-1.23");
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], -1.23);
  }

  # as->double - character, pre and trailing space
  {
    my $x1 = array("  1  ");
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1);
  }

  # as->double - complex
  {
    my $x1 = array(r->complex(1, 2));
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1);
  }
  
  # as->double - double
  {
    my $x1 = array(1.1);
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1.1);
  }
  
  # as->double - integer
  {
    my $x1 = array(1);
    my $x2 = r->as->double(r->as->integer($x1));
    ok(r->is->double($x2));
    is($x2->values->[0], 1);
  }
  
  # as->double - logical
  {
    my $x1 = array(c_(TRUE, FALSE));
    my $x2 = r->as->double($x1);
    ok(r->is->double($x2));
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }
}

# as->numeric
{
  # as->numeric - from integer
  {
    my $x1 = c_(0, 1, 2);
    r->mode($x1 => 'integer');
    my $x2 = r->as->numeric($x1);
    is(r->mode($x2)->value, 'numeric');
    is_deeply($x2->values, [0, 1, 2]);
  }
  
  # as->numeric - from complex
  {
    my $x1 = c_(r->complex(1, 1), r->complex(2, 2));
    r->mode($x1 => 'complex');
    my $x2 = r->as->numeric($x1);
    is(r->mode($x2)->value, 'numeric');
    is_deeply($x2->values, [1, 2]);
  }

  # as->numeric - from numeric
  {
    my $x1 = c_(0.1, 1.1, 2.2);
    r->mode($x1 => 'numeric');
    my $x2 = r->as->numeric($x1);
    is(r->mode($x2)->value, 'numeric');
    is_deeply($x2->values, [0.1, 1.1, 2.2]);
  }
  
  # as->numeric - from logical
  {
    my $x1 = c_(r->TRUE, r->FALSE);
    r->mode($x1 => 'logical');
    my $x2 = r->as->numeric($x1);
    is(r->mode($x2)->value, 'numeric');
    is_deeply($x2->values, [1, 0]);
  }

  # as->numeric - from character
  {
    my $x1 = r->as->integer(c_(0, 1, 2));
    my $x2 = r->as->numeric($x1);
    is(r->mode($x2)->value, 'numeric');
    is_deeply($x2->values, [0, 1, 2]);
  }
}

# as->logical
{ 
  # as->logical - NULL
  {
    my $x1 = NULL;
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is_deeply($x2->values, []);
  }
  
  # as->logical - dim
  {
    my $x1 = array(c_(1.1, 0));
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is_deeply($x2->dim->values, [2]);
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }
  
  # as->logical - Inf
  {
    my $x1 = Inf;
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is_deeply($x2->values, [1]);
  }

  # as->logical - NA
  {
    my $x1 = NA;
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is_deeply($x2->values, [undef]);
  }

  # as->logical - doubke,NaN
  {
    my $x1 = NaN;
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is_deeply($x2->values, [undef]);
  }
  
  # as->logical - character, double
  {
    my $x1 = c_("1.23");
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], undef);
  }

  # as->logical - character, pre and trailing space
  {
    my $x1 = c_("  1  ");
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], undef);
  }

  # as->logical - character
  {
    my $x1 = c_("a");
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], undef);
  }

  # as->logical - complex, 1 + NaN*i
  {
    my $x1 = r->complex(1, NaN);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], undef);
  }

  # as->logical - complex, NaN + 1*i
  {
    my $x1 = r->complex(NaN, 1);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], undef);
  }
  
  # as->logical - complex, 1 + 0*i
  {
    my $x1 = r->complex(1, 0);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
  }

  # as->logical - complex, Inf + 0*i
  {
    my $x1 = r->complex(1, 0);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
  }
  
  # as->logical - complex, 0 + 1*i
  {
    my $x1 = r->complex(0, 1);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
  }
  
  # as->logical - complex, 0 + 0i
  {
    my $x1 = r->complex(0, 0);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 0);
  }
  
  # as->logical - double
  {
    my $x1 = c_(1.1, 0);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }

  # as->logical - integer
  {
    my $x1 = c_(2, 0);
    my $x2 = r->as->logical(r->as->integer($x1));
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }
    
  # as->logical - logical
  {
    my $x1 = c_(TRUE, FALSE);
    my $x2 = r->as->logical($x1);
    ok(r->is->logical($x2));
    is($x2->values->[0], 1);
    is($x2->values->[1], 0);
  }
}

# is_*
{
  # is_* - is_array
  {
    my $x = array(C_('1:24'), c_(4, 3, 2));
    ok(r->is->array($x));
    ok(!r->is->vector($x));
    ok(!r->is->matrix($x));
  }

  # is_* - is_matrix
  {
    my $x = matrix(C_('1:12'), 4, 3);
    ok(r->is->matrix($x));
    ok(r->is->array($x));
  }

  # is_* - is_vector
  {
    my $x = C_('1:24');
    ok(r->is->vector($x));
    ok(!r->is->array($x));
  }

  # is_* - is_vector
  {
    my $x = array(C_('1:24'));
    ok(!r->is->vector($x));
    ok(r->is->array($x));
  }
}

# as->character
{
  # as->double - NULL
  {
    my $x1 = NULL;
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is_deeply($x2->values, []);
  }
  
  # as->character - complex
  {
    my $x0 = r->complex(1, 2);
    my $x1 = array(r->complex(1, 2));
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is($x2->values->[0], "1+2i");
  }

  # as->character - NA
  {
    my $x1 = array(NA);
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is_deeply($x2->values, [undef]);
  }

  # as->character - Inf
  {
    my $x1 = Inf;
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is_deeply($x2->values, ["Inf"]);
  }

  # as->character - NaN
  {
    my $x1 = NaN;
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is_deeply($x2->values, ["NaN"]);
  }
  
  # as->character - character
  {
    my $x1 = array(c_("a"));
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is($x2->values->[0], "a");
  }
  
  # as->character - complex, 0 + 0i
  {
    my $x1 = array(r->complex(0, 0));
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is($x2->values->[0], "0+0i");
  }
  
  # as->character - numeric
  {
    my $x1 = array(c_(1.1, 0));
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is($x2->values->[0], 1.1);
    is($x2->values->[1], "0");
  }
  
  # as->character - logical
  {
    my $x1 = array(c_(TRUE, FALSE));
    my $x2 = r->as->character($x1);
    ok(r->is->character($x2));
    is($x2->values->[0], "TRUE");
    is($x2->values->[1], "FALSE");
  }
}

# as->numeric
{
  # as->numeric - character, pre and trailing space
  {
    my $x1 = array("  1  ");
    my $x2 = r->as->numeric($x1);
    ok(r->is->numeric($x2));
    is($x2->values->[0], 1);
  }
}

# as->complex
{
  # as->complex - NULL
  {
    my $x1 = NULL;
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, []);
  }

  # as->complex - Inf
  {
    my $x1 = Inf;
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 'Inf');
    is($x2->values->[0]->{im}, 0);
  }

  # as->complex - NA
  {
    my $x1 = array(NA);
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, [undef]);
  }

  # as->complex - NaN
  {
    my $x1 = NaN;
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, [{re => 'NaN', im => 0}]);
  }

  # as->complex - character, only real number, no sign
  {
    my $x1 = array("1.23");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1.23);
    is($x2->values->[0]->{im}, 0);
  }

  # as->complex - character, only real number, pre and trailing space
  {
    my $x1 = array("  1.23  ");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1.23);
    is($x2->values->[0]->{im}, 0);
  }
  
  # as->complex - character, only real number, plus
  {
    my $x1 = array("+1.23");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1.23);
    is($x2->values->[0]->{im}, 0);
  }
  
  # as->complex - character, only real number, minus
  {
    my $x1 = array("-1.23");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, -1.23);
    is($x2->values->[0]->{im}, 0);
  }

  # as->complex - character, only image number, no sign
  {
    my $x1 = array("1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 0);
    is($x2->values->[0]->{im}, 1.23);
  }

  # as->complex - character, only image number, plus
  {
    my $x1 = array("+1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 0);
    is($x2->values->[0]->{im}, 1.23);
  }

  # as->complex - character, only image number, minus
  {
    my $x1 = array("-1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 0);
    is($x2->values->[0]->{im}, -1.23);
  }

  # as->complex - character, real number and image number, no sign
  {
    my $x1 = array("2.5+1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 2.5);
    is($x2->values->[0]->{im}, 1.23);
  }

  # as->complex - character, real number and image number, plus
  {
    my $x1 = array("+2.5+1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 2.5);
    is($x2->values->[0]->{im}, 1.23);
  }
  
  # as->complex - character, real number and image number, minus
  {
    my $x1 = array("-2.5-1.23i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, -2.5);
    is($x2->values->[0]->{im}, -1.23);
  }

  # as->complex - character, pre and trailing space
  {
    my $x1 = array("  2.5+1.23i  ");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 2.5);
    is($x2->values->[0]->{im}, 1.23);
  }

  # as->complex - error
  {
    my $x1 = array("a");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0], undef);
  }

  # as->complex - error
  {
    my $x1 = array("i");
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0], undef);
  }
        
  # as->complex - complex
  {
    my $x1 = array(r->complex(1, 2));
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1);
    is($x2->values->[0]->{im}, 2);
  }
  
  # as->complex - numeric
  {
    my $x1 = array(1.1);
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1.1);
    is($x2->values->[0]->{im}, 0);
  }
  
  # as->complex - integer
  {
    my $x1 = array(1);
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1);
    is($x2->values->[0]->{im}, 0);
  }
  
  # as->complex - logical
  {
    my $x1 = array(c_(TRUE, FALSE));
    my $x2 = r->as->complex($x1);
    ok(r->is->complex($x2));
    is($x2->values->[0]->{re}, 1);
    is($x2->values->[0]->{im}, 0);
    is($x2->values->[1]->{re}, 0);
    is($x2->values->[1]->{im}, 0);
  }
}

# array decide type
{
  # array decide type - complex
  {
    my $x1 = array(c_(r->complex(1, 2), r->complex(3, 4)));
    is($x1->values->[0]->{re}, 1);
    is($x1->values->[0]->{im}, 2);
    is($x1->values->[1]->{re}, 3);
    is($x1->values->[1]->{im}, 4);
    ok(r->is->complex($x1));
  }

  # array decide type - numerci
  {
    my $x1 = array(c_(1, 2));
    is_deeply($x1->values, [1, 2]);
    ok(r->is->numeric($x1));
  }
  
  # array decide type - logical
  {
    my $x1 = array(c_(TRUE, FALSE));
    is_deeply($x1->values, [1, 0]);
    ok(r->is->logical($x1));
  }

  # array decide type - character
  {
    my $x1 = array(c_("c1", "c2"));
    is_deeply($x1->values, ["c1", "c2"]);
    ok(r->is->character($x1));
  }

  # array decide type - character, look like number
  {
    my $x1 = array(c_("1", "2"));
    is_deeply($x1->values, ["1", "2"]);
    ok(r->is->character($x1));
  }

  # array decide type - Inf
  {
    my $x1 = Inf;
    is_deeply($x1->values, ['Inf']);
    ok(r->is->numeric($x1));
  }

  # array decide type - NaN
  {
    my $x1 = NaN;
    is_deeply($x1->values, ['NaN']);
    ok(r->is->numeric($x1));
  }

  # array decide type - NA
  {
    my $x1 = array(NA);
    is_deeply($x1->values, [undef]);
    ok(r->is->logical($x1));
  }
}

# as->vector
{
  my $x = array(C_('1:24'), c_(4, 3, 2));
  is_deeply(r->as->vector($x)->values, [1 .. 24]);
  is_deeply(r->dim(r->as->vector($x))->values, []);
}

# as->matrix
{
  # as->matrix - from vector
  {
    my $x = c_(C_('1:24'));
    is_deeply(r->as->matrix($x)->values, [1 .. 24]);
    is_deeply(r->dim(r->as->matrix($x))->values, [24, 1]);
  }

  # as->matrix - from matrix
  {
    my $x = matrix(C_('1:12'), 4, 3);
    is_deeply(r->as->matrix($x)->values, [1 .. 12]);
    is_deeply(r->dim(r->as->matrix($x))->values, [4, 3]);
  }

  # as->matrix - from array
  {
    my $x = array(C_('1:24'), c_(4, 3, 2));
    is_deeply(r->as->matrix($x)->values, [1 .. 24]);
    is_deeply(r->dim(r->as->matrix($x))->values, [24, 1]);
  }
}

# as->array
{
  # as->array - from vector
  {
    my $x1 = C_('1:24');
    my $x2 = r->as->array($x1);
    is_deeply($x2->values, [1 .. 24]);
    is_deeply(r->dim($x2)->values, [24]);
  }

  # as->array - from array
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = r->as->array($x1);
    is_deeply($x2->values, [1 .. 24]);
    is_deeply(r->dim($x2)->values, [4, 3, 2]);
  }
}

