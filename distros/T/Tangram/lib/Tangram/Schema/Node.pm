package Tangram::Schema::Node;

# base class for Tangram::Class in Tangram::Schema (now
# Tangram::Schema::Class) and Tangram::Relational::Engine::Class

use strict;
sub get_bases
  {
	@{ shift->{BASES} }
  }

*direct_bases = \&get_bases;

sub get_specs
  {
	@{ shift->{SPECS} }
  }

sub for_conforming
{
   my ($class, $fun, @args) = @_;
   my $done = Set::Object->new;

   my $traverse;

   $traverse = sub {
	 my $class = shift;
	 return if $done->includes($class);
	 $done->insert($class);
	 $fun->($class, @args);

	 foreach my $derived (@{ $class->{SPECS} }) {
	   $traverse->($derived);
	 }
   };

   $traverse->($class);
 }

#---------------------------------------------------------------------
#  Tangram::Node->for_composing($closure, @_)
#
# Runs the given closure once for this class, and all its superclasses
# listed in the schema as $class->{BASES}
#
#---------------------------------------------------------------------
sub for_composing
{
   my ($class, $fun, @args) = @_;
   my $done = Set::Object->new;

   my $traverse;

   $traverse = sub {
	 my $class = shift;
	 return if $done->includes($class);
	 $done->insert($class);

	 foreach my $base (@{ $class->{BASES} }) {
	   $traverse->($base);
	 }

	 $fun->($class, @args);
   };

   $traverse->($class);
 }

sub get_exporter {
  my ($self, $context) = @_;

  return $self->{EXPORTER} ||= do {

	my (@export_sources, @export_closures);

	$self->for_composing
	    ( sub {
		  my ($part) = @_;

		  $context->{class} = $part;

		  for my $field ($part->direct_fields()) {
		      if (my $exporter = $field->get_exporter($context)) {
			  if (ref $exporter) {
			      push @export_closures, $exporter;
			      push @export_sources, 'shift(@closures)->($obj, $context)';
			  } else {
			      push @export_sources, $exporter;
			  }
		      }
		  }
	      } );

	my $export_source = join ",\n", @export_sources;
	my $copy_closures =
	    ( @export_closures ? ' my @closures = @export_closures;' : '' );

	# $Tangram::TRACE = \*STDOUT;

	$export_source = ("sub { my (\$obj, \$context) = \@_;"
			  ."$copy_closures\n$export_source }");

	print $Tangram::TRACE "Compiling exporter for $self->{name}...\n".($Tangram::DEBUG_LEVEL > 1 ? "$export_source\n" : "")
	    if $Tangram::TRACE;

	eval $export_source or die;
    }
}

sub get_importer {
  my ($self, $context) = @_;

  return $self->{IMPORTER} ||= do {
	my (@import_sources, @import_closures);

	$self->for_composing
	    ( sub {
		  my ($part) = @_;

		  $context->{class} = $part;

		  for my $field ($part->get_direct_fields()) {

		      my $importer = $field->get_importer($context)
			  or next;

		      if (ref $importer) {
			  push @import_closures, $importer;
			  push @import_sources, 'shift(@closures)->($obj, $row, $context)';
		      } else {
			  push @import_sources, $importer;
		      }
		  }
	      } );

	my $import_source = join ";\n", @import_sources;
	my $copy_closures =
	    ( @import_closures ? ' my @closures = @import_closures;' : '' );

	# $Tangram::TRACE = \*STDOUT;

	$import_source = ( "sub { my (\$obj, \$row, \$context) = \@_;"
			   ."(ref(\$row) eq 'ARRAY') and (\@\$row) or Carp::confess('no row!');\n"
			   ."# line 1 'tangram-$self->{table}-to-$self->{name}.pl'\n"
			   ."$copy_closures\n$import_source }" );

	print $Tangram::TRACE "Compiling importer for $self->{name}...\n".($Tangram::DEBUG_LEVEL > 1 ? "$import_source\n" : "")."\n"
	  if $Tangram::TRACE;

	# use Data::Dumper; print Dumper \@cols;
	eval $import_source or die;
  };
}

1;
