use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

######
# let's check our subs/methods.
######

my @subs = qw( _count_utf_chars _init check get_suggestions new set_ignore_word);

BEGIN {
	use_ok( 'Padre::Plugin::SpellCheck::Engine', @subs );
}

can_ok( 'Padre::Plugin::SpellCheck::Engine', @subs );

done_testing();

__END__
