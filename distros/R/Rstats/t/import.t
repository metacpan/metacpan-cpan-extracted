use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# c_
{
  my $v1 = c_(1, 2, 3);
  is_deeply($v1->values, [1, 2, 3]);
}

# C_
{
  my $v1 = C_('1:3');
  is_deeply($v1->values, [1, 2, 3]);
}

# array
{
  my $x1 = array(C_('1:12'), c_(4, 3));
  is_deeply($x1->values, [1 .. 12]);
  is_deeply(r->dim($x1)->values, [4, 3]);
}

# matrix
{
  my $m1 = matrix(C_('1:12'), 4, 3);
  is_deeply($m1->values, [1 .. 12]);
  is_deeply(r->dim($m1)->values, [4, 3]);
}

# i
{
  my $v1 = i_;
  is_deeply($v1->values, [{re => 0, im => 1}]);
}

# TRUE
{
  my $true = TRUE;
  is_deeply($true->values, [1]);
}

# FALSE
{
  my $false = FALSE;
  is_deeply($false->values, [0]);
}

# NA
{
  my $na = NA;
  is_deeply($na->values, [undef]);
}

# NaN
{
  my $nan = NaN;
  is_deeply($nan->values, ['NaN']);
}

# Inf
{
  my $inf = Inf;
  is_deeply($inf->values, ['Inf']);
}

# NULL
{
  my $null = NULL;
  is_deeply($null->values, []);
  is_deeply(r->dim($null)->values, []);
  is_deeply($null->get_type, 'NULL');
}

# r
{
  my $r = r;
  my $v1 = r->c_(1, 2, 3);
  is_deeply($v1->values, [1, 2, 3]);
}

