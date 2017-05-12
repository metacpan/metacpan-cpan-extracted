package Perl::Critic::Policy::Freenode::Prototypes;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';

our $VERSION = '0.019';

use constant DESC => 'Using function prototypes';
use constant EXPL => 'Function prototypes (sub foo ($@) { ... }) will usually not do what you want. Omit the prototype, or use signatures instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem) = @_;
	
	# Check if signatures are enabled
	my $includes = $elem->find('PPI::Statement::Include') || [];
	return () if any { $_->pragma eq 'feature' and m/\bsignatures\b/ } @$includes;
	
	my $prototypes = $elem->find('PPI::Token::Prototype') || [];
	my @violations;
	foreach my $prototype (@$prototypes) {
		# Empty prototypes and prototypes containing & can be useful
		next if $prototype->prototype eq '' or $prototype->prototype =~ /&/;
		push @violations, $self->violation(DESC, EXPL, $prototype);
	}
	
	return @violations;
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::Prototypes - Don't use function prototypes

=head1 DESCRIPTION

Function prototypes are primarily a hint to the Perl parser for parsing the
function's argument list. They are not a way to validate or count the arguments
passed to the function, and will cause confusion if used this way. Often, the
prototype can simply be left out, but see L<perlsub/"Signatures"> for a more
modern method of declaring arguments.

  sub foo ($$) { ... } # not ok
  sub foo { ... }      # ok
  use feature 'signatures'; sub foo ($bar, $baz) { ... } # ok

This policy is similar to the core policy
L<Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes>, but
additionally ignores files using the C<signatures> feature, and allows empty
prototypes and prototypes containing C<&>, as these are often useful for
structural behavior.

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
