# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Parser;{
our $VERSION = '3.05';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use List::Util     qw/first/;
use Scalar::Util   qw/reftype/;

our %syntax_implementation = (
	markov => 'OODoc::Parser::Markov',
);

#--------------------

#--------------------

sub new(%)
{	my ($class, %args) = @_;

	$class eq __PACKAGE__
		or return $class->SUPER::new(%args);

	my $syntax = delete $args{syntax} || 'markov';
	my $pkg    = $syntax_implementation{$syntax} || $syntax;
	eval "require $pkg" or die $@;
	$pkg->new(%args);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	my $skip = delete $args->{skip_links} || [];
	my @skip = map { ref $_ eq 'REGEXP' ? $_ : qr/^\Q$_\E(?:\:\:|$)/ }
		ref $skip eq 'ARRAY' ? @$skip : $skip;

	$self->{skip_links} = \@skip;
	$self;
}

#--------------------

sub parse(@) {panic}

#--------------------

sub skipManualLink($)
{	my ($self, $package) = @_;
	(first { $package =~ $_ } @{$self->{skip_links}}) ? 1 : 0;
}


sub cleanupPod($$%) { ... }


sub cleanupHtml($$%) { ... }


sub formatReferTo($$) { ... }


sub finalizeManual($)
{	my ($self, $manual, %args) = @_;
	$self;
}

1;
