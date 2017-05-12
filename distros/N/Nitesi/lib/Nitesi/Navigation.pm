package Nitesi::Navigation;

use strict;
use warnings;

use Moo;
use Sub::Quote;

=head1 NAME

Nitesi::Navigation - Navigation class for Nitesi Shop Machine

=head1 DESCRIPTION

Generic navigation class for L<Nitesi>.

=head2 NAVIGATION

A navigation entity has the following attributes:

=over 4

=item code

Unique identifier for the navigation entity.

=item uri

Navigation URI.

=item name

Navigation name.

=item description

Navigation description.

=item template

Template used for this navigation entity.

=item language

Language of this navigation entity.

=item alias

Original navigation entity for language specific entities.

=item priority

The priority is used for sort navigation
entities.

=item inactive

Inactive Navigations are excluded from search results and
category listings.

=item entered

Creation date and time for this navigation object.

=back

=cut

has code => (
    is => 'rw',
);

has type => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 'category';},
);

has scope => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return '';},
    );

has name => (
    is => 'rw',
);

has description => (
    is => 'rw',
);

has template => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return '';},
);

has language => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return '';},
);

has alias => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

has parent => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
    );

has priority => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

has inactive => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

has entered => (
    is => 'rw',
    lazy => 1,
    );

has uri => (
    is => 'rw',
    lazy => 1,
    builder => '_build_uri',
);

=head1 METHODS

=head2 api_attributes

API attributes for navigation class.

=cut

has api_attributes => (
    is => 'rw',
);

=head2 api_info

API information for navigation class.

=cut

sub api_info {
    my $self = shift;

    return {base => __PACKAGE__,
            table => 'navigation',
            key => 'code',
            attributes => $self->api_attributes,
            assign => {'Nitesi::Product' => {
                table => 'navigation_products',
                key => [qw/sku navigation/]}
            },
    };
};

sub _build_uri {
    my $self = shift;

    return $self->clean_uri;
}

=head2 clean_uri

Retrieve clean URI for this navigation object.

=cut

sub clean_uri {
    my $self = shift;
    my $name = $self->name;

    $name =~ s/\s/-/g;
    $name =~ s/[^\w-]//g;
    $name =~ s/-+/-/g;
    $name =~ s/-$//;

    return $name;
}

=head2 move

Move category to a new parent.

=cut

sub move {
    my ($self, $new_parent) = @_;

    $self->parent($new_parent);
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
