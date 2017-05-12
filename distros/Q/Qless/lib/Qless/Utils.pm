package Qless::Utils;
use strict; use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(fix_empty_array);

# Because of how Lua parses JSON, empty arrays comes through as {}
sub fix_empty_array {
	my $val = shift;

	if (!$val) {
		return [];
	}

	if (ref $val eq 'HASH' && !scalar keys %{ $val }) {
		return [];
	}

	return $val;
}

1;
