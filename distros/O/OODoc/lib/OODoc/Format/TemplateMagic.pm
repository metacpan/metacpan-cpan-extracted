# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Format::TemplateMagic;{
our $VERSION = '3.05';
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
