package Myco::Base::Entity::SampleEntityAddress;

##############################################################################
# $Id: SampleEntityAddress.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
##############################################################################

=pod

=head1 NAME

Myco::Base::Entity::SampleEntityAddress - Myco Addresses.

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 SYNOPSIS

  use Myco::User;

  # Constructors.
  my $addr = Myco::Base::Entity::SampleEntityAddress->new;
  # See Myco::Base::Entity for more.

  # Instance Methods.
  my $key = $addr->get_key;
  $addr->set_key($key);
  my $street = $addr->get_street;
  $addr->set_street($street);
  my $city = $addr->get_city;
  $addr->set_city($city);
  my $state = $addr->get_state;
  $addr->set_state($state);
  my $zip = $addr->get_zip;
  $addr->set_zip($zip);
  my $country = $addr->get_country;
  $addr->set_country($country);

  $addr->save;
  $addr->destroy;

=head1 DESCRIPTION

Objects of this class represent addresses in Myco. In addition to the typical
address parts ach also has a value called "key". This value must be
unique across all adddresses for a given person, though different persons can
have the same key.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use strict;
use warnings;
use Myco::Exceptions;

##############################################################################
# Programmatic Dependences
use Myco::Constants;
use Locale::SubCountry;

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Myco::Base::Entity);
my $md = Myco::Base::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'address' },
    ui => {
	   displayname => 'key',
	   list => { layout => [qw(__DISPLAYNAME__ city state country)] },
	   view => { layout => [qw(street city state zip
				   country)] }
	  }
  );

##############################################################################
# Function and Closure Prototypes
##############################################################################
# None.

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant COUNTRY_CODES => scalar Myco::Constants->country_codes;
use constant LOCALE_US => scalar Locale::SubCountry->new('United States');
use constant LOCALE_Canada => scalar Locale::SubCountry->new('Canada');

##############################################################################
# Constructors
##############################################################################

=head1 CONSTRUCTORS

See L<Myco::Base::Entity>.

=cut


=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 4

=item

set

 $obj->set_attr($value);

This method sets the value of the "attr" attribute. These methods, implemented
by L<Class::Tangram|Class::Tangram>, perform data validation. If there is any
concern that the set method might be called with invalid data then the call
should be wrapped in an C<eval> block to catch exceptions that would result.

=item

get

 $value = $obj->get_attr;

This method returns the value of the "attr" attribute.

=back

A listing of available attributes follows:

=head2 key

 type: string(32)  default value: 'home'

A short descripter that uniquely describes an address on a per-person bases.
All addresses associated with a single person must have different keys, but
different people can have the same key. The key is stored internally in
lowercase, so key matches are case-insensitive.

=cut

$md->add_attribute( name => 'key',
                    type => 'string',
                    type_options => { string_length => 32 },
		    tangram_options => { sql => 'VARCHAR(32) NOT NULL',
					 required => 1,
					 init_default => 'home' },
                    ui => { options => { hidden => 1 } }
                  );

sub set_key { $_[0]->SUPER::set_key( lc $_[1] ) }

=head2 street

 type: string(159)

The street portion of the address. May be multiple lines by using new line
characters.

=cut

$md->add_attribute(name => 'street',
                   type => 'string',
                   type_options => { string_length => 159 },
		   ui => {
                          widget => [ 'textarea', -columns => 35, -rows => 1 ],
                          label => 'Street',
                         }
                  );


=head2 city

 type: string(128)

The address city.

=cut

$md->add_attribute( name => 'city',
                    type => 'string',
                    type_options => { string_length => 128 },
                    ui => {
                           widget => [ 'textfield', -size => 15, ],
                           label => 'City',
                          },
                  );


=head2 state

 type: string(2)

The address state or province.

=cut

# Remove 'MA' to put it up front. Word to my homies from da Bay State!
my %state_codes_hash = LOCALE_US->code_full_name_hash;
my %state_codes = map { $_ => 1 } LOCALE_US->all_codes;
delete $state_codes_hash{MA};
delete $state_codes{MA};
my @state_codes = keys %state_codes;

$md->add_attribute( name => 'state',
                    type => 'string',
                    type_options => { string_length => 64 },
                    values => [ '__select__',
				'__blank__',
                                ' ',
				'__blank__',
                                'MA',
				'__blank__',
                                @state_codes,
				'__blank__',
				LOCALE_Canada->all_codes,
				'__blank__',
				'__other__' ],
                    value_labels => { ' ' => 'NONE',
                                      MA => 'Massachusetts',
                                      %state_codes_hash,
                                      LOCALE_Canada->code_full_name_hash,
                                    },
                    ui => {
                           label => 'State/Province',
			  },
                  );



=head2 zip

 type: string(16)

The address postal code.

=cut

$md->add_attribute( name => 'zip',
                    type => 'string',
                    type_options => { string_length => 16 },
                    ui => {
                           label => 'Zip/Postal code',
                           widget => [ 'textfield', -size => 16, ],
			  },
                  );

=head2 country

 type: string(64)

The address country. preferrably specified as an ISO 3166-1 two-letter code.

=cut

$md->add_attribute( name => 'country',
                    type => 'string',
                    type_options => { string_length => 64 },
		    values => COUNTRY_CODES,
                    value_labels => { Myco::Constants->country_hash_by_code },
                    ui => {
                           options => { value_default => 'us' },
                           label => 'Country',
			  },
                  );


##############################################################################
$md->activate_class;

1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Myco::Base::Entity|Myco::Base::Entity>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<Lingua::Strfname|Lingua::Strname>.

=cut
