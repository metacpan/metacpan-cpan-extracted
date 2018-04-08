use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;
use Rstats::Util;
use Math::Complex ();
use Math::Trig ();

# NULL
{
  my $x1 = r->NULL;
  is_deeply($x1->values, []);
  is("$x1", 'NULL');
  $x1->at(3);
  $x1->set(5);
  is_deeply($x1->values, [undef, undef, 5]);
}


# c_
{
  # c_()
  {
    my $x1 = c_();
    my $x_tmp = r->is->null($x1);
    ok($x_tmp);
  }
  
  # c_(NULL)
  {
    my $x1 = c_(NULL);
    ok(r->is->null($x1));
  }
  
  # c_(1, 2, 3, NULL)
  {
    my $x1 = c_(1, 2, 3);
    ok(r->is->double($x1));
    is_deeply($x1->values, [1, 2, 3]);
  }
  
  # c_(T_, F_);
  {
    my $x1 = c_(T_, F_);
    ok(r->is->logical($x1));
    is_deeply($x1->values, [1, 0]);
  }

  # c_(T_, r->as->integer(2));
  {
    my $x1 = c_(T_, r->as->integer(2));
    ok(r->is->integer($x1));
    is_deeply($x1->values, [1, 2]);
  }

  # c_(1, r->as->integer(2));
  {
    my $x1 = c_(1, r->as->integer(2));
    ok(r->is->double($x1));
    is_deeply($x1->values, [1, 2]);
  }
    
  # c_(1, 3 + 4*i_);
  {
    my $x1 =  c_(1, r->complex(3, 4));
    ok(r->is->complex($x1));
    is($x1->values->[0]->{re}, 1);
    is($x1->values->[0]->{im}, 0);
    is($x1->values->[1]->{re}, 3);
    is($x1->values->[1]->{im}, 4);
  }

  # c_("a", "b")
  {
    my $x1 = c_("a", "b");
    ok(r->is->character($x1));
    is_deeply($x1->values, ["a", "b"]);
  }

  # c_([1, 2, 3])
  {
    my $x1 = c_([1, 2, 3]);
    ok(r->is->double($x1));
    is_deeply($x1->values, [1, 2, 3]);
  }
  
  # c_(c_(1, 2, 3))
  {
    my $x1 = c_(c_(1, 2, 3));
    ok(r->is->double($x1));
    is_deeply($x1->values, [1, 2, 3]);
  }
  
  # c_(1, 2, c_(3, 4, 5))
  {
    my $x1 = c_(1, 2, c_(3, 4, 5));
    is_deeply($x1->values, [1, 2, 3, 4, 5]);
  }

  # c_ - append (array)
  {
    my $x1 = c_(c_(1, 2), 3, 4);
    is_deeply($x1->values, [1, 2, 3, 4]);
  }
  
  # c_ - append to original vector
  {
    my $x1 = c_(1, 2, 3);
    $x1->at(r->length($x1)->value + 1)->set(6);
    is_deeply($x1->values, [1, 2, 3, 6]);
  }
}

# class
{
  # class - matrix
  {
    my $x1 = matrix(2, 2);
    is_deeply($x1->class->values, ['matrix']);
  }

  # class - data frame
  {
    my $x1 = data_frame(sex => c_(1, 2));
    is_deeply($x1->class->values, ['data.frame']);
  }

  # class - vector, numeric
  {
    my $x1 = c_(1, 2);
    is_deeply($x1->class->values, ['numeric']);
  }
  
  # class - array
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    is_deeply($x1->class->values, ['array']);
  }
  
  # class - factor
  {
    my $x1 = factor(c_(1, 2, 3));
    is_deeply($x1->class->values, ['factor']);
  }
  
  # class - factor, ordered
  {
    my $x1 = ordered(c_(1, 2, 3));
    is_deeply($x1->class->values, ['factor', 'ordered']);
  }
  
  # class - list
  {
    my $x1 = list(1, 2);
    is_deeply($x1->class->values, ['list']);
  }
}

# C_
{
  # C_('1:3')
  {
    my $x1 = C_('1:3');
    is_deeply($x1->values, [1, 2, 3]);
  }
  
  # C_('0.5*1:3')
  {
    my $x1 = C_('0.5*1:3');
    is_deeply($x1->values, [1, 1.5, 2, 2.5, 3]);
  }
}

# tail
{
  {
    my $x1 = c_(1, 2, 3, 4, 5, 6, 7);
    my $tail = r->tail($x1);
    is_deeply($tail->values, [2, 3, 4, 5, 6, 7]);
  }
  
  # tail - values is low than 6
  {
    my $x1 = c_(1, 2, 3);
    my $tail = r->tail($x1);
    is_deeply($tail->values, [1, 2, 3]);
  }
  
  # tail - n option
  {
    my $x1 = c_(1, 2, 3, 4);
    my $tail = r->tail($x1, {n => 3});
    is_deeply($tail->values, [2, 3, 4]);
  }
}

