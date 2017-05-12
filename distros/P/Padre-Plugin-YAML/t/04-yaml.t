use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;


use Test::More tests => 10;

BEGIN {
	use_ok('Padre',               '0.96');
	use_ok('Padre::Document',     '0.96');
	use_ok('Padre::Logger',       '0.96');
	use_ok('Padre::Plugin',       '0.96');
	use_ok('Padre::Task::Syntax', '0.96');
	use_ok('Padre::Unload',       '0.96');
	use_ok('Padre::Wx',           '0.96');
}

######
# let's check our subs/methods.
######

my @subs
	= qw( menu_plugins_simple padre_interfaces plugin_enable plugin_disable
	plugin_name registered_documents plugin_about
);

BEGIN {
	use_ok('Padre::Plugin::YAML', @subs);
}

can_ok('Padre::Plugin::YAML', @subs);

my @needs = Padre::Plugin::YAML::padre_interfaces();
cmp_ok(@needs % 2, '==', 0, 'plugin interface check');

done_testing();

__END__

