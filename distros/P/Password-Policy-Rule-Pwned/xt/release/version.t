use strict;
use warnings;

use Test::More;
use Test::Version 'version_all_ok', {
	is_strict => 0,
	consistent => 1,
};
use Test::NewVersion;

version_all_ok ();
all_new_version_ok ();

done_testing;
