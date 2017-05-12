use strict;
use warnings;
use inc::Module::Install;

name 'Scalar-Alias';
all_from 'lib/Scalar/Alias.pm';

build_requires 'ExtUtils::ParseXS';

test_requires 'Test::More'      => 0.62;
test_requires 'Test::LeakTrace' => 0.09;

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		Scalar-Alias-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
