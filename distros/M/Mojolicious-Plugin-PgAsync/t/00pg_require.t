use Mojo::Base -strict;

use Test::More;

BEGIN {
	use_ok('Mojolicious')  or BAIL_OUT 'Cannot continue without Mojolicious';
	use_ok('DBI') or BAIL_OUT 'Cannot continue without DBI';
	use_ok('DBD::Pg') or BAIL_OUT 'Cannot continue without DBD::Pg';
}

done_testing();

