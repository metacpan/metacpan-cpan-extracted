use strict;
use warnings;
use inc::Module::Install 1.06;

all_from 'lib/ShipIt/Step/ChangeAllVersions.pm';

requires 'ShipIt' => 0.52;
requires 'parent';

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive 't';

auto_set_repository() if -d '.git';

clean_files qw(
	ShipIt-Step-ChangeAllVersions-* *.stackdump
	cover_db
	nytprof
	*.out
);

WriteAll check_nmake => 0;
