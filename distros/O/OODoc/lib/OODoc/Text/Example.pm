# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Text::Example;{
our $VERSION = '3.05';
}

use parent 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{type}    ||= 'Example';
	$args->{container} = delete $args->{container} or panic;
	$self->SUPER::init($args);
}

1;
