package Nitesi::Address;

use Moo;
use Sub::Quote;

=head1 NAME

Nitesi::Address - Address class for Nitesi Shop Machine

=head1 ATTRIBUTES

=head2 aid

Adress identifier.

=cut

has aid => (
    is => 'rw',
);

=head2 uid

User identifier for this address.

=cut

has uid => (
    is => 'rw',
);

=head2 type

Address type (shipping, billing, ...).

=cut

has type => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return '';},
);

=head2 first_name

First name for this address.

=cut

has first_name => (
    is => 'rw',
);

=head2 last_name

Last name for this address.

=cut

has last_name => (
    is => 'rw',
);

=head2 company

Company name for this address (optional).

=cut

has company => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{"";},
    );

=head2 street_address

Street address.

=cut

has street_address => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return '';},
);

=head2 zip

Zip resp. postal code for this address.

=cut

has zip => (
    is => 'rw',
);

=head2 city

City for this address.

=cut

has city => (
    is => 'rw',
);

=head2 phone

Phone number for this address.

=cut

has phone => (
    is => 'rw',
);

=head2 state_code

State code for this address, e.g. FL for Florida.

=cut

has state_code => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

=head2 country_code

Country code for this address, e.g. DE for Germany.

=cut

has country_code => (
    is => 'rw',
);

=head2 created

Date and time of address creation.

=cut

has created => (
    is => 'rw',
);

=head2 modified

Date and time of last modification of this address.

=cut

has modified => (
    is => 'rw',
);

=head1 METHODS

=head2 api_attributes

API attributes for address class.

=cut

has api_attributes => (
    is => 'rw',
);

=head2 api_info

Returns API information for adress object.

=cut

sub api_info {
    my $self = shift;

    return {base => __PACKAGE__,
            table => 'addresses',
            attributes => $self->api_attributes,
            key => 'aid',
    };
};

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
