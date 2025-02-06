use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 9;
use Perlmazing qw(columnize);

{
  my @array = (1..9);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 4, 7], [2, 5, 8], [3, 6, 9]]', 'columnize returned the correct value';
}
{
  my @array = (1..10);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 5, 9], [2, 6, 10], [3, 7], [4, 8]]', 'columnize returned the correct value';
}
{
  my @array = (1..11);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 5, 9], [2, 6, 10], [3, 7, 11], [4, 8]]', 'columnize returned the correct value';
}
{
  my @array = (1..12);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 5, 9], [2, 6, 10], [3, 7, 11], [4, 8, 12]]', 'columnize returned the correct value';
}
{
  my @array = (1..13);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 6, 11], [2, 7, 12], [3, 8, 13], [4, 9], [5, 10]]', 'columnize returned the correct value';
}
{
  my @array = (1..12);
  my $number_of_columns = 4;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 4, 7, 10], [2, 5, 8, 11], [3, 6, 9, 12]]', 'columnize returned the correct value';
}
{
  my @array = (1..13);
  my $number_of_columns = 4;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 5, 9, 13], [2, 6, 10], [3, 7, 11], [4, 8, 12]]', 'columnize returned the correct value';
}
{
  my @array;
  my $number_of_columns = 4;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[]', 'columnize returned the correct value';
}
{
  my @array = (1, 2, undef, 4, undef, 6, undef, 8, 9);
  my $number_of_columns = 3;
  my @columns = columnize $number_of_columns, @array;
  my $result = dumped \@columns;
  is $result, '[[1, 4, undef], [2, undef, 8], [undef, 6, 9]]', 'columnize returned the correct value';
}



