# This code is part of Perl distribution OODoc version 3.04.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Export::JSON;{
our $VERSION = '3.04';
}

use parent 'OODoc::Export';

use strict;
use warnings;

use Log::Report  'oodoc';

use JSON   ();

#--------------------

sub new(%) { my $class = shift; $class->SUPER::new(serializer => 'json', @_) }

#--------------------

# Bleh: JSON has real true and false booleans :-(
sub boolean($) { $_[1] ? $JSON::true : $JSON::false }


sub write($$%)
{	my ($self, $output, $data, %args) = @_;

	my $fh;
	if($output eq '-')
	{	$fh = \*STDOUT;
	}
	else
	{	open $fh, '>:encoding(UTF-8)', $output
			or fault __x"cannot write output to {file}", file => $output;
	}

	my $json = JSON->new->pretty($args{pretty_print});
	$fh->print($json->encode($data));

	$output eq '-' || $fh->close
		or fault __x"write errors to {file}", file => $output;
}

1;
