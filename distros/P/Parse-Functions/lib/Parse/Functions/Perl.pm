package Parse::Functions::Perl;

use 5.008;
use strict;
use warnings;
use Parse::Functions;

our $VERSION = '0.01';
our @ISA     = qw(Parse::Functions);

# TODO: the regex containing func|method should either reuse what
# Padre has in PPIx::EditorTools::Outline or copy the list from there
# for now let's leave it as it is and focus on improving the Outline
# code and then we'll see if we reuse or copy paste.

sub function_re {
	my ($self) = @_;

	my $newline = $self->newline;
	return qr{
		(?:
			${newline}__(?:DATA|END)__\b.*
			|
			$newline$newline=\w+.*?$newline\s*?$newline=cut\b(?=.*?(?:$newline){1,2})
			|
			(?:^|$newline)\s*
			(?:
				(?:sub|func|method|before|after|around|override|augment)\s+(\w+(?:::\w+)*)
				|
				\* (\w+(?:::\w+)*) \s*=\s* (?: sub\b | \\\& )
			)
		)
	}sx;
}

1;

# Copyright 2008-2014 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