# matrix
{
  {
    my $mat = matrix(0, 2, 5);
    is_deeply($mat->values, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    is_deeply(r->dim($mat)->values, [2, 5]);
    ok(r->is->matrix($mat));
  }
  
  # matrix - repeat values
  {
    my $mat = matrix(c_(1,2), 2, 5);
    is_deeply($mat->values, [1, 2, 1, 2, 1, 2, 1, 2, 1, 2]);
    is_deeply(r->dim($mat)->values, [2, 5]);
    ok(r->is->matrix($mat));
  }
}

# rnorm
{
  my $x1 = r->rnorm(100);
  is(r->length($x1)->value, 100);
}

# sequence
{
  my $x1 = c_(1, 2, 3);
  my $x2 = r->sequence($x1);
  is_deeply($x2->values, [1, 1, 2, 1, 2, 3])
}
  
# sample
{
  {
    my $x1 = C_('1:100');
    my $x2 = r->sample($x1, 50);
    is(r->length($x2)->value, 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $x2_value (@{$x2->values}) {
      $duplicate_h->{$x2_value}++;
      $duplicate = 1 if $duplicate_h->{$x2_value} > 2;
      unless (grep { $_ eq $x2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$duplicate);
    ok(!$invalid_value);
  }
  
  # sample - replace => 0
  {
    my $x1 = C_('1:100');
    my $x2 = r->sample($x1, 50, {replace => 0});
    is(r->length($x2)->value, 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $x2_value (@{$x2->values}) {
      $duplicate_h->{$x2_value}++;
      $duplicate = 1 if $duplicate_h->{$x2_value} > 2;
      unless (grep { $_ eq $x2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$duplicate);
    ok(!$invalid_value);
  }

  # sample - replace => 0
  {
    my $x1 = C_('1:100');
    my $x2 = r->sample($x1, 50, {replace => 1});
    is(r->length($x2)->value, 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $x2_value (@{$x2->values}) {
      unless (grep { $_ eq $x2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$invalid_value);
  }
  
  # sample - replace => 0, (strict check)
  {
    my $x1 = c_(1);
    my $x2 = r->sample($x1, 5, {replace => 1});
    is(r->length($x2)->value, 5);
    is_deeply($x2->values, [1, 1, 1, 1, 1]);
  }
}

# which
{
  my $x1 = c_('a', 'b', 'a');
  my $x2 = r->which($x1, sub { $_ eq 'a' });
  is_deeply($x2->values, [1, 3]);
}

# elseif
{
  my $x1 = c_(1, 0, 1);
  my $x2 = r->ifelse($x1, 'a', 'b');
  is_deeply($x2->values, ['a', 'b', 'a']);
}

# head
{
  {
    my $x1 = c_(1, 2, 3, 4, 5, 6, 7);
    my $head = r->head($x1);
    is_deeply($head->values, [1, 2, 3, 4, 5, 6]);
  }
  
  # head - values is low than 6
  {
    my $x1 = c_(1, 2, 3);
    my $head = r->head($x1);
    is_deeply($head->values, [1, 2, 3]);
  }
  
  # head - n option
  {
    my $x1 = c_(1, 2, 3, 4);
    my $head = r->head($x1, {n => 3});
    is_deeply($head->values, [1, 2, 3]);
  }
}

# length
{
  my $x = array(c_(1, 2, 3));
  is(r->length($x)->value, 3);
}

# array
{
  {
    my $x = array(25);
    is_deeply($x->values, [25]);
  }
  {
    my $x = array(c_(1, 2, 3));
    is_deeply(r->dim($x)->values, [3]);
  }
}

# Array get and set
{
  my $x = array(c_(1, 2, 3));
  is_deeply($x->get(1)->values, [1]);
  is_deeply($x->get(3)->values, [3]);
  $x->at(1)->set(5);;
  is_deeply($x->get(1)->values, [5]);
}

# rep function
{
  # req($v, {times => $times});
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = r->rep($x1, {times => 3});
    is_deeply($x2->values, [1, 2, 3, 1, 2, 3, 1, 2, 3]);
  }
}

# seq function
{
  # seq($from, $to),  n > m
  {
    my $x1 = r->seq(1, 3);
    is_deeply($x1->values, [1, 2, 3]);
  }

  # seq({from => $from, to => $to}),  n > m
  {
    my $x1 = r->seq({from => 1, to => 3});
    is_deeply($x1->values, [1, 2, 3]);
  }
  
  # seq($from, $to),  n < m
  {
    my $x1 = r->seq(3, 1);
    is_deeply($x1->values, [3, 2, 1]);
  }
  
  # seq($from, $to), n = m
  {
    my $x1 = r->seq(2, 2);
    is_deeply($x1->values, [2]);
  }
  
  # seq($from, $to, {by => p}) n > m
  {
    my $x1 = r->seq(1, 3, {by => 0.5});
    is_deeply($x1->values, [1, 1.5, 2.0, 2.5, 3.0]);
  }

  # seq($from, $to, {by => p}) n > m
  {
    my $x1 = r->seq(3, 1, {by => -0.5});
    is_deeply($x1->values, [3.0, 2.5, 2.0, 1.5, 1.0]);
  }
  
  # seq($from, {by => p, length => l})
  {
    my $x1 = r->seq(1, 3, {length => 5});
    is_deeply($x1->values, [1, 1.5, 2.0, 2.5, 3.0]);
  }
  
  # seq(along => $v);
  my $x1 = c_(3, 4, 5);
  my $x2 = r->seq({along => $x1});
  is_deeply($x2->values, [1, 2, 3]);
}

# sub
{
  # sub - case not ignore
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3 = c_("ad1ad1", NA, "ad2ad2");
    my $x4 = r->sub($x1, $x2, $x3);
    is_deeply($x4->values, ["bd1ad1", undef, "bd2ad2"]);
  }

  # sub - case ignore
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3 = c_("Ad1ad1", NA, "ad2ad2");
    my $x4 = r->sub($x1, $x2, $x3, {'ignore.case' => TRUE});
    is_deeply($x4->values, ["bd1ad1", undef, "bd2ad2"]);
  }
}

# NaN
{
  # NaN - type
  {
    my $x_nan = NaN;
    ok(r->is->double($x_nan));
  }
}

# Arg
{
  # Arg - double
  {
    my $x1 = c_(1.2);
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [0]);
  }

  # Arg - integer
  {
    my $x1 = r->as->integer(c_(-3));
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [r->pi->value]);
  }

  # Arg - logical
  {
    my $x1 = c_(T_);
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [0]);
  }

  # Arg - double,NaN
  {
    my $x1 = c_(NaN);
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, ['NaN']);
  }

=pod TODO
  # Arg - complex, non 0 values
  {
    my $x1 = c_(1 + 1*i_, 2 + 2*i_);
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [r->pi->value / 4, r->pi->value / 4]);
  }
=cut
  
  # Arg - complex, 0 values
  {
    my $x1 = c_(0 + 0*i_);
    my $x2 = r->Arg($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [0]);
  }

  # Arg - dim
  {
    my $x1 = array(c_(T_, T_));
    my $x2 = r->Arg($x1);
    is_deeply($x2->dim->values, [2]);
  }
}

# Method
{
  # sort - contain NA or NaN
  {
    my $x1 = c_(2, 1, 5, NA, NaN);
    my $x1_sorted = r->sort($x1);
    is_deeply($x1_sorted->values, [1, 2, 5]);
  }
    
  # c_ - append (vector)
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = c_($x1, 4, 5);
    is_deeply($x2->values, [1, 2, 3, 4, 5]);
  }

  # var
  {
    my $x1 = c_(2, 3, 4, 7, 9);
    my $var = r->var($x1);
    is($var->value, 8.5);
  }
  
  # numeric
  {
    my $x1 = r->numeric(3);
    is_deeply($x1->values, [0, 0, 0]);
  }

  # length
  {
    my $x1 = c_(1, 2, 4);
    my $length = r->length($x1);
    is($length->value, 3);
  }
  
  # mean
  {
    my $x1 = c_(1, 2, 3);
    my $mean = r->mean($x1);
    is($mean->value, 2);
  }

  # sort
  {
    # sort - acending
    {
      my $x1 = c_(2, 1, 5);
      my $x1_sorted = r->sort($x1);
      is_deeply($x1_sorted->values, [1, 2, 5]);
    }
    
    # sort - decreasing
    {
      my $x1 = c_(2, 1, 5);
      my $x1_sorted = r->sort($x1, {decreasing => 1});
      is_deeply($x1_sorted->values, [5, 2, 1]);
    }
  }
}

# min
{
  # min - contain NA
  {
    my $x_tmp = c_(1, 2, NaN, NA);
    my $x1 = r->min(c_(1, 2, NaN, NA));
    is_deeply($x1->values, [undef]);
  }
  
  # min - no argument
  {
    my $x1 = r->min(NULL);
    is_deeply($x1->values, ['Inf']);
  }
  # min
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = r->min($x1);
    is_deeply($x2->values, [1]);
  }

  # min - multiple arrays
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = c_(4, 5, 6);
    my $x3 = r->min($x1, $x2);
    is_deeply($x3->values, [1]);
  }
  
  # min - contain NaN
  {
    my $x1 = r->min(c_(1, 2, NaN));
    is_deeply($x1->values, ['NaN']);
  }
}

