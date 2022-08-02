package Perl::Critic::Community::Utils;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';

our $VERSION = 'v1.0.3';

our @EXPORT_OK = qw(is_empty_return is_structural_block);

my %modifiers = map { ($_ => 1) } qw(if unless while until for foreach when);
my %compound = map { ($_ => 1) } qw(if unless while until for foreach given);

sub is_empty_return {
	my $elem = shift;
	croak 'is_empty_return must be called with a PPI::Token::Word return element'
		unless blessed $elem and $elem->isa('PPI::Token::Word') and $elem eq 'return';
	
	my $next = $elem->snext_sibling || return 1;
	return 1 if $next->isa('PPI::Token::Structure') and $next eq ';';
	return 1 if $next->isa('PPI::Token::Word') and exists $modifiers{$next};
	
	return 0;
}

sub is_structural_block {
	my $elem = shift;
	croak 'is_structural_block must be called with a PPI::Structure::Block element'
		unless blessed $elem and $elem->isa('PPI::Structure::Block');
	
	if (my $parent = $elem->parent) {
		if ($parent->isa('PPI::Statement::Compound') and my $first = $parent->schild(0)) {
			return 1 if $first->isa('PPI::Token::Word') and exists $compound{$first};
		}
	}
	
	# TODO: Allow bare blocks or blocks with labels
	
	return 0;
}

1;

=head1 NAME

Perl::Critic::Community::Utils - Utility functions for the Community policy set

=head1 DESCRIPTION

This module contains utility functions for use in L<Perl::Critic::Community>
policies. All functions are exportable on demand.

=head1 FUNCTIONS

=head2 is_empty_return

 my $bool = is_empty_return($elem);

Tests whether a L<PPI::Token::Word> C<return> element represents an empty
C<return> statement. This function returns false for C<return()>.

=head2 is_structural_block

 my $bool = is_structural_block($elem);

Tests whether a L<PPI::Structure::Block> element is structural, and does not
introduce a new calling context. This function currently only returns true for
blocks in compound statements such as C<if> and C<foreach>, but may be extended
to cover more cases in the future.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
