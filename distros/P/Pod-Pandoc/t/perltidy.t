use strict;
use Test::More;
use File::Find;

plan skip_all => 'these tests are for author testing'
  unless $ENV{AUTHOR_TESTING};

use_ok 'Test::PerlTidy';

foreach ( Test::PerlTidy::list_files('lib'), 'script/pod2pandoc' ) {
    ok Test::PerlTidy::is_file_tidy($_), $_;
}

done_testing;
