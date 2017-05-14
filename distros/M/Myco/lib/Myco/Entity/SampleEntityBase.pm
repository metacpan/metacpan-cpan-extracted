package Myco::Entity::SampleEntityBase;

###############################################################################
# $Id: SampleEntityBase.pm,v 1.5 2006/03/19 19:34:07 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::SampleEntityBase - a Myco entity class.

=head1 SYNOPSIS

 $obj = Myco::Entity::SampleEntityBase->new;

 # accessor usage
 $obj->set_fooattrib("hello");
 $value = $obj->get_fooattrib;

 $obj->foometh();

=head1 DESCRIPTION

This class, along with L<Myco::Entity::SampleEntity|Myco::Entity::SampleEntity>
and  L<Myco::Entity::SampleEntityAddress|Myco::Entity::SampleEntityAddress>,
provide the basis for all tests provided with the core myco system.

=cut

### Inheritance
use base qw(Myco::Entity);

my $metadata = Myco::Entity::Meta->new
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


$metadata->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::SampleEntityBase::Test|Myco::Entity::SampleEntityBase::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
