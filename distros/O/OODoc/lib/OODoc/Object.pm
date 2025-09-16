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

package OODoc::Object;{
our $VERSION = '3.04';
}


use strict;
use warnings;

use Log::Report    'oodoc';

use List::Util     qw/first/;

#--------------------

use overload
	'=='   => sub {$_[0]->unique == $_[1]->unique},
	'!='   => sub {$_[0]->unique != $_[1]->unique},
	'bool' => sub {1};

#--------------------

sub new(@)
{	my ($class, %args) = @_;
	my $self = (bless {}, $class)->init(\%args);

	if(my @missing = keys %args)
	{	error __xn"unknown object attribute '{names}' for {pkg}", "unknown object attributes for {pkg}: {names}",
			scalar @missing, names => \@missing, pkg => $class;
	}

	$self;
}

my $unique = 42;

sub init($)
{	my ($self, $args) = @_;

	# prefix with 'id', otherwise confusion between string and number
	$self->{OO_unique} = 'id' . $unique++;
	$self;
}

#--------------------

sub unique() { $_[0]->{OO_unique} }


my $index;  # still a global :-(  Set by ::Export
sub _publicationIndex($) { $index = $_[1] }

sub publish($)
{	my ($self, $args) = @_;
	$index->{$self->unique} = +{ id => $self->unique };
}

1;
