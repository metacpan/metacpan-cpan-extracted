#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 19;

# Check dependencies that are not checked but  Test::Software::License.pm itself
BEGIN {
		use_ok('Padre::Plugin::Autodia', '0.04');
		use_ok('Autodia',                '2.14');
		use_ok('Carp',                   '1.32');
		use_ok('Cwd',                    '3.4');
		use_ok('Data::Printer',          '0.35');
		use_ok('File::Spec',             '3.4');
		use_ok('GraphViz',               '2.14');
		use_ok('Padre',                  '0.98');
		use_ok('Try::Tiny',              '0.18');
		use_ok('constant',               '1.27');
		use_ok('parent',                 '0.228');

		use_ok('Test::More',              '1.001002');
		use_ok('Test::Requires',          '0.07');
		use_ok('Test::Software::License', '0.002');

		use_ok('ExtUtils::MakeMaker',   '6.82');
		use_ok('File::Spec::Functions', '3.4');
		use_ok('List::Util',            '1.35');
		use_ok('Test::Pod',             '1.48');
		use_ok('Test::Pod::Coverage',   '1.08');
}

diag("Info: Testing Padre::Plugin::Autodia $Padre::Plugin::Autodia::VERSION"
	);

done_testing();

__END__

46:	To save a full .LOG file rerun with -g