# expm1
{
  # expm1 - double,array
  {
    my $x0 = c_(1, 2);
    my $x1 = array($x0);
    my $x2 = r->expm1($x1);
    is(sprintf("%.6f", $x2->values->[0]), '1.718282');
    is(sprintf("%.6f", $x2->values->[1]), '6.389056');
    is_deeply(r->dim($x2)->values, [2]);
    ok(r->is->double($x2));
  }

  # expm1 - complex
  {
    my $x1 = c_(1 + 2*i_);
    eval {
      my $x2 = r->expm1($x1);
    };
    like($@, qr/unimplemented/);
  }
  
  # expm1 - double,less than 1e-5
  {
    my $x1 = array(c_(0.0000001234));
    my $x2 = r->expm1($x1);
    my $x2_value_str = sprintf("%.13e", $x2->value);
    $x2_value_str =~ s/e-0+/e-/;
    is($x2_value_str, '1.2340000761378e-7');
    ok(r->is->double($x2));
  }

  # expm1 - integer
  {
    my $x1 = r->as->integer(array(c_(2)));
    my $x2 = r->expm1($x1);
    is(sprintf("%.6f", $x2->value), '6.389056');
    ok(r->is->double($x2));
  }
    
  # expm1 - Inf
  {
    my $x1 = c_(Inf);
    my $x2 = r->expm1($x1);
    is($x2->value, 'Inf');
  }
  
  # expm1 - -Inf
  {
    my $x1 = c_(-Inf);
    my $x2 = r->expm1($x1);
    is($x2->value, -1);
  }

  # expm1 - NA
  {
    my $x1 = c_(NA);
    my $x2 = r->expm1($x1);
    ok(!defined $x2->value);
  }

  # expm1 - NaN
  {
    my $x1 = c_(NaN);
    my $x2 = r->expm1($x1);
    is($x2->value, 'NaN');
  }
}

# prod
{
  # prod - NULL
  {
    my $x1 = NULL;
    my $x2 = r->prod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1]);
  }
  
  # prod - complex
  {
    my $x1 = c_(1+1*i_, 2+3*i_);
    my $x2 = r->prod($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, [{re => -1, im => 5}]);
  }

  # prod - double
  {
    my $x1 = c_(2, 3, 4);
    my $x2 = r->prod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [24]);
  }

  # prod - integer
  {
    my $x1 = r->as->integer(c_(2, 3, 4));
    my $x2 = r->prod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [24]);
  }

  # prod - logical
  {
    my $x1 = c_(T_, T_, T_);
    my $x2 = r->prod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1]);
  }
}

# sum
{
  # sum - NULL
  {
    my $x1 = NULL;
    my $x2 = r->sum($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [0]);
  }

  # sum - complex
  {
    my $x1 = c_(1+1*i_, 2+2*i_, 3+3*i_);
    my $x2 = r->sum($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, [{re => 6, im => 6}]);
  }
  
  # sum - double
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = r->sum($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [6]);
  }
  
  # sum - integer
  {
    my $x1 = r->as->integer(c_(1, 2, 3));
    my $x2 = r->sum($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [6]);
  }
  
  # sum - logical
  {
    my $x1 = c_(T_, T_, F_);
    my $x2 = r->sum($x1);
    ok(r->is->integer($x2));
    is_deeply($x2->values, [2]);
  }
}

# ve - minus
{
  my $x1 = -C_('1:4');
  is_deeply($x1->values, [-1, -2, -3, -4]);
}

# str
{

  # str - array, one element
  {
    my $x1 = array(1, 1);
    is(r->str($x1), 'num [1(1d)] 1');
  }
  
  # str - array, one dimention
  {
    my $x1 = array(C_('1:4'), c_(4));
    is(r->str($x1), 'num [1:4(1d)] 1 2 3 4');
  }
  
  # str - array
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    is(r->str($x1), 'num [1:4, 1:3] 1 2 3 4 5 6 7 8 9 10 ...');
  }
  
  # str - vector, more than 10 element
  {
    my $x1 = C_('1:11');
    is(r->str($x1), 'num [1:11] 1 2 3 4 5 6 7 8 9 10 ...');
  }

  # str - vector, 10 element
  {
    my $x1 = C_('1:10');
    is(r->str($x1), 'num [1:10] 1 2 3 4 5 6 7 8 9 10');
  }

  # str - vector, logical
  {
    my $x1 = c_(T_, F_);
    is(r->str($x1), 'logi [1:2] TRUE FALSE');
  }

  # str - vector, integer
  {
    my $x1 = r->as->integer(c_(1, 2));
    is(r->str($x1), 'int [1:2] 1 2');
  }

  # str - vector, complex
  {
    my $x1 = c_(1 + 1*i_, 1 + 2*i_);
    is(r->str($x1), 'cplx [1:2] 1+1i 1+2i');
  }

  # str - vector, character
  {
    my $x1 = c_("a", "b", "c");
    is(r->str($x1), 'chr [1:3] "a" "b" "c"');
  }

  # str - vector, one element
  {
    my $x1 = c_(1);
    is(r->str($x1), 'num 1');
  }

  # str - vector, double
  {
    my $x1 = c_(1, 2, 3);
    is(r->str($x1), 'num [1:3] 1 2 3');
  }
}

