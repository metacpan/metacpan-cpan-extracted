#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

######
# let's check our subs/methods.
######

BEGIN {
	use_ok('Padre::Plugin::Autodia');
}

my @subs = qw(
	plugin_name
	plugin_enable
	padre_interfaces
	menu_plugins_simple
	draw_this_file
	draw_all_files
	_get_handler
	plugin_icon
	plugin_disable
	plugin_about
	class_dia
	project_jpg
	project_dia
	project_files
	on_finish
);

foreach my $subs (@subs) {
	can_ok('Padre::Plugin::Autodia', $subs);
}

done_testing();

__END__

