use strict;
use warnings;
use Test::More;

if(eval q{ use Test::MinimumVersion; use Perl::MinimumVersion 1.37; 1 })
{
  all_minimum_version_ok('5.006');
}
else
{
  plan skip_all => 'test requires Test::MinimumVersion';
}