# exp
{
  # exp - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = r->exp($x1);
    is(sprintf("%.6f", $x2->value->{re}), '-1.131204');
    is(sprintf("%.6f", $x2->value->{im}), '2.471727');
    ok(r->is->complex($x2));
  }
  
  # exp - double,array
  {
    my $x1 = array(c_(1, 2));
    my $x2 = r->exp($x1);
    is(sprintf("%.6f", $x2->values->[0]), '2.718282');
    is(sprintf("%.6f", $x2->values->[1]), '7.389056');
    is_deeply(r->dim($x2)->values, [2]);
    ok(r->is->double($x2));
  }

  # exp - Inf
  {
    my $x1 = c_(Inf);
    my $x2 = r->exp($x1);
    is($x2->value, 'Inf');
  }
  
  # exp - -Inf
  {
    my $x1 = c_(-Inf);
    my $x2 = r->exp($x1);
    is($x2->value, 0);
  }

  # exp - NA
  {
    my $x1 = c_(NA);
    my $x2 = r->exp($x1);
    ok(!defined $x2->value);
  }  

  # exp - NaN
  {
    my $x1 = c_(NaN);
    my $x2 = r->exp($x1);
    is($x2->value, 'NaN');
  }
}

# log10
{
  # log10 - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = r->log10($x1);
    my $exp = Math::Complex->make(1, 2)->log / Math::Complex->make(10, 0)->log;
    my $exp_re = Math::Complex::Re($exp);
    my $exp_im = Math::Complex::Im($exp);
    
    is($x2->value->{re}, $exp_re);
    is($x2->value->{im}, $exp_im);
    ok(r->is->complex($x2));
  }
  
  # log10 - double,array
  {
    my $x1 = array(c_(10));
    my $x2 = r->log10($x1);
    is($x2->value, 1);
    is_deeply(r->dim($x2)->values, [1]);
    ok(r->is->double($x2));
  }

  # log10 - integer
  {
    my $x1 = array(r->c_integer(10));
    my $x2 = r->log10($x1);
    is($x2->value, 1);
    is_deeply(r->dim($x2)->values, [1]);
    ok(r->is->double($x2));
  }

  # log10 - logical
  {
    my $x1 = array(r->c_logical(10));
    my $x2 = r->log10($x1);
    is($x2->value, 1);
    is_deeply(r->dim($x2)->values, [1]);
    ok(r->is->double($x2));
  }
}

# log2
{
  # log2 - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = r->log2($x1);
    my $exp = Math::Complex->make(1, 2)->log;
    my $exp_re = Math::Complex::Re($exp);
    my $exp_im = Math::Complex::Im($exp);
    
    is($x2->value->{re}, $exp_re / log(2));
    is($x2->value->{im}, $exp_im / log(2));
    ok(r->is->complex($x2));
  }
  
  # log2 - double,array
  {
    my $x1 = array(c_(2));
    my $x2 = r->log2($x1);
    is($x2->values->[0], 1);
    is_deeply(r->dim($x2)->values, [1]);
    ok(r->is->double($x2));
  }
}

# logb
{
  # logb - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = r->logb($x1);
    my $exp = Math::Complex->make(1, 2)->log;
    my $exp_re = Math::Complex::Re($exp);
    my $exp_im = Math::Complex::Im($exp);
    
    is($x2->value->{re}, $exp_re);
    is($x2->value->{im}, $exp_im);
    ok(r->is->complex($x2));
  }
  
  # logb - double,array
  {
    my $x1 = array(c_(1, 10, -1, 0));
    my $x2 = r->logb($x1);
    is($x2->values->[0], 0);
    is(sprintf("%.5f", $x2->values->[1]), '2.30259');
    is($x2->values->[2], 'NaN');
    ok($x2->values->[3], '-Inf');
    is_deeply(r->dim($x2)->values, [4]);
    ok(r->is->double($x2));
  }
}

# log
{
  # log - complex
  {
    my $x1 = c_(1 + 2*i_);
    my $x2 = r->log($x1);
    my $exp = Math::Complex->make(1, 2)->log;
    my $exp_re = Math::Complex::Re($exp);
    my $exp_im = Math::Complex::Im($exp);
    
    is($x2->value->{re}, $exp_re);
    is($x2->value->{im}, $exp_im);
    ok(r->is->complex($x2));
  }
  
  # log - double,array
  {
    my $x1 = array(c_(1, 10, -1, 0));
    my $x2 = r->log($x1);
    is($x2->values->[0], 0);
    is(sprintf("%.5f", $x2->values->[1]), '2.30259');
    ok($x2->values->[2], 'NaN');
    ok($x2->values->[3], '-Inf');
    is_deeply(r->dim($x2)->values, [4]);
    ok(r->is->double($x2));
  }

  # log - Inf
  {
    my $x1 = c_(Inf);
    my $x2 = r->log($x1);
    ok(r->is->infinite($x2)->values, [1]);
  }
  
  # log - Inf()
  {
    my $x1 = c_(-Inf);
    my $x2 = r->log($x1);
    is($x2->value, 'NaN');
  }

  # log - NA
  {
    my $x1 = c_(NA);
    my $x2 = r->log($x1);
    ok(!defined $x2->value);
  }  

  # log - NaN
  {
    my $x1 = c_(NaN);
    my $x2 = r->log($x1);
    is($x2->value, 'NaN');
  }
}

# gsub
{
  # gsub - case not ignore
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3 = c_("ad1ad1", NA, "ad2ad2");
    my $x4 = r->gsub($x1, $x2, $x3);
    is_deeply($x4->values, ["bd1bd1", undef, "bd2bd2"]);
  }

  # sub - case ignore
  {
    my $x1 = c_("a");
    my $x2 = c_("b");
    my $x3 = c_("Ad1Ad1", NA, "Ad2Ad2");
    my $x4 = r->gsub($x1, $x2, $x3, {'ignore.case' => TRUE});
    is_deeply($x4->values, ["bd1bd1", undef, "bd2bd2"]);
  }
}

