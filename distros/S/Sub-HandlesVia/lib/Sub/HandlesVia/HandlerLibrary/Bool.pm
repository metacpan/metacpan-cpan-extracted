use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Bool;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw( set unset toggle not reset );

sub set {
	handler
		name      => 'Bool:set',
		args      => 0,
		template  => '« !!1 »',
}

sub unset {
	handler
		name      => 'Bool:unset',
		args      => 0,
		template  => '« !!0 »',
}

sub toggle {
	handler
		name      => 'Bool:toggle',
		args      => 0,
		template  => '« !$GET »',
}

sub not {
	handler
		name      => 'Bool:not',
		args      => 0,
		template  => '!$GET',
}

sub reset {
	handler
		name      => 'Bool:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 0 },
}


1;
