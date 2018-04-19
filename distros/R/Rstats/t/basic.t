use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;
use Math::Trig ();
use Rstats::Array;

my $r = Rstats->new;

# complex
{
  # complex
  {
    my $a1 = $r->complex(1, 2);
    is($a1->value->{re}, 1);
    is($a1->value->{im}, 2);
  }
}

# as_numeric
{
  # as_numeric - from complex
  {
    my $a1 = $r->c([$r->complex(1, 1), $r->complex(2, 2)]);
    $a1->mode('complex');
    my $a2 = $r->as_numeric($a1);
    is($a2->mode->value, 'numeric');
    is_deeply($a2->values, [1, 2]);
  }

  # as_numeric - from numeric
  {
    my $a1 = $r->c([0.1, 1.1, 2.2]);
    $a1->mode('numeric');
    my $a2 = $r->as_numeric($a1);
    is($a2->mode->value, 'numeric');
    is_deeply($a2->values, [0.1, 1.1, 2.2]);
  }
    
  # as_numeric - from integer
  {
    my $a1 = $r->c([0, 1, 2]);
    $a1->mode('integer');
    my $a2 = $r->as_numeric($a1);
    is($a2->mode->value, 'numeric');
    is_deeply($a2->values, [0, 1, 2]);
  }
  
  # as_numeric - from logical
  {
    my $a1 = $r->c([$r->TRUE, $r->FALSE]);
    $a1->mode('logical');
    my $a2 = $r->as_numeric($a1);
    is($a2->mode->value, 'numeric');
    is_deeply($a2->values, [1, 0]);
  }

  # as_numeric - from character
  {
    my $a1 = $r->c([0, 1, 2])->as_integer;
    my $a2 = $r->as_numeric($a1);
    is($a2->mode->value, 'numeric');
    is_deeply($a2->values, [0, 1, 2]);
  }
}
  
# is_*, as_*, typeof
{
  # is_*, as_*, typeof - integer
  {
    my $c = $r->c([0, 1, 2]);
    ok($c->as_integer->is_integer);
    is($c->as_integer->mode->value, 'numeric');
    is($c->as_integer->typeof->value, 'integer');
  }
  
  # is_*, as_*, typeof - character
  {
    my $c = $r->c([0, 1, 2]);
    ok($c->as_character->is_character);
    is($c->as_character->mode->value, 'character');
    is($c->as_character->typeof->value, 'character');
  }
  
  # is_*, as_*, typeof - complex
  {
    my $c = $r->c([0, 1, 2]);
    ok($c->as_complex->is_complex);
    is($c->as_complex->mode->value, 'complex');
    is($c->as_complex->typeof->value, 'complex');
  }
  
  # is_*, as_*, typeof - logical
  {
    my $a1 = $r->c([0, 1, 2]);
    my $a2 = $r->as_logical($a1);
    ok($a2->is_logical);
    is($a2->mode->value, 'logical');
    is($a2->typeof->value, 'logical');
  }

  # is_*, as_*, typeof - NULL
  {
    my $a1 = $r->NULL;
    is($a1->mode->value, 'logical');
    is($a1->typeof->value, 'logical');
  }
}