# grep
{
  # grep - case not ignore
  {
    my $x1 = c_("abc");
    my $x2 = c_("abc", NA, "ABC");
    my $x3 = r->grep($x1, $x2);
    is_deeply($x3->values, [1]);
  }

  # grep - case ignore
  {
    my $x1 = c_("abc");
    my $x2 = c_("abc", NA, "ABC");
    my $x3 = r->grep($x1, $x2, {'ignore.case' => TRUE});
    is_deeply($x3->values, [1, 3]);
  }
}

# chartr
{
  my $x1 = c_("a-z");
  my $x2 = c_("A-Z");
  my $x3 = c_("abc", "def", NA);
  my $x4 = r->chartr($x1, $x2, $x3);
  is_deeply($x4->values, ["ABC", "DEF", undef]);
}

# charmatch
{
  # charmatch - empty string
  {
    my $x1 = r->charmatch("", "");
    is_deeply($x1->value, 1);
  }
  
  # charmatch - multiple match
  {
    my $x1 = r->charmatch("m",   c_("mean", "median", "mode"));
    is_deeply($x1->value, 0);
  }
  
  # charmatch - multiple match
  {
    my $x1 = r->charmatch("m",   c_("mean", "median", "mode"));
    is_deeply($x1->value, 0);
  }

  # charmatch - one match
  {
    my $x1 = r->charmatch("med",   c_("mean", "median", "mode"));
    is_deeply($x1->value, 2);
  }
    
  # charmatch - one match, multiple elements
  {
    my $x1 = r->charmatch(c_("med", "mod"),   c_("mean", "median", "mode"));
    is_deeply($x1->values, [2, 3]);
  }
}

# pi
{
  my $x1 = pi;
  is(sprintf('%.4f', $x1->value), 3.1416);
}

# complex
{
  # complex
  {
    my $x1 = r->complex(1, 2);
    is($x1->value->{re}, 1);
    is($x1->value->{im}, 2);
  }
  
  # complex - array
  {
    my $x1 = r->complex(c_(1, 2), c_(3, 4));
    is_deeply($x1->values, [{re => 1, im => 3}, {re => 2, im => 4}]);
  }

  # complex - array, some elements lack
  {
    my $x1 = r->complex(c_(1, 2), c_(3, 4, 5));
    is_deeply($x1->values, [{re => 1, im => 3}, {re => 2, im => 4}, {re => 0, im => 5}]);
  }

  # complex - re and im option
  {
    my $x1 = r->complex({re => c_(1, 2), im => c_(3, 4)});
    is_deeply($x1->values, [{re => 1, im => 3}, {re => 2, im => 4}]);
  }
  
  # complex - mod and arg option
  {
    my $x1 = r->complex({mod => 2, arg => pi});
    is($x1->value->{re}, -2);
    cmp_ok(abs($x1->value->{im}), '<', 1e-15);
  }

  # complex - mod and arg option, omit arg
  {
    my $x1 = r->complex({mod => 2});
    is($x1->value->{re}, 2);
    is(sprintf("%.5f", $x1->value->{im}), '0.00000');
  }

  # complex - mod and arg option, omit mod
  {
    my $x1 = r->complex({arg => pi});
    is($x1->value->{re}, -1);
    cmp_ok(abs($x1->value->{im}), '<', 1e-15);
  }
}

# append
{
  # append - after option
  {
    my $x1 = c_(1, 2, 3, 4, 5);
    my $x2 = r->append($x1, 1, {after => 3});
    is_deeply($x2->values, [1, 2, 3, 1, 4, 5]);
  }

  # append - no after option
  {
    my $x1 = c_(1, 2, 3, 4, 5);
    my $x2 = r->append($x1, 1);
    is_deeply($x2->values, [1, 2, 3, 4, 5, 1]);
  }

  # append - vector
  {
    my $x1 = c_(1, 2, 3, 4, 5);
    my $x2 = r->append($x1, c_(6, 7));
    is_deeply($x2->values, [1, 2, 3, 4, 5, 6, 7]);
  }
}

# replace
{
  {
    my $x1 = C_('1:10');
    my $x2 = c_(2, 5, 10);
    my $x3 = c_(12, 15, 20);
    my $x4 = r->replace($x1, $x2, $x3);
    is_deeply($x4->values, [1, 12, 3, 4, 15, 6, 7, 8, 9, 20]);
  }
  
  # replace - single value
  {
    my $x1 = C_('1:10');
    my $x2 = c_(2, 5, 10);
    my $x4 = r->replace($x1, $x2, 11);
    is_deeply($x4->values, [1, 11, 3, 4, 11, 6, 7, 8, 9, 11]);
  }
  
  # replace - few values
  {
    my $x1 = C_('1:10');
    my $x2 = c_(2, 5, 10);
    my $x4 = r->replace($x1, $x2, c_(12, 15));
    is_deeply($x4->values, [1, 12, 3, 4, 15, 6, 7, 8, 9, 12]);
  }
}

# is->element
{
  # is->element - numeric
  {
    my $x1 = c_(1, 2, 3, 4);
    my $x2 = c_(1, 2, 3);
    my $x3 = r->is->element($x1, $x2);
    is_deeply($x3->values, [1, 1, 1, 0]);
  }
  
  # is->element - complex
  {
    my $x1 = c_(1*i_, 2*i_, 3*i_, 4*i_);
    my $x2 = c_(1*i_, 2*i_, 3*i_);
    my $x3 = r->is->element($x1, $x2);
    is_deeply($x3->values, [1, 1, 1, 0])
  }
}

# setequal
{
  # setequal - equal
  {
    my $x1 = c_(2, 3, 1);
    my $x2 = c_(3, 2, 1);
    my $x3 = r->setequal($x1, $x2);
    is_deeply($x3->value, 1);
  }

  # setequal - not equal
  {
    my $x1 = c_(2, 3, 1);
    my $x2 = c_(2, 3, 4);
    my $x3 = r->setequal($x1, $x2);
    is_deeply($x3->value, 0);
  }
    
  # setequal - not equal, element count is diffrent
  {
    my $x1 = c_(2, 3, 1);
    my $x2 = c_(2, 3, 1, 5);
    my $x3 = r->setequal($x1, $x2);
    is_deeply($x3->value, 0);
  }
}

