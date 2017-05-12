package Parse::Functions::Python;

use 5.008;
use strict;
use warnings;
use Parse::Functions;

our $VERSION = '0.01';
our @ISA     = qw(Parse::Functions);

######################################################################

sub function_re {
	my ($self) = @_;

	my $newline = $self->newline;
	return qr/
		(?:
			\"\"\".*?\"\"\"
			|
			(?:^|$newline)\s*
			(?:
				(?:def)\s+(\w+)
				|
				(?:(\w+)\s*\=\s*lambda)
			)
		)
	/sx;
}

1;

# Copyright 2008-2014 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

