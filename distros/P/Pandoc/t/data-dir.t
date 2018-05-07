use strict;
use Test::More;
use File::Spec::Functions 'catdir';
use Pandoc;

ok length pandoc_data_dir > length '/.pandoc', 'pandoc_data_dir';

done_testing;