# setdiff
{
  my $x1 = c_(1, 2, 3, 4);
  my $x2 = c_(3, 4);
  my $x3 = r->setdiff($x1, $x2);
  is_deeply($x3->values, [1, 2]);
}

# intersect
{
  my $x1 = c_(1, 2, 3, 4);
  my $x2 = c_(3, 4, 5, 6);
  my $x3 = r->intersect($x1, $x2);
  is_deeply($x3->values, [3, 4]);
}

# union
{
  my $x1 = c_(1, 2, 3, 4);
  my $x2 = c_(3, 4, 5, 6);
  my $x3 = r->union($x1, $x2);
  is_deeply($x3->values, [1, 2, 3, 4, 5, 6]);
}

# cummin
{
  my $x1 = c_(7, 3, 5, 1);
  my $x2 = r->cummin($x1);
  is_deeply($x2->values, [7, 3, 3, 1]);
}

# cummax
{
  my $x1 = c_(1, 5, 3, 7);
  my $x2 = r->cummax($x1);
  is_deeply($x2->values, [1, 5, 5, 7]);
}

# cumprod
{
  # cumprod - NULL
  {
    my $x1 = NULL;
    my $x2 = r->cumprod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, []);
  }

  # cumprod - integer
  {
    my $x1 = r->c_integer(2, 3, 4);
    my $x2 = r->cumprod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [2, 6, 24]);
  }

  # cumprod - logical
  {
    my $x1 = c_(T_, T_, F_);
    my $x2 = r->cumprod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1, 1, 0]);
  }
  
  # cumprod - double
  {
    my $x1 = c_(2, 3, 4);
    my $x2 = r->cumprod($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [2, 6, 24]);
  }
  
  # cumprod - complex
  {
    my $x1 = c_(2*i_, 3*i_, 4*i_);
    my $x2 = r->cumprod($x1);
    ok(r->is->complex($x2));
    cmp_ok($x2->values->[0]->{re}, '==', 0);
    cmp_ok($x2->values->[0]->{im}, '==', 2);
    cmp_ok($x2->values->[1]->{re}, '==', -6);
    cmp_ok($x2->values->[1]->{im}, '==', 0);
    cmp_ok($x2->values->[2]->{re}, '==', 0);
    cmp_ok($x2->values->[2]->{im}, '==', -24);
  }
}

# cumsum
{
  # cumprod - NULL
  {
    my $x1 = NULL;
    my $x2 = r->cumsum($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, []);
  }

  # cumsum - logical
  {
    my $x1 = r->c_logical(1, 0, 1);
    my $x2 = r->cumsum($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1, 1, 2]);
  }

  # cumsum - integer
  {
    my $x1 = r->c_integer(1, 2, 3);
    my $x2 = r->cumsum($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1, 3, 6]);
  }

  # cumsum - double
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = r->cumsum($x1);
    ok(r->is->double($x2));
    is_deeply($x2->values, [1, 3, 6]);
  }
  
  # cumsum - complex
  {
    my $x1 = c_(1*i_, 2*i_, 3*i_);
    my $x2 = r->cumsum($x1);
    ok(r->is->complex($x2));
    is_deeply($x2->values, [{re => 0, im => 1}, {re => 0, im => 3}, {re => 0, im => 6}]);
  }
}

# rank
{
  my $x1 = c_(1, 5, 5, 5, 3, 3, 7);
  my $x2 = r->rank($x1);
  is_deeply($x2->values, [1, 5, 5, 5, 2.5, 2.5, 7]);
}

# order
{
  # order - 2 condition,decreasing TRUE
  {
    my $x1 = c_(4, 3, 3, 3, 1, 5);
    my $x2 = c_(1, 2, 3, 1, 1, 1);
    my $x3 = r->order($x1, $x2, {decreasing => TRUE});
    is_deeply($x3->values, [6, 1, 3, 2, 4, 5]);
  }
  
  # order - 2 condition,decreasing FALSE
  {
    my $x1 = c_(4, 3, 3, 3, 1, 5);
    my $x2 = c_(1, 2, 3, 1, 1, 1);
    my $x3 = r->order($x1, $x2);
    is_deeply($x3->values, [5, 4, 2, 3, 1, 6]);
  }
  
  # order - decreasing FALSE
  {
    my $x1 = c_(2, 4, 3, 1);
    my $x2 = r->order($x1, {decreasing => FALSE});
    is_deeply($x2->values, [4, 1, 3, 2]);
  }
  
  # order - decreasing TRUE
  {
    my $x1 = c_(2, 4, 3, 1);
    my $x2 = r->order($x1, {decreasing => TRUE});
    is_deeply($x2->values, [2, 3, 1, 4]);
  }

  # order - decreasing FALSE
  {
    my $x1 = c_(2, 4, 3, 1);
    my $x2 = r->order($x1);
    is_deeply($x2->values, [4, 1, 3, 2]);
  }
}

# diff
{
  # diff - numeric
  {
    my $x1 = c_(1, 5, 10, NA);
    my $x2 = r->diff($x1);
    is_deeply($x2->values, [4, 5, undef]);
  }
  
  # diff - complex
  {
    my $x1 = c_(1 + 2*i_, 5 + 3*i_, NA);
    my $x2 = r->diff($x1);
    is_deeply($x2->values, [{re => 4, im => 1}, undef]);
  }
}

# paste
{
  # paste($str, $vector);
  {
    my $x1 = r->paste('x', C_('1:3'));
    is_deeply($x1->values, ['x 1', 'x 2', 'x 3']);
  }
  # paste($str, $vector, {sep => ''});
  {
    my $x1 = r->paste('x', C_('1:3'), {sep => ''});
    is_deeply($x1->values, ['x1', 'x2', 'x3']);
  }
}

# nchar
{
  my $x1 = c_("AAA", "BB", NA);
  my $x2 = r->nchar($x1);
  is_deeply($x2->values, [3, 2, undef])
}

# tolower
{
  my $x1 = c_("AA", "BB", NA);
  my $x2 = r->tolower($x1);
  is_deeply($x2->values, ["aa", "bb", undef])
}

# toupper
{
  my $x1 = c_("aa", "bb", NA);
  my $x2 = r->toupper($x1);
  is_deeply($x2->values, ["AA", "BB", undef])
}

