use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

BEGIN {
	use_ok('Padre::Plugin::YAML');
	use_ok('Padre::Plugin::YAML::Document');
	use_ok('Padre::Plugin::YAML::Syntax');
}

diag("Info: Testing Padre::Plugin::YAML $Padre::Plugin::YAML::VERSION");

done_testing();

__END__

