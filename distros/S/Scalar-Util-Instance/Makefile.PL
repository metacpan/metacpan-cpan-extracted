use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Scalar/Util/Instance.pm';

use_ppport 3.19;
cc_warnings;

requires 'MRO::Compat' if $] < 5.010;

test_requires 'Test::More'       => 0.80;
test_requires 'Test::Exception', => 0.27;

tests 't/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
	Scalar-Util-Instance-* *.stackdump
	*.gcda *.gcno *.gcov
	nytprof *.out
	cover_db
);

WriteAll check_nmake => 0;

