package Parse::Functions::CSharp;

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
	return qr{
			/\*.+?\*/        # block comment
			|
			\/\/.+?$newline  # line comment
			|
			(?:^|$newline)   # text start or newline 
			\s*              
			(?:
			  (?: \[ [\s\w()]+ \]\s* )?  # optional annotations
			  (?:
				(?: public|protected|private|
				    abstract|static|sealed|virtual|override|
				    explicit|implicit|
				    operator|
				    extern)
				\s+
			  ){0,4}                     # zero to 2 method modifiers
			  (?: [\w\[\]<>,]+)          # return data type
			  \s+
			  (\w+)                      # method name
			  (?: <\w+>)?                # optional: generic type parameter
			  \s*
			  \(.*?\)                    # parentheses around the parameters
			)
	}sx;
}

1;

# Copyright 2008-2014 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

