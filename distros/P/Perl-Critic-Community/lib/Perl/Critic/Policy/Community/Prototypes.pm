package Perl::Critic::Policy::Community::Prototypes;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = 'v1.0.1';

use constant DESC => 'Using function prototypes';
use constant EXPL => 'Function prototypes (sub foo ($@) { ... }) will usually not do what you want. Omit the prototype, or use signatures instead.';

sub supported_parameters {
	(
		{
			name        => 'signature_enablers',
			description => 'Non-standard modules to recognize as enabling signatures',
			behavior    => 'string list',
		},
	)
}

sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'community' }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem) = @_;

	# Check if signatures are enabled
	my $includes = $elem->find('PPI::Statement::Include') || [];
	foreach my $include (@$includes) {
	  next unless $include->type eq 'use';
	  return () if $include->pragma eq 'feature' and $include =~ m/\bsignatures\b/;
	  return () if $include->pragma eq 'experimental' and $include =~ m/\bsignatures\b/;
	  return () if $include->module eq 'Mojo::Base' and $include =~ m/-signatures\b/;
	  return () if $include->module eq 'Mojolicious::Lite' and $include =~ m/-signatures\b/;
	  return () if exists $self->{_signature_enablers}{$include->module};
	}
	
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

Perl::Critic::Policy::Community::Prototypes - Don't use function prototypes

=head1 DESCRIPTION

Function prototypes are primarily a hint to the Perl parser for parsing the
function's argument list. They are not a way to validate or count the arguments
passed to the function, and will cause confusion if used this way. Often, the
prototype can simply be left out, but see L<perlsub/"Signatures"> for a more
modern method of declaring arguments.

  sub foo ($$) { ... } # not ok
  sub foo { ... }      # ok
  use feature 'signatures'; sub foo ($bar, $baz) { ... }      # ok
  use experimental 'signatures'; sub foo ($bar, $baz) { ... } # ok

This policy is similar to the core policy
L<Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes>, but
additionally ignores files using the C<signatures> feature, and allows empty
prototypes and prototypes containing C<&>, as these are often useful for
structural behavior.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

=head1 CONFIGURATION

This policy can be configured to recognize additional modules as enabling the
C<signatures> feature, by putting an entry in a C<.perlcriticrc> file like
this:

  [Community::Prototypes]
  signature_enablers = MyApp::Base

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
