use Test2::V0 -no_srand => 1;
use lib 'lib';

eval { require JSON; };
skip_all 'Test requires JSON' if $@;
eval { require Test::Script; Test::Script->import('script_compiles','script_runs') };
skip_all 'Test requires Test::Script' if $@;

opendir my $dir, 'examples' or die;
my @examples = sort grep /\.pl$/, readdir $dir;
closedir $dir;

foreach my $example (@examples)
{
  script_compiles("examples/$example");
  script_runs("examples/$example");
}

done_testing;
