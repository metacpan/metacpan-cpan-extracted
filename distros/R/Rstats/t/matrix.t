use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# TODO
# arr.ind=TRUE

# cbind
{
  my $m1 = r->cbind(
    c_(1, 2, 3, 4),
    c_(5, 6, 7, 8),
    c_(9, 10, 11, 12)
  );
  is_deeply($m1->values, [1 .. 12]);
  is_deeply(r->dim($m1)->values, [4, 3]);
}

# matrix
{
  
  # matrix - matrix(2, 2);
  {
    my $x1 = matrix(2, 2);
    is_deeply($x1->values, [2, 2]);
    is_deeply($x1->dim->values, [2, 1]);
  }
  
  # matrix - byrow
  {
    my $m1 = matrix(C_('1:12'), 3, 4, {byrow => 1});
    is_deeply($m1->values, [(1, 5, 9), (2, 6, 10), (3, 7,11), (4, 8, 12)]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }

  # matrix - omit col
  {
    my $m1 = matrix(C_('1:12'), undef, 4);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }
  
  # matrix - basic
  {
    my $m1 = matrix(C_('1:12'), 3, 4);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }
  
  # matrix - omit row
  {
    my $m1 = matrix(C_('1:12'), 3);
    is_deeply($m1->values, [1 .. 12]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }
  
  # matrix - omit col
  {
    my $m1 = matrix(C_('1:12'));
    is_deeply($m1->values, [1 .. 12]);
    is_deeply(r->dim($m1)->values, [12, 1]);
    ok(r->is->matrix($m1));
  }

  # matrix - nrow and ncol option
  {
    my $m1 = matrix(C_('1:12'), {nrow => 4, ncol => 3});
    is_deeply($m1->values, [1 .. 12]);
    is_deeply(r->dim($m1)->values, [4, 3]);
    ok(r->is->matrix($m1));
  }
  
  # matrix - repeat
  {
    my $m1 = matrix(C_('1:3'), 3, 4);
    is_deeply($m1->values, [(1 .. 3) x 4]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }

  # matrix - repeat 2
  {
    my $m1 = matrix(C_('1:10'), 3, 4);
    is_deeply($m1->values, [1 .. 10, 1, 2]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }
  
  # matrix - repeat 3
  {
    my $m1 = matrix(0, 3, 4);
    is_deeply($m1->values, [(0) x 12]);
    is_deeply(r->dim($m1)->values, [3, 4]);
    ok(r->is->matrix($m1));
  }
}

# rownames and colnames
{
  # rownames and colnames - accessor
  {
    my $m1 = matrix(C_('1:6'), 2, 3);
    r->colnames($m1,c_(qw/c1 c2 c3/));
    is_deeply(r->colnames($m1)->values, [qw/c1 c2 c3/]);
    r->rownames($m1, c_(qw/r1 r2 r3/));
    is_deeply(r->rownames($m1)->values, [qw/r1 r2 r3/]);
  }

  # rownames and colnames - to_string
  {
    my $m1 = matrix(C_('1:6'), 2, 3);
    r->colnames($m1, c_(qw/c1 c2 c3/));
    r->rownames($m1, c_(qw/r1 r2 r3/));
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

# upper_tri
{
  # upper_tri - basic
  {
    my $x1 = matrix(C_('1:12'), 3, 4);
    my $x2 = r->lower_tri($x1);
    is_deeply($x2->values, [
      0,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0
    ]);
    is_deeply(r->dim($x2)->values, [3, 4]);
  }

  # upper_tri - diag = TRUE
  {
    my $x1 = matrix(C_('1:12'), 3, 4);
    my $x2 = r->lower_tri($x1, {diag => TRUE});
    is_deeply($x2->values, [
      1,
      1,
      1,
      0,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0
    ]);
    is_deeply(r->dim($x2)->values, [3, 4]);
  }
}

# upper_tri
{
  # upper_tri - basic
  {
    my $x1 = matrix(C_('1:12'), 3, 4);
    my $x2 = r->upper_tri($x1);
    is_deeply($x2->values, [
      0,
      0,
      0,
      1,
      0,
      0,
      1,
      1,
      0,
      1,
      1,
      1
    ]);
    is_deeply(r->dim($x2)->values, [3, 4]);
  }

  # upper_tri - diag = TRUE
  {
    my $x1 = matrix(C_('1:12'), 3, 4);
    my $x2 = r->upper_tri($x1, {diag => TRUE});
    is_deeply($x2->values, [
      1,
      0,
      0,
      1,
      1,
      0,
      1,
      1,
      1,
      1,
      1,
      1
    ]);
    is_deeply(r->dim($x2)->values, [3, 4]);
  }
}

# t
{
  # t - basic
  {
    my $m1 = matrix(C_('1:6'), 3, 2);
    my $m2 = r->t($m1);
    is_deeply($m2->values, [1, 4, 2, 5, 3, 6]);
    is_deeply(r->dim($m2)->values, [2, 3]);
  }
}

# rbind
{
  my $m1 = r->rbind(
    c_(1, 2, 3, 4),
    c_(5, 6, 7, 8),
    c_(9, 10, 11, 12)
  );
  is_deeply($m1->values, [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]);
  is_deeply(r->dim($m1)->values, [3, 4]);
}

# rowSums
{
  my $m1 = matrix(C_('1:12'), 4, 3);
  my $v1 = r->rowSums($m1);
  is_deeply($v1->values,[10, 26, 42]);
  is_deeply(r->dim($v1)->values, []);
}

# rowMeans
{
  my $m1 = matrix(C_('1:12'), 4, 3);
  my $v1 = r->rowMeans($m1);
  is_deeply($v1->values,[10/4, 26/4, 42/4]);
  is_deeply(r->dim($v1)->values, []);
}

# colSums
{
  my $m1 = matrix(C_('1:12'), 4, 3);
  my $v1 = r->colSums($m1);
  is_deeply($v1->values,[15, 18, 21, 24]);
  is_deeply(r->dim($v1)->values, []);
}

# colMeans
{
  my $m1 = matrix(C_('1:12'), 4, 3);
  my $v1 = r->colMeans($m1);
  is_deeply($v1->values,[15/3, 18/3, 21/3, 24/3]);
  is_deeply(r->dim($v1)->values, []);
}

# row
{
  my $m1 = matrix(C_('1:12'), 3, 4);
  my $m2 = r->row($m1);
  is_deeply($m2->values,[1,2,3,1,2,3,1,2,3,1,2,3]);
  is_deeply(r->dim($m2)->values, [3, 4]);
}

# col
{
  my $m1 = matrix(C_('1:12'), 3, 4);
  my $m2 = r->col($m1);
  is_deeply($m2->values,[1,1,1,2,2,2,3,3,3,4,4,4]);
  is_deeply(r->dim($m2)->values, [3, 4]);
}

# nrow and ncol
{
  my $m1 = matrix(C_('1:12'), 3, 4);
  is_deeply(r->nrow($m1)->values, [3]);
  is_deeply(r->ncol($m1)->values, [4]);
}

