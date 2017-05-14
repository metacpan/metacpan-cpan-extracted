package Myco::Entity::SampleEntity;

###############################################################################
# $Id: SampleEntity.pm,v 1.6 2006/03/19 19:34:07 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::SampleEntity - a Myco entity class.

-- thingies that do such and such

=cut

=head1 SYNOPSIS

 $obj = Myco::Entity::SampleEntity->new;

 # accessor usage
 $obj->set_fooattrib("hello");
 $value = $obj->get_fooattrib;

=head1 DESCRIPTION

This class, along with L<Myco::Entity::SampleEntityBase|Myco::Entity::SampleEntityBase>
and  L<Myco::Entity::SampleEntityAddress|Myco::Entity::SampleEntityAddress>,
provide the basis for all tests provided with the core myco system.

=cut

### Inheritance
use base qw(Myco::Entity::SampleEntityBase);
my $metadata = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'sample_entity',
                 bases => [ qw(Myco::Entity::SampleEntityBase) ]
               },
    ui => { attribute_options => { foo => 'bar' },
            view => { fields => [qw( fish color chicken )] }
          }
  );

### Module Dependencies and Compiler Pragma
use warnings;
use strict;

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

$metadata->activate_class( queries => $queries );

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::SampleEntity::Test|Myco::Entity::SampleEntity::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
