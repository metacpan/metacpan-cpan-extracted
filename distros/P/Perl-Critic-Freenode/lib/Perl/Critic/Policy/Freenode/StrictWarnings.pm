package Perl::Critic::Policy::Freenode::StrictWarnings;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use Perl::Critic::Utils::Constants qw(@STRICT_EQUIVALENT_MODULES @WARNINGS_EQUIVALENT_MODULES);
use parent 'Perl::Critic::Policy';
use version;

our $VERSION = '0.020';

use constant DESC => 'Missing strict or warnings';
use constant EXPL => 'The strict and warnings pragmas are important to avoid common pitfalls and deprecated/experimental functionality. Make sure each script or module contains "use strict; use warnings;" or a module that does this for you.';

sub supported_parameters {
	(
		{
			name        => 'extra_importers',
			description => 'Non-standard modules to recognize as importing strict and warnings',
			behavior    => 'string list',
		},
	)
}

sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

my @incomplete_importers = qw(common::sense sanity);

sub violates {
	my ($self, $elem) = @_;
	my $includes = $elem->find('PPI::Statement::Include') || [];
	
	# Add importers from Perl::Critic core
	my %strict_importers = map { ($_ => 1) } @STRICT_EQUIVALENT_MODULES;
	my %warnings_importers = map { ($_ => 1) } @WARNINGS_EQUIVALENT_MODULES;
	
	# Remove incomplete importers if added
	delete $strict_importers{$_} for @incomplete_importers;
	delete $warnings_importers{$_} for @incomplete_importers;
	
	# Add extra importers
	$strict_importers{$_} = $warnings_importers{$_} = 1 foreach keys %{$self->{_extra_importers}};
	
	my ($has_strict, $has_warnings);
	foreach my $include (@$includes) {
		if ($include->pragma) {
			$has_strict = 1 if $include->pragma eq 'strict';
			$has_warnings = 1 if $include->pragma eq 'warnings';
		}
		if ($include->type//'' eq 'use') {
			$has_strict = 1 if $include->version and version->parse($include->version) >= version->parse('v5.12');
			$has_strict = 1 if defined $include->module and exists $strict_importers{$include->module};
			$has_warnings = 1 if defined $include->module and exists $warnings_importers{$include->module};
		}
		return () if $has_strict and $has_warnings;
	}
	
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::StrictWarnings - Always use strict and
warnings, or a module that imports these

=head1 DESCRIPTION

The L<strict> and L<warnings> pragmas help avoid many common pitfalls such as
misspellings, scoping issues, and performing operations on undefined values.
Warnings can also alert you to deprecated or experimental functionality. The
pragmas may either be explicitly imported with C<use>, or indirectly through a
number of importer modules such as L<Moose> or L<strictures>. L<strict> is also
enabled automatically with a C<use> declaration of perl version 5.12 or higher.

  use strict;
  use warnings;

  use Moose;

  use 5.012;
  use warnings;

This policy is similar to the core policies
L<Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict> and
L<Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings>, but combines
them into one policy in the C<freenode> theme. The default modules recognized
as importing L<strict> and L<warnings> are defined by the same constants as the
core policies, L<Perl::Critic::Utils::Constants/"@STRICT_EQUIVALENT_MODULES">.
To define additional modules, see L</"CONFIGURATION">.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured to recognize additional modules as importers of
L<strict> and L<warnings>, by putting an entry in a C<.perlcriticrc> file like
this:

  [Freenode::StrictWarnings]
  extra_importers = MyApp::Class MyApp::Role

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