# match
{
  my $x1 = c_("ATG", "GC", "AT", "GCGC");
  my $x2 = c_("CGCA", "GC", "AT", "AT", "ATA");
  my $x3 = r->match($x1, $x2);
  is_deeply($x3->values, [undef, 2, 3, undef])
}

# range
{
  my $x1 = c_(1, 2, 3);
  my $x2 = r->range($x1);
  is_deeply($x2->values, [1, 3]);
}

# pmax
{
  my $x1 = c_(1, 6, 3, 8);
  my $x2 = c_(5, 2, 7, 4);
  my $pmax = r->pmax($x1, $x2);
  is_deeply($pmax->values, [5, 6, 7, 8]);
}

# pmin
{
  my $x1 = c_(1, 6, 3, 8);
  my $x2 = c_(5, 2, 7, 4);
  my $pmin = r->pmin($x1, $x2);
  is_deeply($pmin->values, [1, 2, 3, 4]);
}
  
# rev
{
  my $x1 = c_(2, 4, 3, 1);
  my $x2 = r->rev($x1);
  is_deeply($x2->values, [1, 3, 4, 2]);
}

# T, F
{
  my $x1 = c_(T_, F_);
  is_deeply($x1->values, [1, 0]);
}

# sqrt
{
  # sqrt - numeric
  {
    my $e1 = c_(4, 9);
    my $e2 = r->sqrt($e1);
    is_deeply($e2->values, [2, 3]);
  }

  # sqrt - complex, 1 + 0i
  {
    my $e1 = c_(1 + 0*i_);
    my $e2 = r->sqrt($e1);
    is_deeply($e2->value, {re => 1, im => 0});
  }

  # sqrt - complex, 4 + 0i
  {
    my $e1 = c_(4 + 0*i_);
    my $e2 = r->sqrt($e1);
    is_deeply($e2->value, {re => 2, im => 0});
  }
  
  # sqrt - complex, -1 + 0i
  {
    my $e1 = c_(-1 + 0*i_);
    my $e2 = r->sqrt($e1);
    is_deeply($e2->value, {re => 0, im => 1});
  }

  # sqrt - complex, -4 + 0i
  {
    my $e1 = c_(-4 + 0*i_);
    my $e2 = r->sqrt($e1);
    is_deeply($e2->value, {re => 0, im => 2});
  }
}

# max
{
  # max
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = r->max($x1);
    is_deeply($x2->values, [3]);
  }

  # max - multiple arrays
  {
    my $x1 = c_(1, 2, 3);
    my $x2 = c_(4, 5, 6);
    my $x3 = r->max($x1, $x2);
    is_deeply($x3->values, [6]);
  }
  
  # max - no argument
  {
    my $x1 = r->max(NULL);
    is_deeply($x1->values, ['-Inf']);
  }
  
  # max - contain NA
  {
    my $x1 = r->max(c_(1, 2, NaN, NA));
    is_deeply($x1->values, [undef]);
  }
  
  # max - contain NaN
  {
    my $x1 = r->max(c_(1, 2, NaN));
    is_deeply($x1->values, ['NaN']);
  }
}

# median
{
  # median - odd number
  {
    my $x1 = c_(2, 3, 3, 4, 5, 1);
    my $x2 = r->median($x1);
    is_deeply($x2->values, [3]);
  }
  # median - even number
  {
    my $x1 = c_(2, 3, 3, 4, 5, 1, 6);
    my $x2 = r->median($x1);
    is_deeply($x2->values, [3.5]);
  }
}

# quantile
{
  # quantile - odd number
  {
    my $x1 = C_('0:100');
    my $x2 = r->quantile($x1);
    is_deeply($x2->values, [0, 25, 50, 75, 100]);
    is_deeply(r->names($x2)->values, [qw/0%  25%  50%  75% 100% /]);
  }
  
  # quantile - even number
  {
    my $x1 = C_('1:100');
    my $x2 = r->quantile($x1);
    is_deeply($x2->values, [1.00, 25.75, 50.50, 75.25, 100.00]);
  }

  # quantile - one element
  {
    my $x1 = c_(1);
    my $x2 = r->quantile($x1);
    is_deeply($x2->values, [1, 1, 1, 1, 1]);
  }
}

# unique
{
  # uniqeu - numeric
  my $x1 = c_(1, 1, 2, 2, 3, NA, NA, Inf, Inf);
  my $x2 = r->unique($x1);
  is_deeply($x2->values, [1, 2, 3, undef, 'Inf']);
}

# NA
{
  my $x1 = NA;
  my $na_value = $x1->value;
  is($na_value, undef);
  ok(r->is->na($x1));
  ok(r->is->logical($x1));
}

# round
{
  # round - array reference
  {
    my $x1 = c_(-1.3, 2.4, 2.5, 2.51, 3.51);
    my $x2 = r->round($x1);
    is_deeply(
      $x2->values,
      [-1, 2, 2, 3, 4]
    );
  }

  # round - matrix
  {
    my $x1 = c_(-1.3, 2.4, 2.5, 2.51, 3.51);
    my $x2 = r->round(matrix($x1));
    is_deeply(
      $x2->values,
      [-1, 2, 2, 3, 4]
    );
  }

  # round - array reference
  {
    my $x1 = c_(-13, 24, 25, 25.1, 35.1);
    my $x2 = r->round($x1, -1);
    is_deeply(
      $x2->values,
      [-10, 20, 20, 30, 40]
    );
  }

  # round - array reference
  {
    my $x1 = c_(-13, 24, 25, 25.1, 35.1);
    my $x2 = r->round($x1, {digits => -1});
    is_deeply(
      $x2->values,
      [-10, 20, 20, 30, 40]
    );
  }
  
  # round - matrix
  {
    my $x1 = c_(-13, 24, 25, 25.1, 35.1);
    my $x2 = r->round(matrix($x1), -1);
    is_deeply(
      $x2->values,
      [-10, 20, 20, 30, 40]
    );
  }
  
  # round - array reference
  {
    my $x1 = c_(-0.13, 0.24, 0.25, 0.251, 0.351);
    my $x2 = r->round($x1, 1);
    is_deeply(
      $x2->values,
      [-0.1, 0.2, 0.2, 0.3, 0.4]
    );
  }

  # round - matrix
  {
    my $x1 = c_(-0.13, 0.24, 0.25, 0.251, 0.351);
    my $x2 = r->round(matrix($x1), 1);
    is_deeply(
      $x2->values,
      [-0.1, 0.2, 0.2, 0.3, 0.4]
    );
  }
}

