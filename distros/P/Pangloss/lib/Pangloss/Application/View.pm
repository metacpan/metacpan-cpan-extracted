=head1 NAME

Pangloss::Application::View - current view of the application model.

=head1 SYNOPSIS

  use Pangloss::Application::View;
  my $view = new Pangloss::Application::View();

  # use it as a hash

=cut

package Pangloss::Application::View;

use strict;
use warnings::register;

use base qw( Pangloss::Object );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

1;

__END__

=head1 DESCRIPTION

Simple hash so we can put views in the store.

Currently we're using direct-variable access (ie: regular perl hash), eventually
these vars should live behind accessors.

ATM, L<Pangloss::Application::CollectionEditor> does most of the populating.

=head1 KNOWN KEYS

=over 4

=item errors

The list of error objects.

=item users_collection, languages_collection, categories_collection,
concepts_collection, terms_collection

The named L<Pangloss::Collection> object.

=item users, languages, categories, concepts, terms,

The list() of Pangloss objects in the named L<Pangloss::Collection> (this is
a handy shortcut for Petal templates).

=item user, category, concept, term, language

The I<currently selected> Pangloss object (ie: L<Pangloss::User>, etc).

The following keys are added as needed:

    error    - associated error object
    added    - true if the pangloss object was added
    removed  - true if the pangloss object was removed
    modified - true if the pangloss object was modified

=item add, get, modify, remove

The hash of actions performed, which is added to as needed:

    user       Pangloss::User
    language   Pangloss::Language
    concept    Pangloss::Concept
    category   Pangloss::Category
    term       Pangloss::Term

This lets you chain things like this:

    $view->add->{user}->{error}
    $view->add->{user}->{added}

And so on.

=back

=head1 NOTES

Everything here is cloned, so you don't have to worry about modifying the
original stored object (use L<Pangloss::Application> to do that).

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut

