package Myco::Schema;

###############################################################################
# $Id: Schema.pm,v 1.7 2006/03/31 19:12:57 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Schema - place to collect and manage tangram schema definitions

=cut

=head1 SYNOPSIS

 use Myco::Schema;

 # Use Myco::Schema to extract schema from all of the Myco entity classes

 my $schema;
 unless ($schema = Myco::Schema->schema) {
    # gotta compile it fresh
    Myco::Schema::mkschema();
    $schema = Myco::Schema->schema;
 }

See L<Myco> and L<Tangram::Storage|Tangram::Storage> for other miscellany.

=head1 DESCRIPTION

Myco::Schema collects and compiles tangram schema for all basic Myco framework
entity classes. It will also (in a future release) manage schema for entity
classes in the various Myco applications.

=cut


use Tangram;
use Tangram::Type::Dump::Perl;
use Tangram::Type::Date;
use Set::Object;

use Myco::Association;
use Myco::Entity::Event;
use Myco::Query;
use Myco::Entity::SampleEntity;
use Myco::Entity::SampleEntityAddress;
use Myco::Entity::SampleEntityBase;


my $dbschema;

sub mkschema {

  # start with the basic entity classes
  my $schema_classes =
    [
     'Myco::Query' => $Myco::Query::schema,
     'Myco::Association' => $Myco::Association::schema,
     'Myco::Entity::Event' => $Myco::Entity::Event::schema,

     'Myco::Entity::SampleEntity' =>
     $Myco::Entity::SampleEntity::schema,
			
     'Myco::Entity::SampleEntityAddress' =>
     $Myco::Entity::SampleEntityAddress::schema,
			
     'Myco::Entity::SampleEntityBase' =>
     $Myco::Entity::SampleEntityBase::schema,
    ];


  # now collect and compile ancillary schema from myco.conf
  use Myco::Config qw(:schema);

  if (SCHEMA_ENTITY_CLASSES) {
    my $classes_hash = SCHEMA_ENTITY_CLASSES;
    my $classes = Myco::Util::Misc->hash_with_no_values_to_array($classes_hash);
    for my $class (@$classes) {
      eval "use $class";
      my $this_class_schema = eval '$'.$class.'::schema';
      push @$schema_classes, ($class => $this_class_schema);
    }
  }

  $dbschema = Tangram::Schema->new({ classes =>  $schema_classes } );

}

sub schema { $dbschema };

1;
__END__

