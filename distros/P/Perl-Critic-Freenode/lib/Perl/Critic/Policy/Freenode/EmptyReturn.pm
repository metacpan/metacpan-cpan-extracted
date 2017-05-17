package Perl::Critic::Policy::Freenode::EmptyReturn;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';
use Perl::Critic::Freenode::Utils qw(is_empty_return is_structural_block);

our $VERSION = '0.020';

use constant DESC => 'return called with no arguments';
use constant EXPL => 'return with no arguments may return either undef or an empty list depending on context. This can be surprising for the same reason as other context-sensitive returns. Return undef or the empty list explicitly.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOWEST }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Sub' }

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
	
	# Return a violation for each empty return, if any non-empty return is present
	if ($returns and any { !is_empty_return($_) } @$returns) {
		return map { $self->violation(DESC, EXPL, $_) } grep { is_empty_return($_) } @$returns;
	}
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::EmptyReturn - Don't use return with no
arguments

=head1 DESCRIPTION

Context-sensitive functions, while one way to write functions that DWIM (Do
What I Mean), tend to instead lead to unexpected behavior when the function is
accidentally used in a different context, especially if the function's behavior
changes significantly based on context. This also can lead to vulnerabilities
when a function is intended to be used as a scalar, but is used in a list, such
as a hash constructor or function parameter list. C<return> with no arguments
will return either C<undef> or an empty list depending on context. Instead,
return the appropriate value explicitly.

  return;       # not ok
  return ();    # ok
  return undef; # ok

  sub get_stuff {
    return unless @things;
    return join(' ', @things);
  }
  my %stuff = (
    one => 1,
    two => 2,
    three => get_stuff(), # oops! function returns empty list if @things is empty
  );

Empty returns are permitted by this policy if the subroutine contains no
explicit return values, indicating it is intended to be used in void context.

=head1 CAVEATS

This policy currently only checks return statements in named subroutines,
anonymous subroutines are not checked. Also, return statements within blocks,
other than compound statements like C<if> and C<foreach>, are not considered
when determining if a function is intended to be used in void context.

Any non-empty return will cause empty returns within the same subroutine to
report violations, even though in list context, C<return> and C<return ()> are
functionally equivalent. It is recommended to explicitly specify an empty list
return with C<return ()> in a function that intends to return list context.

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
