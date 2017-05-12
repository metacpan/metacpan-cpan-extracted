=head1 NAME

Pangloss - a multilingual web-based glossary.

=head1 SYNOPSIS

  use Pangloss;

  # there's much more to it than that, of course...

=cut

package Pangloss;

use 5.008;

use strict;
use warnings::register;

# pre-load modules:
use Error;
use Pixie;
use Pangloss::Config;
use Pangloss::Application;

# hard-code version temporarily while we try & resolve a CPAN indexing problem
#our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $VERSION  = '0.05_01';
our $REVISION = (split(/ /, ' $Revision: 1.12 $ '))[2];

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Pangloss is a I<terminology management system> who's goal is to help translators
produce consistent translations of common terms across multiple languages.  The
system allows users to search through and manage terms and their translations.

There are 4 main types of users:

=over 2

=item Administrators

Admins can create, remove, or modify user accounts, languages, categories,
concepts and terms.

=item Translators

Translators can submit & modify term translations for a given concept.

=item Proofreaders

Proofreaders can accept/reject/etc. term translations by modifying a term's
status.

=item Generic users

Other users can search through the terms, but cannot modify any content.

=back

=head1 SYSTEM OVERVIEW

Pangloss can be broken down into these parts:

=head2 The Application Model

In MVC terms, L<Pangloss::Application> and its sub-components form the I<model>
of the system.  It includes exception-handling and validation code for
collections of the following objects:

=over 4

=item *
L<Pangloss::User>

=item *
L<Pangloss::Language>

=item *
L<Pangloss::Category>

=item *
L<Pangloss::Concept>

=item *
L<Pangloss::Term>

=back

Any action by the application classes results in a view of the system
represented by a L<Pangloss::Application::View>.

=head2 The Web Application

L<Pangloss::WebApp> acts as the I<controller> of the system.  It takes in a
request and passes it through a L<Pipeline> of modules that talk to the
L<Pangloss::Application> to figure out an appropriate response.  Most of the
so-called I<business logic> sits at this level.

By default L<Petal> templates are used to present the application I<view> to
the user.

L<Pangloss::WebApp> is configured by environment variables passed to
L<Pangloss::Config>. The controller is defined by a L<Pipeline::Config> file.

=head2 The Shell

Pangloss has an off-line administration tool, L<pg_admin>.

=head1 INSTALLATION

For detailed installation instructions, see L<Pangloss::Install> or the INSTALL
file.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 COPYRIGHT

Copyright (c) 2003, Quiup Ltd.

This module is free software; you can redistribute it or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

L<Pangloss::Config>, L<Pangloss::Application>

L<OpenFrame>, L<Pixie>

Pangloss mailing list:
L<http://www.email-lists.org/mailman/listinfo/pangloss>

=cut

