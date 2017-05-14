package Myco::Foo;

###############################################################################
# $Id: entity.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Foo - a Myco entity class

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $obj = Myco::Foo->new;

  # Accessors.
  my $value = $obj->get_fooattrib;
  $obj->set_fooattrib($value);

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

Blah blah blah... Blah blah blah... Blah blah blah...
Blah blah blah blah blah... Blah blah...

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################


##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Myco::Entity);
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    #tangram => { table => '::SetTableName', },
#    ui => { displayname => 'fooattrib' }
  );

##############################################################################
# Function and Closure Prototypes
##############################################################################

##############################################################################
# Query Specifications (See Myco::Entity::Meta::Query)
##############################################################################

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=head2 fooattrib

 type: string   default: 'hello'

A whole lot of nothing

=cut

$md->add_attribute(name => 'fooattrib',
		   type => 'string',
		   synopsis => 'foo for one',
		   tangram_options => {init_default => 'hello'});

=head2 barattrib

 type: int   required: not undef

Almost, but not quite, something.

=cut

$md->add_attribute(name => 'barattrib',
		   type => 'string',
		   synopsis => 'foo for all',
#		   tangram_options => {required => 1},
		   values => [qw(red yellow black white)],
		   ui => {widget => [ 'radio_group', -rows => 2,
                                                     -columns => 2 ],
			  label => 'Pick one',
			 }
		  );


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 foometh

  Myco::Foo->foometh(attribute => value, ...)

blah blah blah

=cut

#sub foometh {}


=head2 barmeth

  $obj->barmeth(attribute => $value, ...)

blah blah blah

=cut

#sub barmeth {}


##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Foo::Test|Myco::Foo::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
