package Myco::Base::Entity::SampleEntity;

###############################################################################
# $Id: SampleEntity.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::SampleEntity - a Myco entity class.

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

 $obj = Myco::Base::Entity::SampleEntity->new;

 # accessor usage
 $obj->set_fooattrib("hello");
 $value = $obj->get_fooattrib;

 $obj->foometh();

=head1 DESCRIPTION

Blah blah blah... Blah blah blah... Blah blah blah...
Blah blah blah blah blah... Blah blah...

=cut

### Inheritance
use base qw(Myco::Base::Entity::SampleEntityBase);
my $metadata = Myco::Base::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'sample_entity',
                 bases => [ qw(Myco::Base::Entity::SampleEntityBase) ]
               },
    ui => { attribute_options => { foo => 'bar' },
            view => { fields => [qw( fish color chicken )] }
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
   table => 'base_entity_sampleentity',
   fields => {
	      string => {fooattrib => {},
			 name => {},
			},
	     },
  };


my $queries = sub {
    my ($md) = @_;
    $md->add_query
      ( name => 'default',
        description => 'the default query',
        remotes => { '$sample_base_entity_' => __PACKAGE__ },
        result_remote => '$sample_base_entity_',
        params => {
                   chk => ['$sample_base_entity_', 'chicken']
                  },
        filter => { parts => [ { remote => '$sample_base_entity_',
                                 attr => 'chicken',
                                 oper => '==',
                                 param => '$params{chk}' }
                             ]
                  },
      );
};

$metadata->add_attribute(name => 'fish',
			 type => 'string',
			 type_options => {string_length => 5},
			);

# These two for tests retrofitted from using Myco::Person
$metadata->add_attribute(name => $_, type => 'string') for qw(first last);

$metadata->add_attribute(name => 'chips',
			 type => 'int',
                         readonly => 1,
			);
$metadata->add_attribute(name => 'another_sample_entity',
			 type => 'ref',
                         tangram_options => { class => __PACKAGE__ }
			);

$metadata->add_attribute(name => 'address',
			 type => 'ref',
                         tangram_options => { class => __PACKAGE__.'Address' }
			);


# Override of superclass attrib
#$metadata->add_attribute(name => 'color',
#			 type => 'string',
#                         ui => { label => 'Gotcha!',
#                               }
#                        );

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

#$metadata->activate_class;
$metadata->activate_class( queries => $queries );

1;
__END__

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::SampleEntity::Test|Myco::Base::Entity::SampleEntity::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
