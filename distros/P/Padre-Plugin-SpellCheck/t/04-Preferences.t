use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

BEGIN {
	use_ok( 'Padre::Unload', '0.96' );
	use_ok( 'Padre::Locale', '0.96' );
	use_ok( 'Padre::Util',   '0.96' );
	use_ok( 'Padre::Logger', '0.96' );
}

######
# let's check our subs/methods.
######

my @subs = qw( _display_dictionaries _local_aspell_dictionaries
	_local_hunspell_dictionaries _on_button_save_clicked _set_up new
	on_dictionary_chosen padre_locale_label
);

BEGIN {
	use_ok( 'Padre::Plugin::SpellCheck::Preferences', @subs );
}

can_ok( 'Padre::Plugin::SpellCheck::Preferences', @subs );

######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::SpellCheck::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Preferences');

done_testing();

__END__
