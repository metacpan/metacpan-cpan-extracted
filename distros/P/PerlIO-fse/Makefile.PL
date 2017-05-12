use strict;
use warnings;
use inc::Module::Install;

name 'PerlIO-fse';
all_from 'lib/PerlIO/fse.pm';

requires 'Encode';

build_requires 'ExtUtils::ParseXS';

test_requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		PerlIO-fse-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
