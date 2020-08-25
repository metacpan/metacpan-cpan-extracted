use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Code;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw( execute execute_method );

sub execute {
	handler
		name      => 'Code:execute',
		template  => '$GET->(@ARG)',
}

sub execute_method {
	handler
		name      => 'Code:execute_method',
		template  => '$GET->($SELF, @ARG)',
}

1;
