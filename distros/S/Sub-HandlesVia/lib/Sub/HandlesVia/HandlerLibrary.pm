use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.016';

use Types::Standard qw( Any Item );

sub _type_inspector {
	my ($me, $type) = @_;
	if (!$type or $type == Any or $type == Item) {
		return {
			trust_mutated => 'always',
		};
	}
	
	return { trust_mutated => 'never' };
}

1;
