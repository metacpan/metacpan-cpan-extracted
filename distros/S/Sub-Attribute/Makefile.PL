use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Sub/Attribute.pm';

use_ppport 3.19;
cc_warnings;

requires 'parent', 0.2;

test_requires 'Test::More'  => 0.62;
test_requires 'parent'      => 0.221;
test_requires 'MRO::Compat' => 0.09;

no_index directory => 'example';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

clean_files q(
	Sub-Attribute-* *.stackdump
	*.gcda *.gcno *.gcov
	nytprof *.out
	cover_db
);

WriteAll check_nmake => 0;
