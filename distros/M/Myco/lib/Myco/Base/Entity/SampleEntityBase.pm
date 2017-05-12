package Myco::Base::Entity::SampleEntityBase;

###############################################################################
# $Id: SampleEntityBase.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::SampleEntityBase - a Myco entity class.

-- thingies that do such and such

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

 $obj = Myco::Base::Entity::SampleEntityBase->new;

 # accessor usage
 $obj->set_fooattrib("hello");
 $value = $obj->get_fooattrib;

 $obj->foometh();

=head1 DESCRIPTION


Blah blah blah... Blah blah blah... Blah blah blah...
Blah blah blah blah blah... Blah blah...

=cut

### Inheritance
use base qw(Myco::Base::Entity);

my $metadata = Myco::Base::Entity::Meta->new
  (
   name => __PACKAGE__,
   synopsis => 'FOO!',
   tangram => { table => 'sample_entity_base' },
   access_list => { rw => 'admin' },
   ui => {
          view => { fields => [qw( color chicken heybud )] }
         }
  );

### Module Dependencies and Compiler Pragma
use warnings;
use strict;

### Class Data


=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods.  Typical usage:

=over 3

=item *  Set attribute value

 $obj->set_attributeName($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data validation.
If there is any concern that the set method might be called with invalid data
then the call should be wrapped in an C<eval> block to catch exceptions
that would result.

=item *  Get attribute value

 $value = $obj->get_attributeName;

=back

Available attributes are listed below, using syntax borrowed from UML class
diagrams; for each showing the name, type, default initial value (if any), and,
following that, a description.

=over 4

=item -fooattrib: string = 'hello'

A whole lot of nothing

=item -barattrib: int

Almost, but not quite, something.  [required: not undef]

=back

=cut

### Object Schema Definition
our $schema =
  {
   fields => {
	      string => {heybud => {},
			},
	     },
  };


$metadata->add_attribute(name => 'color',
			 type => 'string',
                         synopsis => 'Gimme Color',
                         values => [qw(red green blue)],
                         ui => { label => 'BAR!',
                               }
                        );

$metadata->add_attribute(name => 'chicken',
			 type => 'int',
                         values => [0..5],
                         value_labels => {
                                          0 => 'Rhode Island Red',
                                          1 => 'Pullet',
                                          2 => 'Cornish',
                                          3 => 'Leghorn',
                                          4 => 'Hawk',
                                          5 => 'Kentucky Fried',
                                         },
                         ui => { widget => [ 'radio_group' ],
                                 label => 'Yummy'
                               }
                        );


### Methods

=head1 COMMON ENTITY INTERFACE

constructor, accessors, and other methods --  as inherited from
Myco::Base::Entity

=head1 ADDED CLASS / INSTANCE METHODS

=over 4

=item B<foometh>

 Class->foometh(attribute => value, ...)

blah blah blah

=cut

#sub foometh {}


=item B<barmeth>

 $instance->barmeth(attribute => $value, ...)

blah blah blah

=cut

#sub barmeth {}

$metadata->activate_class;

1;
__END__

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::SampleEntityBase::Test|Myco::Base::Entity::SampleEntityBase::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
