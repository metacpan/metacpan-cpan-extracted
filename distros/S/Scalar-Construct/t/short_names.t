use warnings;
use strict;

use Test::More tests => 13;

require_ok "Scalar::Construct";

foreach(
	[qw(ro constant)],
	[qw(rw variable)],
	[qw(ar aliasref)],
	[qw(ao aliasobj)],
) {
	my($alias, $orig) = @$_;
	no strict "refs";
	ok defined(&{"Scalar::Construct::$alias"});
	ok \&{"Scalar::Construct::$alias"} == \&{"Scalar::Construct::$orig"};
	use_ok "Scalar::Construct", $alias;
}

1;
