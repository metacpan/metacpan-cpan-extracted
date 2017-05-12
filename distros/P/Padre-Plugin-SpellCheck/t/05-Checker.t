use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

BEGIN {
	use_ok( 'Padre::Unload', '0.96' );
	use_ok( 'Padre::Logger', '0.96' );
}

######
# let's check our subs/methods.
######

my @subs = qw( _next _on_ignore_all_clicked _on_ignore_clicked
	_on_replace_all_clicked _on_replace_clicked _replace _update
	new padre_locale_label _set_up
);

BEGIN {
	use_ok( 'Padre::Plugin::SpellCheck::Checker', @subs );
}

can_ok( 'Padre::Plugin::SpellCheck::Checker', @subs );

######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::SpellCheck::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Checker');

done_testing();

__END__

