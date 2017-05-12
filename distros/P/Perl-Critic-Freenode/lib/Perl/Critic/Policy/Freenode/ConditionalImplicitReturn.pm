package Perl::Critic::Policy::Freenode::ConditionalImplicitReturn;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';
use Perl::Critic::Freenode::Utils qw(is_empty_return is_structural_block);

our $VERSION = '0.019';

use constant DESC => 'Subroutine may implicitly return a conditional statement';
use constant EXPL => 'When the last statement in a subroutine is a conditional, the return value may unexpectedly be the evaluated condition.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Sub' }

my %conditionals = map { ($_ => 1) } qw(if unless);

sub violates {
	my ($self, $elem) = @_;
	
	my $block = $elem->block || return ();
	my $returns = $block->find(sub {
		my ($elem, $child) = @_;
		# Don't search in blocks unless we know they are structural
		if ($child->isa('PPI::Structure::Block')) {
			return undef unless is_structural_block($child);
		}
		return 1 if $child->isa('PPI::Token::Word') and $child eq 'return';
		return 0;
	});
	
	# Check the last statement if any non-empty return is present
	if ($returns and any { !is_empty_return($_) } @$returns) {
		my $last = $block->schild(-1);
		# Check if last statement is a conditional
		if ($last and $last->isa('PPI::Statement::Compound')
		    and $last->schildren and exists $conditionals{$last->schild(0)}) {
			# Make sure there isn't an "else"
			unless (any { $_->isa('PPI::Token::Word') and $_ eq 'else' } $last->schildren) {
				return $self->violation(DESC, EXPL, $last);
			}
		}
	}
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::ConditionalImplicitReturn - Don't end a
subroutine with a conditional block

=head1 DESCRIPTION

If the last statement in a subroutine is a conditional block such as
C<if ($foo) { ... }>, and the C<else> condition is not handled, the subroutine
will return an unexpected value when the condition fails, and it is most likely
a logic error. Specify a return value after the conditional, or handle the
C<else> condition.

  sub { ... if ($foo) { return 1 } }                   # not ok
  sub { ... if ($foo) { return 1 } return 0 }          # ok
  sub { ... if ($foo) { return 1 } else { return 0 } } # ok

This policy only applies if the subroutine contains a return statement with an
explicit return value, indicating it is not intended to be used in void
context.

=head1 CAVEATS

This policy currently only checks for implicitly returned conditionals in named
subroutines, anonymous subroutines are not checked. Also, return statements
within blocks, other than compound statements like C<if> and C<foreach>, are
not considered when determining if a function is intended to be used in void
context.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
