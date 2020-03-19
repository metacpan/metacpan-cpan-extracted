use Mojo::Base -strict;
use Test::More;
use Mojo::File 'tempdir';
use Mojo::Loader 'data_section';
use Mojo::Util 'tablify';

my $tmp = tempdir 'list.XXXXX', TMPDIR => 1;
my $all = data_section __PACKAGE__;
$tmp->child($_)->spurt("") for keys %$all;

my $files = $tmp->list->map(with_roles => '+Extension');
is_deeply $files->map('extension')->sort,
  ['.csv', '.csv', '.pl', '.t', '.tar.gz', '.txt'], 'ok';

is_deeply $files->map('moniker')->sort,
  ['check', 'data', 'further', 'script', 'test', 'wanted'], 'ok';

is_deeply $files->map('extension_parts')->sort(sub { $a->[0] cmp $b->[0] }),
  [['.csv'], ['.csv'], ['.pl'], ['.t'], ['.tar', '.gz'], ['.txt']], 'ok';

is_deeply $files->map('extension')->reduce(sub { $a->{$b}++; $a; }, {}),
  {'.csv' => 2, '.pl' => 1, '.t' => 1, '.tar.gz' => 1, '.txt' => 1},
  'count files by extension';

done_testing;

__DATA__
@@ check.t
@@ data.csv
@@ test.txt
@@ further.tar.gz
@@ wanted.csv
@@ script.pl
