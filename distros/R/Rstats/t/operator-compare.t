use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# comparison operator numeric
{

  # comparison operator numeric - <
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 < $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 0]);
  }
  
  # comparison operator numeric - <, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 < $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 0]);
  }

  # comparison operator numeric - <=
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 <= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 1]);
  }

  # comparison operator numeric - <=, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 <= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 1, 0]);
  }

  # comparison operator numeric - >
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 > $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 0]);
  }

  # comparison operator numeric - >, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 > $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 0, 1]);
  }

  # comparison operator numeric - >=
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 >= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 1]);
  }

  # comparison operator numeric - >=, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 >= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 1]);
  }

  # comparison operator numeric - ==
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2,2));
    my $x3 = $x1 == $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1]);
  }

  # comparison operator numeric - ==, arguments count is different
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2));
    my $x3 = $x1 == $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1]);
  }

  # comparison operator numeric - !=
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2,2));
    my $x3 = $x1 != $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0]);
  }

  # comparison operator numeric - !=, arguments count is different
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2));
    my $x3 = $x1 != $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0]);
  }
}

# comparison operator
{
  # comparison operator - >
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 > $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/0 0 1/]);
  }

  # comparison operator - >=
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 >= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/0 1 1/]);
  }

  # comparison operator - <
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 < $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/1 0 0/]);
  }

  # comparison operator - <=
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 <= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/1 1 0/]);
  }

  # comparison operator - ==
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 == $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/0 1 0/]);
  }

  # comparison operator - !=
  {
    my $x1 = array(c_(0, 1, 2));
    my $x2 = array(c_(1, 1, 1));
    my $x3 = $x1 != $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [qw/1 0 1/]);
  }
}

# comparison operator numeric
{

  # comparison operator numeric - <
  {
    my $x1 = array(c_(1, 2, 3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 < $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 0]);
  }

  # comparison operator numeric - <, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 < $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 0]);
  }

  # comparison operator numeric - <=
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 <= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0, 1]);
  }

  # comparison operator numeric - <=, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 <= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 1, 0]);
  }

  # comparison operator numeric - >
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 > $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 0]);
  }

  # comparison operator numeric - >, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 > $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 0, 1]);
  }

  # comparison operator numeric - >=
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2,1,3));
    my $x3 = $x1 >= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 1]);
  }

  # comparison operator numeric - >=, arguments count is different
  {
    my $x1 = array(c_(1,2,3));
    my $x2 = array(c_(2));
    my $x3 = $x1 >= $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1, 1]);
  }

  # comparison operator numeric - ==
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2,2));
    my $x3 = $x1 == $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1]);
  }

  # comparison operator numeric - ==, arguments count is different
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2));
    my $x3 = $x1 == $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [0, 1]);
  }

  # comparison operator numeric - !=
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2,2));
    my $x3 = $x1 != $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0]);
  }

  # comparison operator numeric - !=, arguments count is different
  {
    my $x1 = array(c_(1,2));
    my $x2 = array(c_(2));
    my $x3 = $x1 != $x2;
    ok(r->is->logical($x3));
    is_deeply($x3->values, [1, 0]);
  }
}

# comparison operator
{
  # comparison operator - ==, true
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    my $ret = r->equal($z1, $z2);
    is($ret->value, 1);
  }
  # comparison operator - ==, false
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 1});
    my $ret = r->equal($z1, $z2);
    is($ret->value, 0);
  }

  # comparison operator - !=, true
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    is(r->not_equal($z1, $z2)->value, 0);
  }
  
  # comparison operator - !=, false
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 1});
    is(r->not_equal($z1, $z2)->value, 1);
  }

  # comparison operator - <, error
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    eval { my $result = r->less_than($z1, $z2) };
    like($@, qr/invalid/);
  }

  # comparison operator - <=, error
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    eval { my $result = r->less_than_or_equal($z1, $z2) };
    like($@, qr/invalid/);
  }

  # comparison operator - >, error
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    eval { my $result = r->more_than($z1, $z2) };
    like($@, qr/invalid/);
  }

  # comparison operator - >=, error
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    my $z2 = r->c_complex({re => 1, im => 2});
    eval { my $result = r->more_than_or_equal($z1, $z2) };
    like($@, qr/invalid/);
  }
}