# trunc
{
  # trunc - array reference
  {
    my $x1 = c_(-1.2, -1, 1, 1.2);
    my $x2 = r->trunc($x1);
    is_deeply(
      $x2->values,
      [-1, -1, 1, 1]
    );
  }

  # trunc - matrix
  {
    my $x1 = c_(-1.2, -1, 1, 1.2);
    my $x2 = r->trunc(matrix($x1));
    is_deeply(
      $x2->values,
      [-1, -1, 1, 1]
    );
  }
}

# floor
{
  # floor - array reference
  {
    my $x1 = c_(2.5, 2.0, -1.0, -1.3);
    my $x2 = r->floor($x1);
    is_deeply(
      $x2->values,
      [2, 2, -1, -2]
    );
  }

  # floor - matrix
  {
    my $x1 = c_(2.5, 2.0, -1.0, -1.3);
    my $x2 = r->floor(matrix($x1));
    is_deeply(
      $x2->values,
      [2, 2, -1, -2]
    );
  }
}

# ceiling
{
  # ceiling - array reference
  {
    my $x1 = c_(2.5, 2.0, -1.0, -1.3);
    my $x2 = r->ceiling($x1);
    is_deeply(
      $x2->values,
      [3, 2, -1, -1]
    );
  }

  # ceiling - matrix
  {
    my $x1 = c_(2.5, 2.0, -1.0, -1.3);
    my $x2 = r->ceiling(matrix($x1));
    is_deeply(
      $x2->values,
      [3, 2, -1, -1]
    );
  }
}

# sqrt
{
  # sqrt - array reference
  {
    my $x1 = c_(2, 3, 4);
    my $x2 = r->sqrt($x1);
    is_deeply(
      $x2->values,
      [
        sqrt $x1->values->[0],
        sqrt $x1->values->[1],
        sqrt $x1->values->[2]
      ]
    );
  }

  # sqrt - matrix
  {
    my $x1 = c_(2, 3, 4);
    my $x2 = r->sqrt(matrix($x1));
    is_deeply(
      $x2->values,
      [
        sqrt $x1->values->[0],
        sqrt $x1->values->[1],
        sqrt $x1->values->[2]
      ]
    );
  }
}

# c_double
{
  # c_double - arguments is list
  {
    my $x1 = r->c_double(1.1, 1.2, 1.3);
    ok($x1->is->double);
    is_deeply($x1->values, [1.1, 1.2, 1.3]);
  }

  # c_double - arguments is array reference
  {
    my $x1 = r->c_double([1.1, 1.2, 1.3]);
    ok($x1->is->double);
    is_deeply($x1->values, [1.1, 1.2, 1.3]);
  }
}

# clone
{
  
  # clone - vector
  {
    my $x1 = r->matrix(C_('1:24'), 3, 2);
    r->names($x1 => c_('r1', 'r2', 'r3'));
    my $x2 = r->clone($x1);
    is_deeply(r->names($x2)->values, ['r1', 'r2', 'r3']);
  }
  
  # clone - matrix
  {
    my $x1 = r->matrix(C_('1:24'), 3, 2);
    r->rownames($x1 => c_('r1', 'r2', 'r3'));
    r->colnames($x1 => c_('c1', 'c2'));
    my $x2 = r->clone($x1);
    ok(r->is->matrix($x2));
    is_deeply(r->dim($x2)->values, [3, 2]);
    is_deeply(r->rownames($x2)->values, ['r1', 'r2', 'r3']);
    is_deeply(r->colnames($x2)->values, ['c1', 'c2']);
  }
}

# c_character
{
  # c_character - arguments is list
  {
    my $x1 = r->c_character("a", "b", "c");
    ok($x1->is->character);
    is_deeply($x1->values, [qw/a b c/]);
  }

  # c_character - arguments is array reference
  {
    my $x1 = r->c_character(["a", "b", "c"]);
    ok($x1->is->character);
    is_deeply($x1->values, [qw/a b c/]);
  }
}

# c_complex
{
  # c_complex - arguments is list
  {
    my $x1 = r->c_complex({re => 1, im => 2}, {re => 3, im => 4});
    ok($x1->is->complex);
    is_deeply($x1->values, [{re => 1, im => 2}, {re => 3, im => 4}]);
  }

  # c_complex - arguments is array reference
  {
    my $x1 = r->c_complex([{re => 1, im => 2}, {re => 3, im => 4}]);
    ok($x1->is->complex);
    is_deeply($x1->values, [{re => 1, im => 2}, {re => 3, im => 4}]);
  }
}

# array
{
  # array - basic
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    is_deeply($x1->values, [1 .. 24]);
    is_deeply(r->dim($x1)->values, [4, 3, 2]);
  }
  
  # array - dim option
  {
    my $x1 = array(C_('1:24'), {dim => c_(4, 3, 2)});
    is_deeply($x1->values, [1 .. 24]);
    is_deeply(r->dim($x1)->values, [4, 3, 2]);
  }
}

# value
{
  # value - none argument
  {
    my $x1 = array(C_('1:4'));
    is($x1->value, 1);
  }

  # value - one-dimetion
  {
    my $x1 = array(C_('1:4'));
    is($x1->value(2), 2);
  }
  
  # value - two-dimention
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    is($x1->value(3, 2), 7);
  }

  # value - two-dimention, as_vector
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    is(r->as->vector($x1)->value(5), 5);
  }
  
  # value - three-dimention
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 1));
    is($x1->value(3, 2, 1), 7);
  }
}

# create element
{
  # create element - double
  {
    my $x1 = c_(1, 2, 3);
  }
  
  # create element - character
  {
    my $x1 = c_("a", "b", "c");
  }
}

# names
{
  # names - get
  {
    my $x1 = c_(1, 2, 3, 4);
    is_deeply($x1->values, [1, 2, 3, 4]);
    
    r->names($x1 => c_('a', 'b', 'c', 'd'));
    my $x2 = $x1->get(c_('b', 'd'));
    is_deeply($x2->values, [2, 4]);
  }
  
  # names - to_string
  {
    my $x1 = c_(1, 2, 3);
    r->names($x1 => c_('a', 'b', 'c'));
    is("$x1", "a b c\n[1] 1 2 3\n");
  }
}
