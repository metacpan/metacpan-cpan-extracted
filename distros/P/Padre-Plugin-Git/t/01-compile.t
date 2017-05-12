#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 14;

# Check dependencies that are not checked but Padre::Plugin::Git.pm itself
BEGIN {
	use_ok('Padre::Plugin::Git', '0.11');
	use_ok('CPAN::Changes',      '0.23');
	use_ok('Carp',               '1.32');
	use_ok('File::Slurp',        '9999.19');
	use_ok('File::Spec',         '3.4');
	use_ok('File::Which',        '1.09');
	use_ok('Padre',              '0.98');
	use_ok('Pithub',             '0.0102');
	use_ok('Try::Tiny',          '0.18');
	use_ok('constant',           '1.27');
	use_ok('parent',             '0.227');
	use_ok('Test::Deep',         '0.108');
	use_ok('Test::More',         '0.98');
	use_ok('Test::Requires',     '0.07');

}

diag("Info: Testing Padre::Plugin::Git $Padre::Plugin::Git::VERSION");

done_testing();

__END__

