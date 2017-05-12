use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;
use Rstats::Util;

# TODO
#   which
#   get - logical, undef

# looks_like_logical
{
  # looks_like_logical - "TRUE"
  {
    my $str = "TRUE";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(defined $ret);
    ok($ret);
  }

  # looks_like_logical - "  TRUE  "
  {
    my $str = "  TRUE  ";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(defined $ret);
    ok($ret);
  }

  # looks_like_logical - "T"
  {
    my $str = "T";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(defined $ret);
    ok($ret);
  }

  # looks_like_logical - "FALSE"
  {
    my $str = "FALSE";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(defined $ret);
    ok(!$ret);
  }

  # looks_like_logical - "F"
  {
    my $str = "F";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(defined $ret);
    ok(!$ret);
  }
  
  # looks_like_logical - "abc"
  {
    my $str = "abc";
    my $ret = Rstats::Util::looks_like_logical($str);
    ok(!defined $ret);
  }
}

# looks_like_complex
{
  # looks_like_complex - "abc"
  {
    my $num_str = "abc";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    ok(!defined $ret);
  }
  
  # looks_like_complex - "2i"
  {
    my $num_str = "2i";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 0);
    cmp_ok($ret->{im}, "==", 2);
  }

  # looks_like_complex - "2.3i"
  {
    my $num_str = "2.3i";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 0);
    cmp_ok($ret->{im}, "==", 2.3);
  }

  # looks_like_complex - "-2.3i"
  {
    my $num_str = "-2.3i";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 0);
    cmp_ok($ret->{im}, "==", -2.3);
  }

  # looks_like_complex - "  2.3i  "
  {
    my $num_str = "  2.3i  ";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 0);
    cmp_ok($ret->{im}, "==", 2.3);
  }

  # looks_like_complex - "1.2+2.3i"
  {
    my $num_str = "1.2+2.3i";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 1.2);
    cmp_ok($ret->{im}, "==", 2.3);
  }

  # looks_like_complex - "  1.2  +  2.3i  "
  {
    my $num_str = "  1.2+2.3i  ";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", 1.2);
    cmp_ok($ret->{im}, "==", 2.3);
  }

  # looks_like_complex - "-1.2-2.3i"
  {
    my $num_str = "-1.2-2.3i";
    my $ret = Rstats::Util::looks_like_complex($num_str);
    cmp_ok($ret->{re}, "==", -1.2);
    cmp_ok($ret->{im}, "==", -2.3);
  }
}

# looks_like_double
{
  # looks_like_double - 5.23
  {
    my $num_str = "5.23";
    my $ret = Rstats::Util::looks_like_double($num_str);
    cmp_ok($ret, "==", 5.23);
  }
}

# looks_like_integer
{
  # looks_like_double - 5
  {
    my $num_str = "5";
    my $ret = Rstats::Util::looks_like_integer($num_str);
    cmp_ok($ret, "==", 5);
  }
}

# cross_product
{
  my $values = [
    ['a1', 'a2'],
    ['b1', 'b2'],
    ['c1', 'c2']
  ];
  
  my $x1 = array(C_('1:3'));
  my $result =  Rstats::Util::cross_product($values);
  is_deeply($result, [
    ['a1', 'b1', 'c1'],
    ['a2', 'b1', 'c1'],
    ['a1', 'b2', 'c1'],
    ['a2', 'b2', 'c1'],
    ['a1', 'b1', 'c2'],
    ['a2', 'b1', 'c2'],
    ['a1', 'b2', 'c2'],
    ['a2', 'b2', 'c2']
  ]);
}

# pos_to_index
{
  # pos_to_index - last position
  {
    my $pos = 23;
    my $index = Rstats::Util::pos_to_index($pos, [4, 3, 2]);
    is_deeply($index, [4, 3, 2]);
  }

  # pos_to_index - some position
  {
    my $pos = 21;
    my $index = Rstats::Util::pos_to_index($pos, [4, 3, 2]);
    is_deeply($index, [2, 3, 2]);
  }

  # pos_to_index - first position
  {
    my $pos = 0;
    my $index = Rstats::Util::pos_to_index($pos, [4, 3, 2]);
    is_deeply($index, [1, 1, 1]);
  }
}


# index_to_pos
{
  my $x1 = array(C_('1:24'), c_(4, 3, 2));
  my $dim = [4, 3, 2];
  
  {
    my $value = Rstats::Util::index_to_pos([4, 3, 2], $dim);
    is($value, 23);
  }
  
  {
    my $value = Rstats::Util::index_to_pos([3, 3, 2], $dim);
    is($value, 22);
  }
}