# matrix
{
  {
    my $mat = $r->matrix(0, 2, 5);
    is_deeply($mat->values, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    is_deeply($mat->dim->values, [2, 5]);
    ok($mat->is_matrix);
  }
  
  # matrix - repeat values
  {
    my $mat = $r->matrix([1,2], 2, 5);
    is_deeply($mat->values, [1, 2, 1, 2, 1, 2, 1, 2, 1, 2]);
    is_deeply($mat->dim->values, [2, 5]);
    ok($mat->is_matrix);
  }
}

# cumsum
{
  my $v1 = $r->c([1, 2, 3]);
  my $v2 = $r->cumsum($v1);
  is_deeply($v2->values, [1, 3, 6]);
}

# rnorm
{
  my $v1 = $r->rnorm(100);
  is($r->length($v1), 100);
}

# sequence
{
  my $v1 = $r->c([1, 2, 3]);
  my $v2 = $r->sequence($v1);
  is_deeply($v2->values, [1, 1, 2, 1, 2, 3])
}
  
# sample
{
  {
    my $v1 = $r->c($r->C('1:100'));
    my $v2 = $r->sample($v1, 50);
    is($r->length($v2), 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $v2_value (@{$v2->values}) {
      $duplicate_h->{$v2_value}++;
      $duplicate = 1 if $duplicate_h->{$v2_value} > 2;
      unless (grep { $_ eq $v2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$duplicate);
    ok(!$invalid_value);
  }
  
  # sample - replace => 0
  {
    my $v1 = $r->c($r->C('1:100'));
    my $v2 = $r->sample($v1, 50, {replace => 0});
    is($r->length($v2), 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $v2_value (@{$v2->values}) {
      $duplicate_h->{$v2_value}++;
      $duplicate = 1 if $duplicate_h->{$v2_value} > 2;
      unless (grep { $_ eq $v2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$duplicate);
    ok(!$invalid_value);
  }

  # sample - replace => 0
  {
    my $v1 = $r->c($r->C('1:100'));
    my $v2 = $r->sample($v1, 50, {replace => 1});
    is($r->length($v2), 50);
    my $duplicate_h = {};
    my $duplicate;
    my $invalid_value;
    for my $v2_value (@{$v2->values}) {
      unless (grep { $_ eq $v2_value } (1 .. 100)) {
        $invalid_value = 1;
      }
    }
    ok(!$invalid_value);
  }
  
  # sample - replace => 0, (strict check)
  {
    my $v1 = $r->c(1);
    my $v2 = $r->sample($v1, 5, {replace => 1});
    is($r->length($v2), 5);
    is_deeply($v2->values, [1, 1, 1, 1, 1]);
  }
}

# NULL
{
  my $v1 = $r->NULL;
  is_deeply($v1->values, []);
  is("$v1", 'NULL');
  $v1->at(3)->set(5);
  is_deeply($v1->values, [undef, undef, 5]);
}

# order
{
  my $v1 = $r->c([2, 4, 3, 1]);
  my $v2 = $r->order($v1);
  is_deeply($v2->values, [4, 1, 3, 2]);
}

# rev
{
  my $v1 = $r->c([2, 4, 3, 1]);
  my $v2 = $r->rev($v1);
  is_deeply($v2->values, [2, 3, 1, 4]);
}

# runif
{
  {
    srand 100;
    my $rands = [rand 1, rand 1, rand 1, rand 1, rand 1];
    $r->set_seed(100);
    my $v1 = $r->runif(5);
    is_deeply($v1->values, $rands);
    
    my $v2 = $r->runif(5);
    isnt($v1->values->[0], $v2->values->[0]);

    my $v3 = $r->runif(5);
    isnt($v2->values->[0], $v3->values->[0]);
    
    my $v4 = $r->runif(100);
    my @in_ranges = grep { $_ >= 0 && $_ <= 1 } @{$v4->values};
    is(scalar @in_ranges, 100);
  }
  
  # runif - min and max
  {
    srand 100;
    my $rands = [
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1
    ];
    $r->set_seed(100);
    my $v1 = $r->runif(5, 1, 10);
    is_deeply($v1->values, $rands);

    my $v2 = $r->runif(100, 1, 2);
    my @in_ranges = grep { $_ >= 1 && $_ <= 2 } @{$v2->values};
    is(scalar @in_ranges, 100);
  }
}

# which
{
  my $v1 = $r->c(['a', 'b', 'a']);
  my $v2 = $r->which($v1, sub { $_ eq 'a' });
  is_deeply($v2->values, [1, 3]);
}

# elseif
{
  my $v1 = $r->c([1, 0, 1]);
  my $v2 = $r->ifelse($v1, 'a', 'b');
  is_deeply($v2->values, ['a', 'b', 'a']);
}

# replace
{
  {
    my $v1 = $r->c($r->C('1:10'));
    my $v2 = $r->c([2, 5, 10]);
    my $v3 = $r->c([12, 15, 20]);
    my $v4 = $r->replace($v1, $v2, $v3);
    is_deeply($v4->values, [1, 12, 3, 4, 15, 6, 7, 8, 9, 20]);
  }
  
  # replace - single value
  {
    my $v1 = $r->c($r->C('1:10'));
    my $v2 = $r->c([2, 5, 10]);
    my $v4 = $r->replace($v1, $v2, 11);
    is_deeply($v4->values, [1, 11, 3, 4, 11, 6, 7, 8, 9, 11]);
  }
  
  # replace - few values
  {
    my $v1 = $r->c($r->C('1:10'));
    my $v2 = $r->c([2, 5, 10]);
    my $v4 = $r->replace($v1, $v2, [12, 15]);
    is_deeply($v4->values, [1, 12, 3, 4, 15, 6, 7, 8, 9, 12]);
  }
}

# head
{
  {
    my $v1 = $r->c([1, 2, 3, 4, 5, 6, 7]);
    my $head = $r->head($v1);
    is_deeply($head->values, [1, 2, 3, 4, 5, 6]);
  }
  
  # head - values is low than 6
  {
    my $v1 = $r->c([1, 2, 3]);
    my $head = $r->head($v1);
    is_deeply($head->values, [1, 2, 3]);
  }
  
  # head - n option
  {
    my $v1 = $r->c([1, 2, 3, 4]);
    my $head = $r->head($v1, {n => 3});
    is_deeply($head->values, [1, 2, 3]);
  }
}

# tail
{
  {
    my $v1 = $r->c([1, 2, 3, 4, 5, 6, 7]);
    my $tail = $r->tail($v1);
    is_deeply($tail->values, [2, 3, 4, 5, 6, 7]);
  }
  
  # tail - values is low than 6
  {
    my $v1 = $r->c([1, 2, 3]);
    my $tail = $r->tail($v1);
    is_deeply($tail->values, [1, 2, 3]);
  }
  
  # tail - n option
  {
    my $v1 = $r->c([1, 2, 3, 4]);
    my $tail = $r->tail($v1, {n => 3});
    is_deeply($tail->values, [2, 3, 4]);
  }
}

# to_string
{
  my $array = $r->array([1, 2, 3]);
  is("$array", "[1] 1 2 3\n");
}

# length
{
  my $array = $r->array([1, 2, 3]);
  is($r->length($array), 3);
}

# array
{
  {
    my $array = $r->array(25);
    is_deeply($array->values, [25]);
  }
  {
    my $array = $r->array([1, 2, 3]);
    is_deeply($array->dim->values, [3]);
  }
}

# Array get and set
{
  my $array = $r->array([1, 2, 3]);
  is_deeply($array->get(1)->values, [1]);
  is_deeply($array->get(3)->values, [3]);
  $array->at(1)->set(5);;
  is_deeply($array->get(1)->values, [5]);
}

# paste
{
  my $r = Rstats->new;
  
  # paste($str, $vector);
  {
    my $v = $r->paste('x', $r->c($r->C('1:3')));
    is_deeply($v->values, ['x 1', 'x 2', 'x 3']);
  }
  # paste($str, $vector, {sep => ''});
  {
    my $v = $r->paste('x', $r->c($r->C('1:3')), {sep => ''});
    is_deeply($v->values, ['x1', 'x2', 'x3']);
  }
}

# c
{
  my $r = Rstats->new;
  
  # c($array)
  {
    my $v = $r->c([1, 2, 3]);
    is_deeply($v->values, [1, 2, 3]);
  }
  
  # c($vector)
  {
    my $v = $r->c($r->c([1, 2, 3]));
    is_deeply($v->values, [1, 2, 3]);
  }
  
  # c($r->C('1:3')
  {
    my $v = $r->c($r->C('1:3'));
    is_deeply($v->values, [1, 2, 3]);
  }
  
  # c('0.5*1:3')
  {
    my $v = $r->C('0.5*1:3');
    is_deeply($v->values, [1, 1.5, 2, 2.5, 3]);
  }
}

# rep function
{
  my $r = Rstats->new;
  
  # req($v, {times => $times});
  {
    my $v1 = $r->c([1, 2, 3]);
    my $v2 = $r->rep($v1, {times => 3});
    is_deeply($v2->values, [1, 2, 3, 1, 2, 3, 1, 2, 3]);
  }
}

# seq function
{
  my $r = Rstats->new;

  # seq($from)
  {
    my $v = $r->seq(3);
    is_deeply($v->values, [1, 2, 3]);
  }
  
  # seq($from, $to),  n > m
  {
    my $v = $r->seq([1, 3]);
    is_deeply($v->values, [1, 2, 3]);
  }

  # seq({from => $from, to => $to}),  n > m
  {
    my $v = $r->seq({from => 1, to => 3});
    is_deeply($v->values, [1, 2, 3]);
  }
  
  # seq($from, $to),  n < m
  {
    my $v = $r->seq([3, 1]);
    is_deeply($v->values, [3, 2, 1]);
  }
  
  # seq($from, $to), n = m
  {
    my $v = $r->seq([2, 2]);
    is_deeply($v->values, [2]);
  }
  
  # seq($from, $to, {by => p}) n > m
  {
    my $v = $r->seq([1, 3], {by => 0.5});
    is_deeply($v->values, [1, 1.5, 2.0, 2.5, 3.0]);
  }

  # seq($from, $to, {by => p}) n > m
  {
    my $v = $r->seq([3, 1], {by => -0.5});
    is_deeply($v->values, [3.0, 2.5, 2.0, 1.5, 1.0]);
  }
  
  # seq($from, {by => p, length => l})
  {
    my $v = $r->seq([1, 3], {length => 5});
    is_deeply($v->values, [1, 1.5, 2.0, 2.5, 3.0]);
  }
  
  # seq(along => $v);
  my $v1 = $r->c([3, 4, 5]);
  my $v2 = $r->seq({along => $v1});
  is_deeply($v2->values, [1, 2, 3]);
}

# Method
{
  my $r = Rstats->new;
  
  # add (vector)
  {
    my $v1 = $r->c([1, 2, 3]);
    my $v2 = $r->c([$v1, 4, 5]);
    is_deeply($v2->values, [1, 2, 3, 4, 5]);
  }
  # add (array)
  {
    my $v1 = $r->c([[1, 2], 3, 4]);
    is_deeply($v1->values, [1, 2, 3, 4]);
  }
  
  # add to original vector
  {
    my $v1 = $r->c([1, 2, 3]);
    $v1->at($r->length($v1) + 1)->set(6);
    is_deeply($v1->values, [1, 2, 3, 6]);
  }
  
  # append(after option)
  {
    my $v1 = $r->c([1, 2, 3, 4, 5]);
    $r->append($v1, 1, {after => 3});
    is_deeply($v1->values, [1, 2, 3, 1, 4, 5]);
  }

  # append(no after option)
  {
    my $v1 = $r->c([1, 2, 3, 4, 5]);
    $r->append($v1, 1);
    is_deeply($v1->values, [1, 2, 3, 4, 5, 1]);
  }

  # append(array)
  {
    my $v1 = $r->c([1, 2, 3, 4, 5]);
    $r->append($v1, [6, 7]);
    is_deeply($v1->values, [1, 2, 3, 4, 5, 6, 7]);
  }

  # append(vector)
  {
    my $v1 = $r->c([1, 2, 3, 4, 5]);
    $r->append($v1, $r->c([6, 7]));
    is_deeply($v1->values, [1, 2, 3, 4, 5, 6, 7]);
  }
    
  # numeric
  {
    my $v1 = $r->numeric(3);
    is_deeply($v1->values, [0, 0, 0]);
  }

  # max
  {
    my $v = $r->c([1, 2, 3]);
    my $max = $r->max($v);
    is($max, 3);
  }
  
  # max - multiple vectors
  {
    my $v1 = $r->c([1, 2, 3]);
    my $v2 = $r->c([4, 5, 6]);
    my $max = $r->max($v1, $v2);
    is($max, 6);
  }
  
  # min
  {
    my $v = $r->c([1, 2, 3]);
    my $min = $r->min($v);
    is($min, 1);
  }
  
  # pmax
  {
    my $v1 = $r->c([1, 6, 3, 8]);
    my $v2 = $r->c([5, 2, 7, 4]);
    my $pmax = $r->pmax($v1, $v2);
    is_deeply($pmax->values, [5, 6, 7, 8]);
  }

  # min - multiple vectors
  {
    my $v1 = $r->c([1, 2, 3]);
    my $v2 = $r->c([4, 5, 6]);
    my $min = $r->min($v1, $v2);
    is($min, 1);
  }
  
  # pmin
  {
    my $v1 = $r->c([1, 6, 3, 8]);
    my $v2 = $r->c([5, 2, 7, 4]);
    my $pmin = $r->pmin($v1, $v2);
    is_deeply($pmin->values, [1, 2, 3, 4]);
  }

  # range
  {
    my $v1 = $r->c([1, 2, 3]);
    my $v2 = $r->range($v1);
    is_deeply($v2->values, [1, 3]);
  }
  
  # length
  {
    my $v1 = $r->c([1, 2, 4]);
    my $length = $r->length($v1);
    is($length, 3);
  }

  # sum
  {
    my $v1 = $r->c([1, 2, 3]);
    my $sum = $r->sum($v1);
    is($sum->value, 6);
  }

  # prod
  {
    my $v1 = $r->c([2, 3, 4]);
    my $prod = $r->prod($v1);
    is($prod->value, 24);
  }
  
  # mean
  {
    my $v1 = $r->c([1, 2, 3]);
    my $mean = $r->mean($v1);
    is($mean->value, 2);
  }

  # var
  {
    my $v1 = $r->c([2, 3, 4, 7, 9]);
    my $var = $r->var($v1);
    is($var->value, 8.5);
  }
  
  # sort
  {
    {
      my $v1 = $r->c([2, 1, 5]);
      my $v1_sorted = $r->sort($v1);
      is_deeply($v1_sorted->values, [1, 2, 5]);
    }
    
    # sort - decreasing
    {
      my $v1 = $r->c([2, 1, 5]);
      my $v1_sorted = $r->sort($v1, {decreasing => 1});
      is_deeply($v1_sorted->values, [5, 2, 1]);
    }
  }
}
