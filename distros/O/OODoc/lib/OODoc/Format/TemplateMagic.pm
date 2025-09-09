# This code is part of Perl distribution OODoc version 3.03.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Format::TemplateMagic;{
our $VERSION = '3.03';
}


use strict;
use warnings;

use Log::Report 'oodoc';
use Scalar::Util  qw/blessed/;

#--------------------

sub zoneGetParameters($)
{	my ($self, $zone) = @_;
	my $param = blessed $zone ? $zone->attributes : $zone;
	$param =~ s/^\s+//;
	$param =~ s/\s+$//;
	length $param or return ();

	$param =~ m/[^\s\w]/
		or return split " ", $param;      # old style

	# new style
	my @params = split /\s*\,\s*/, $param;
	map split(/\s*\=\>\s*/, $_, 2), @params;
}

1;
