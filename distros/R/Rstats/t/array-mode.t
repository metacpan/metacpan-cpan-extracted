use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;
use Rstats::Util;

my $r = Rstats->new;

# as_character
{
  # as_character - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is_deeply($a2->values, ["Inf"]);
  }

  # as_character - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is_deeply($a2->values, ["NA"]);
  }

  # as_character - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is_deeply($a2->values, ["NaN"]);
  }
  
  # as_character - character
  {
    my $a1 = $r->array(["a"]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is($a2->values->[0], "a");
  }
  
  # as_character - complex
  {
    my $a1 = $r->array([$r->complex(1, 2)]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is($a2->values->[0], "1+2i");
  }

  # as_character - complex, 0 + 0i
  {
    my $a1 = $r->array([$r->complex(0, 0)]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is($a2->values->[0], "0+0i");
  }
  
  # as_character - numeric
  {
    my $a1 = $r->array([1.1, 0]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is($a2->values->[0], "1.1");
    is($a2->values->[1], "0");
  }
  
  # as_character - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    my $a2 = $r->as_character($a1);
    ok($a2->is_character);
    is($a2->values->[0], "TRUE");
    is($a2->values->[1], "FALSE");
  }
}

# as_logical
{
  # as_logical - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is_deeply($a2->values, [Rstats::Util::TRUE]);
  }

  # as_logical - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_logical - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }
  
  # as_logical - character, number
  {
    my $a1 = $r->array(["1.23"]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }

  # as_logical - character, pre and trailing space
  {
    my $a1 = $r->array(["  1  "]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }

  # as_logical - character
  {
    my $a1 = $r->array(["a"]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }
  
  # as_logical - complex
  {
    my $a1 = $r->array([$r->complex(1, 2)]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is($a2->values->[0], Rstats::Util::TRUE);
  }

  # as_logical - complex, 0 + 0i
  {
    my $a1 = $r->array([$r->complex(0, 0)]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is($a2->values->[0], Rstats::Util::FALSE);
  }
  
  # as_logical - numeric
  {
    my $a1 = $r->array([1.1, 0]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is($a2->values->[0], Rstats::Util::TRUE);
    is($a2->values->[1], Rstats::Util::FALSE);
  }
  
  # as_logical - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is($a2->values->[0], Rstats::Util::TRUE);
    is($a2->values->[1], Rstats::Util::FALSE);
  }
}

# as_integer
{
  # as_integer - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_integer - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_integer - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }
  
  # as_integer - character, only real number, no sign
  {
    my $a1 = $r->array(["1.23"]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }

  # as_integer - character, only real number, plus
  {
    my $a1 = $r->array(["+1"]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }
  
  # as_integer - character, only real number, minus
  {
    my $a1 = $r->array(["-1.23"]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], -1);
  }

  # as_integer - character, pre and trailing space
  {
    my $a1 = $r->array(["  1  "]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }

  # as_integer - error
  {
    my $a1 = $r->array(["a"]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }
  
  # as_integer - complex
  {
    my $a1 = $r->array([$r->complex(1, 2)]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }
  
  # as_integer - integer
  {
    my $a1 = $r->array([1.1]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }
  
  # as_integer - integer
  {
    my $a1 = $r->array([1]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
  }
  
  # as_integer - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    my $a2 = $r->as_integer($a1);
    ok($a2->is_integer);
    is($a2->values->[0], 1);
    is($a2->values->[1], 0);
  }
}

# as_numeric
{
  # as_numeric - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is_deeply($a2->values, [Rstats::Util::Inf]);
  }

  # as_numeric - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_numeric - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is_deeply($a2->values, [Rstats::Util::NaN]);
  }

  # as_numeric - character, only real number, no sign
  {
    my $a1 = $r->array(["1.23"]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1.23);
  }

  # as_numeric - character, only real number, plus
  {
    my $a1 = $r->array(["+1.23"]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1.23);
  }
  
  # as_numeric - character, only real number, minus
  {
    my $a1 = $r->array(["-1.23"]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], -1.23);
  }

  # as_numeric - character, pre and trailing space
  {
    my $a1 = $r->array(["  1  "]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1);
  }

  # as_numeric - error
  {
    my $a1 = $r->array(["a"]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }
  
  # as_numeric - complex
  {
    my $a1 = $r->array([$r->complex(1, 2)]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1);
  }
  
  # as_numeric - numeric
  {
    my $a1 = $r->array([1.1]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1.1);
  }
  
  # as_numeric - integer
  {
    my $a1 = $r->array([1]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1);
  }
  
  # as_numeric - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    my $a2 = $r->as_numeric($a1);
    ok($a2->is_numeric);
    is($a2->values->[0], 1);
    is($a2->values->[1], 0);
  }
}

# as_complex
{
  # as_complex - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, Rstats::Util::Inf);
    is($a2->values->[0]->{im}, 0);
  }

  # as_complex - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_complex - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is_deeply($a2->values, [Rstats::Util::NA]);
  }

  # as_complex - character, only real number, no sign
  {
    my $a1 = $r->array(["1.23"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1.23);
    is($a2->values->[0]->{im}, 0);
  }

  # as_complex - character, only real number, pre and trailing space
  {
    my $a1 = $r->array(["  1.23  "]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1.23);
    is($a2->values->[0]->{im}, 0);
  }
  
  # as_complex - character, only real number, plus
  {
    my $a1 = $r->array(["+1.23"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1.23);
    is($a2->values->[0]->{im}, 0);
  }
  
  # as_complex - character, only real number, minus
  {
    my $a1 = $r->array(["-1.23"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, -1.23);
    is($a2->values->[0]->{im}, 0);
  }

  # as_complex - character, only image number, no sign
  {
    my $a1 = $r->array(["1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 0);
    is($a2->values->[0]->{im}, 1.23);
  }

  # as_complex - character, only image number, plus
  {
    my $a1 = $r->array(["+1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 0);
    is($a2->values->[0]->{im}, 1.23);
  }

  # as_complex - character, only image number, minus
  {
    my $a1 = $r->array(["-1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 0);
    is($a2->values->[0]->{im}, -1.23);
  }

  # as_complex - character, real number and image number, no sign
  {
    my $a1 = $r->array(["2.5+1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 2.5);
    is($a2->values->[0]->{im}, 1.23);
  }

  # as_complex - character, real number and image number, plus
  {
    my $a1 = $r->array(["+2.5+1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 2.5);
    is($a2->values->[0]->{im}, 1.23);
  }
  
  # as_complex - character, real number and image number, minus
  {
    my $a1 = $r->array(["-2.5-1.23i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, -2.5);
    is($a2->values->[0]->{im}, -1.23);
  }

  # as_complex - character, pre and trailing space
  {
    my $a1 = $r->array(["  2.5+1.23i  "]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 2.5);
    is($a2->values->[0]->{im}, 1.23);
  }

  # as_complex - error
  {
    my $a1 = $r->array(["a"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }

  # as_complex - error
  {
    my $a1 = $r->array(["i"]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is(ref $a2->values->[0], 'Rstats::Element::NA');
  }
        
  # as_complex - complex
  {
    my $a1 = $r->array([$r->complex(1, 2)]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1);
    is($a2->values->[0]->{im}, 2);
  }
  
  # as_complex - numeric
  {
    my $a1 = $r->array([1.1]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1.1);
    is($a2->values->[0]->{im}, 0);
  }
  
  # as_complex - integer
  {
    my $a1 = $r->array([1]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1);
    is($a2->values->[0]->{im}, 0);
  }
  
  # as_complex - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    my $a2 = $r->as_complex($a1);
    ok($a2->is_complex);
    is($a2->values->[0]->{re}, 1);
    is($a2->values->[0]->{im}, 0);
    is($a2->values->[1]->{re}, 0);
    is($a2->values->[1]->{im}, 0);
  }
}

# array decide type
{
  # array decide type - complex
  {
    my $a1 = $r->array([$r->complex(1, 2), $r->complex(3, 4)]);
    is($a1->values->[0]->{re}, 1);
    is($a1->values->[0]->{im}, 2);
    is($a1->values->[1]->{re}, 3);
    is($a1->values->[1]->{im}, 4);
    ok($a1->is_complex);
  }

  # array decide type - numerci
  {
    my $a1 = $r->array([1, 2]);
    is_deeply($a1->values, [1, 2]);
    ok($a1->is_numeric);
  }
  
  # array decide type - logical
  {
    my $a1 = $r->array([Rstats::Util::TRUE, Rstats::Util::FALSE]);
    is_deeply($a1->values, [Rstats::Util::TRUE, Rstats::Util::FALSE]);
    ok($a1->is_logical);
  }

  # array decide type - character
  {
    my $a1 = $r->array(["c1", "c2"]);
    is_deeply($a1->values, ["c1", "c2"]);
    ok($a1->is_character);
  }

  # array decide type - character, look like number
  {
    my $a1 = $r->array(["1", "2"]);
    is_deeply($a1->values, ["1", "2"]);
    ok($a1->is_character);
  }

  # array decide type - Inf
  {
    my $a1 = $r->array([Rstats::Util::Inf]);
    is_deeply($a1->values, [Rstats::Util::Inf]);
    ok($a1->is_numeric);
  }

  # array decide type - NaN
  {
    my $a1 = $r->array([Rstats::Util::NaN]);
    is_deeply($a1->values, [Rstats::Util::NaN]);
    ok($a1->is_numeric);
  }

  # array decide type - NA
  {
    my $a1 = $r->array([Rstats::Util::NA]);
    is_deeply($a1->values, [Rstats::Util::NA]);
    ok($a1->is_logical);
  }
}

# array upgrade mode
{
  # array decide mode - complex
  {
    my $a1_values = [1, $r->complex(3, 4)];
    my $a1 = $r->array($a1_values);
    is($a1->values->[0]->{re}, 1);
    is($a1->values->[0]->{im}, 0);
    is($a1->values->[1]->{re}, 3);
    is($a1->values->[1]->{im}, 4);
    ok($a1->is_complex);
  }

}

# is_*
{
  # is_* - is_vector
  {
    my $array = $r->c($r->C('1:24'));
    ok($array->is_vector);
    ok($array->is_array);
  }

  # is_* - is_vector
  {
    my $array = $r->array($r->C('1:24'));
    ok(!$array->is_vector);
    ok($array->is_array);
  }
    
  # is_* - is_matrix
  {
    my $array = $r->matrix($r->C('1:12'), 4, 3);
    ok($array->is_matrix);
    ok($array->is_array);
  }

  # is_* - is_array
  {
    my $array = $r->array($r->C('1:24'), [4, 3, 2]);
    ok($array->is_array);
    ok(!$array->is_vector);
    ok(!$array->is_matrix);
  }
}

# is_* fro Rstats object
{
  # is_* - is_vector
  {
    my $array = $r->array($r->C('1:24'));
    ok(!$r->is_vector($array));
  }
  
  # is_* - is_matrix
  {
    my $array = $r->matrix($r->C('1:24'), 4, 3);
    ok($r->is_matrix($array));
  }

  # is_* - is_array
  {
    my $array = $r->array($r->C('1:12'), [4, 3, 2]);
    ok($r->is_array($array));
  }
}

# as_*
{
  # as_* - as_vector
  {
    my $array = $r->array($r->C('1:24'), [4, 3, 2]);
    is_deeply($array->as_vector->values, [1 .. 24]);
    is_deeply($array->as_vector->dim->values, []);
  }
  
  # as_* - as_matrix, from vector
  {
    my $array = $r->c($r->C('1:24'));
    is_deeply($array->as_matrix->values, [1 .. 24]);
    is_deeply($array->as_matrix->dim->values, [24, 1]);
  }

  # as_* - as_matrix, from matrix
  {
    my $array = $r->matrix($r->C('1:12'), 4, 3);
    is_deeply($array->as_matrix->values, [1 .. 12]);
    is_deeply($array->as_matrix->dim->values, [4, 3]);
  }

  # as_* - as_matrix, from array
  {
    my $array = $r->array($r->C('1:24'), [4, 3, 2]);
    is_deeply($array->as_matrix->values, [1 .. 24]);
    is_deeply($array->as_matrix->dim->values, [24, 1]);
  }
}

# as_* from Rstats object
{
  # as_* from Rstats object - as_vector
  {
    my $array = $r->array($r->C('1:24'), [4, 3, 2]);
    is_deeply($r->as_vector($array)->values, [1 .. 24]);
    is_deeply($r->as_vector($array)->dim->values, []);
  }
  
  # as_* from Rstats object - as_matrix, from vector
  {
    my $array = $r->c($r->C('1:24'));
    is_deeply($r->as_matrix($array)->values, [1 .. 24]);
    is_deeply($r->as_matrix($array)->dim->values, [24, 1]);
  }

  # as_* from Rstats object - as_matrix, from matrix
  {
    my $array = $r->matrix($r->C('1:12'), 4, 3);
    is_deeply($r->as_matrix($array)->values, [1 .. 12]);
    is_deeply($r->as_matrix($array)->dim->values, [4, 3]);
  }

  # as_* from Rstats object - as_matrix, from array
  {
    my $array = $r->array($r->C('1:24'), [4, 3, 2]);
    is_deeply($r->as_matrix($array)->values, [1 .. 24]);
    is_deeply($r->as_matrix($array)->dim->values, [24, 1]);
  }
}
