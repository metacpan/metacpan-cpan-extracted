#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;

######
# let's check our subs/methods.
######

BEGIN {
	use_ok('Padre::Plugin::XS');
}

my @subs = qw(
	plugin_name
	plugin_enable
	padre_interfaces
	menu_plugins_simple
	registered_documents
	plugin_icon
	plugin_disable
	plugin_about
	clean_dialog
);

foreach my $subs (@subs) {
	can_ok('Padre::Plugin::XS', $subs);
}

done_testing();

__END__

