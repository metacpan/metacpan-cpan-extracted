use strict;
use warnings;

use FindBin;

use Test::More;
my $tests;

plan tests => $tests;

use Padre::Plugin::Vi::TabCompletition qw(clear_tab handle_tab set_original_cwd);


set_original_cwd($FindBin::Bin);


# if not prefix is given, show the available command
{
	my $value = handle_tab();
	is $value, 'e';

	$value = handle_tab();
	is $value, 'w';

	$value = handle_tab();
	is $value, 'e';

	$value = handle_tab( '', 0 );
	is $value, 'w';

	$value = handle_tab( '', 1 );
	is $value, 'e';

	BEGIN { $tests += 5; }
}

