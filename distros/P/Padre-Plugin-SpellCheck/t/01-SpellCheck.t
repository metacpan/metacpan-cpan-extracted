use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;

BEGIN {
	use_ok( 'Padre',                 '0.96' );
	use_ok( 'Padre::Plugin',         '0.96' );
	use_ok( 'Padre::Unload',         '0.96' );
	use_ok( 'Padre::Locale',         '0.96' );
	use_ok( 'Padre::Logger',         '0.96' );
	use_ok( 'Padre::Wx',             '0.96' );
	use_ok( 'Padre::Wx::Role::Main', '0.96' );
	use_ok( 'File::Which',           '1.09' );
}

######
# let's check our subs/methods.
######

my @subs = qw( _config clean_dialog event_on_context_menu menu_plugins
	padre_interfaces plugin_disable plugin_enable plugin_icon
	plugin_name plugin_preferences spell_check
);

BEGIN {
	use_ok( 'Padre::Plugin::SpellCheck', @subs );
}

can_ok( 'Padre::Plugin::SpellCheck', @subs );

is( Padre::Plugin::SpellCheck::plugin_name(), 'Spell Checker', 'plugin name check' );

my @needs = Padre::Plugin::SpellCheck::padre_interfaces();
cmp_ok( @needs % 2, '==', 0, 'plugin interface check' );

######
# let's check our lib's are here.
######
my $test_object;

# require Padre::Plugin::SpellCheck::Preferences;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Preferences');

require Padre::Plugin::SpellCheck::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Preferences');

# require Padre::Plugin::SpellCheck::Engine;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Engine');

# require Padre::Plugin::SpellCheck::Checker;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Checker');

require Padre::Plugin::SpellCheck::FBP::Checker;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Checker');

done_testing();

__END__
