use Test::More tests => 1;
use Sort::strverscmp 'versionsort';

use strict;
use warnings;

{
  my @expected = qw(1.0.5 1.0.50 1.1);
  my @input = reverse @expected;
  my @got = versionsort(@input);
  is_deeply \@got, \@expected;
}
