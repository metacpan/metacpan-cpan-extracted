use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

BEGIN {
	use_ok('Padre::Plugin::SpellCheck');
}

diag("Info: Testing Padre::Plugin::SpellCheck $Padre::Plugin::SpellCheck::VERSION");

done_testing();

__END__
