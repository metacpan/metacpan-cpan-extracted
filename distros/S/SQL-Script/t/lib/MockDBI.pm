package t::lib::MockDBI;

use strict;

use vars qw{@SQL};
BEGIN {
	@SQL = ();
}

sub isa {
	return 1;
}

sub new {
	bless { @_[1..-1] }, $_[0];
}

sub do {
	shift;
	push @SQL, [ @_ ];
}

1;
