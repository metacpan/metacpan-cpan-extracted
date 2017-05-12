use strict;
use warnings;

# Tests the use of ORLite::Migrate::Patch

# This isn't necesary except in this distribution
use File::Spec ();
use lib File::Spec->rel2abs(
	File::Spec->catdir(
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
	)
);

use ORLite::Migrate::Patch 0.03;

do(<<'END_SQL');
insert into foo values ( 3, 'baz' )
END_SQL
