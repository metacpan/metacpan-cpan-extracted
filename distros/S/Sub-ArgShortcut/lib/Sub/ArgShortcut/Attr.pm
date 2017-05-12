use 5.006;
use strict;
use warnings;

package Sub::ArgShortcut::Attr;
$Sub::ArgShortcut::Attr::VERSION = '1.021';
use Sub::ArgShortcut;
use Attribute::Handlers;

sub UNIVERSAL::ArgShortcut : ATTR(CODE) {
	my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;
	{ no warnings 'redefine'; *$symbol = argshortcut \&$referent; }
	return;
}

1;
