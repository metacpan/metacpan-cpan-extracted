package Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.029';

use constant DESC => '<>/<<>>/readline/readdir/each result not explicitly assigned in while condition';
use constant EXPL => 'When used alone in a while condition, the <>/<<>> operator, readline, readdir, and each functions assign their result to $_, but do not localize it. Assign the result to an explicit lexical variable instead (my $line = <...>, my $dir = readdir ...)';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

my %bad_functions = (
	each		=> 1,
	readdir		=> 1,
	readline	=> 1,
);

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq 'while' or $elem eq 'for';
	
	my $next = $elem->snext_sibling || return ();
	
	# Detect for (;<>;)
	if ($elem eq 'for') {
		return () unless $next->isa('PPI::Structure::For');
		my @statements = grep { $_->isa('PPI::Statement') } $next->children;
		return () unless @statements >= 2;
		my $middle = $statements[1];
		return $self->violation(DESC, EXPL, $elem) if $middle->schildren
			and $middle->schild(0)->isa('PPI::Token::QuoteLike::Readline');
	} elsif ($elem eq 'while') {
		# while (<>) {} or ... while <>
		if ($next->isa('PPI::Structure::Condition')) {
			$next = $next->schild(0);
			return () unless defined $next and $next->isa('PPI::Statement');
			$next = $next->schild(0);
			return () unless defined $next;
		}
		
		return $self->violation(DESC, EXPL, $elem) if $next->isa('PPI::Token::QuoteLike::Readline');
		if ($next->isa('PPI::Token::Word') and exists $bad_functions{$next} and is_function_call $next) {
			return $self->violation(DESC, EXPL, $elem);
		}
	}
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment - Don't use while
with implicit assignment to $_

=head1 DESCRIPTION

The diamond operator C<E<lt>E<gt>> (or C<E<lt>E<lt>E<gt>E<gt>>), and functions
C<readline()>, C<readdir()>, and C<each()> are extra magical in a while
condition: if it is the only thing in the condition, it will assign its result
to C<$_>, but it does not localize C<$_> to the while loop. (Note, this also
applies to a C<for (;E<lt>E<gt>;)> construct.) This can unintentionally confuse
outer loops that are already using C<$_> to iterate. In addition, using C<$_>
at all means that your loop can get confused by other code which does not
politely localize its usage of the global variable. To avoid these
possibilities, assign the result of the diamond operator or these functions to
an explicit lexical variable.

  while (<$fh>) { ... }                   # not ok
  while (<<>>) { ... }                    # not ok
  ... while <STDIN>;                      # not ok
  for (;<>;) { ... }                      # not ok
  while (readline $fh) { ... }            # not ok
  while (readdir $dh) { ... }             # not ok

  while (my $line = <$fh>) { ... }        # ok
  while (my $line = <<>>) { ... }         # ok
  ... while $line = <STDIN>;              # ok
  for (;my $line = <>;) { ... }           # ok
  while (my $line = readline $fh) { ... } # ok
  while (my $dir = readdir $dh) { ... }   # ok

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
