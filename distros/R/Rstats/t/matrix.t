use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

my $r = Rstats->new;

# arr.ind=TRUE

# t
{
  # t - basic
  {
    my $m1 = $r->matrix($r->C('1:6'), 3, 2);
    my $m2 = $r->t($m1);
    is_deeply($m2->values, [1, 4, 2, 5, 3, 6]);
    is_deeply($r->dim($m2)->values, [2, 3]);
  }
}

# cbind
{
  my $m1 = $r->cbind(
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12]
  );
  is_deeply($m1->values, [1 .. 12]);
  is_deeply($m1->dim->values, [4, 3]);
}

# rbind
{
  my $m1 = $r->rbind(
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12]
  );
  is_deeply($m1->values, [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]);
  is_deeply($m1->dim->values, [3, 4]);
}

# rowSums
{
  my $m1 = $r->matrix($r->C('1:12'), 4, 3);
  my $v1 = $r->rowSums($m1);
  is_deeply($v1->values,[10, 26, 42]);
  is_deeply($v1->dim->values, []);
}

# rowMeans
{
  my $m1 = $r->matrix($r->C('1:12'), 4, 3);
  my $v1 = $r->rowMeans($m1);
  is_deeply($v1->values,[10/4, 26/4, 42/4]);
  is_deeply($v1->dim->values, []);
}

# colSums
{
  my $m1 = $r->matrix($r->C('1:12'), 4, 3);
  my $v1 = $r->colSums($m1);
  is_deeply($v1->values,[15, 18, 21, 24]);
  is_deeply($v1->dim->values, []);
}

# colMeans
{
  my $m1 = $r->matrix($r->C('1:12'), 4, 3);
  my $v1 = $r->colMeans($m1);
  is_deeply($v1->values,[15/3, 18/3, 21/3, 24/3]);
  is_deeply($v1->dim->values, []);
}

# row
{
  my $m1 = $r->matrix($r->C('1:12'), 3, 4);
  my $m2 = $r->row($m1);
  is_deeply($m2->values,[1,2,3,1,2,3,1,2,3,1,2,3]);
  is_deeply($m2->dim->values, [3, 4]);
}

# col
{
  my $m1 = $r->matrix($r->C('1:12'), 3, 4);
  my $m2 = $r->col($m1);
  is_deeply($m2->values,[1,1,1,2,2,2,3,3,3,4,4,4]);
  is_deeply($m2->dim->values, [3, 4]);
}

# nrow and ncol
{
  my $m1 = $r->matrix($r->C('1:12'), 3, 4);
  is_deeply($r->nrow($m1)->values, [3]);
  is_deeply($r->ncol($m1)->values, [4]);
}

# matrix
{
  # matrix - basic
  {
    my $m1 = $r->matrix($r->C('1:12'), 3, 4);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }
  
  # matrix - omit row
  {
    my $m1 = $r->matrix($r->C('1:12'), 3);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }
  
  # matrix - omit col
  {
    my $m1 = $r->matrix($r->C('1:12'), undef, 4);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }

  # matrix - omit col
  {
    my $m1 = $r->matrix($r->C('1:12'));
    is_deeply($m1->values, [1 .. 12]);
    is_deeply($r->dim($m1)->values, [12, 1]);
    ok($m1->is_matrix);
  }

  # matrix - nrow and ncol option
  {
    my $m1 = $r->matrix($r->C('1:12'), {nrow => 4, ncol => 3});
    is_deeply($m1->values, [1 .. 12]);
    is_deeply($r->dim($m1)->values, [4, 3]);
    ok($m1->is_matrix);
  }
  
  # matrix - repeat
  {
    my $m1 = $r->matrix($r->C('1:3'), 3, 4);
    is_deeply($m1->values, [(1 .. 3) x 4]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }

  # matrix - repeat 2
  {
    my $m1 = $r->matrix($r->C('1:10'), 3, 4);
    is_deeply($m1->values, [1 .. 10, 1, 2]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }
  
  # matrix - repeat 3
  {
    my $m1 = $r->matrix(0, 3, 4);
    is_deeply($m1->values, [(0) x 12]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }
  
  # matrix - byrow
  {
    my $m1 = $r->matrix($r->C('1:12'), 3, 4, {byrow => 1});
    is_deeply($m1->values, [(1, 5, 9), (2, 6, 10), (3, 7,11), (4, 8, 12)]);
    is_deeply($r->dim($m1)->values, [3, 4]);
    ok($m1->is_matrix);
  }
}

# rownames and colnames
{
  # rownames and colnames - accessor
  {
    my $m1 = $r->matrix($r->C('1:6'), 2, 3);
    $r->colnames($m1, [qw/c1 c2 c3/]);
    is_deeply($r->colnames($m1)->values, [qw/c1 c2 c3/]);
    $r->rownames($m1, [qw/r1 r2 r3/]);
    is_deeply($r->rownames($m1)->values, [qw/r1 r2 r3/]);
  }

  # rownames and colnames - to_string
  {
    my $m1 = $r->matrix($r->C('1:6'), 2, 3);
    $r->colnames($m1, [qw/c1 c2 c3/]);
    $r->rownames($m1, [qw/r1 r2 r3/]);
    my $m1_str = "$m1";
    $m1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
    c1 c2 c3
r1 1 3 5
r2 2 4 6
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($m1_str, $expected);
  }
}

