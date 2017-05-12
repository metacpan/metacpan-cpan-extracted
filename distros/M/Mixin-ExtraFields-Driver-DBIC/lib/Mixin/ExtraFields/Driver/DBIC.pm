use strict;
use warnings;
package Mixin::ExtraFields::Driver::DBIC;
{
  $Mixin::ExtraFields::Driver::DBIC::VERSION = '0.004';
}
use Mixin::ExtraFields::Driver 0.004 ();
use parent 'Mixin::ExtraFields::Driver';
# ABSTRACT: store Mixin::ExtraFields data in a DBIx::Class store

use Carp ();


sub from_args {
  my ($class, $arg) = @_;

  # schema will be either a DBIx::Class::Schema or a methodref which, called on
  # an object, returns a schema
  my $schema     = $arg->{schema} || sub { $_[1]->result_source->schema };
  my $rs_moniker = $arg->{rs_moniker}
    or Carp::croak "no rs_moniker provided to $class";

  my $self = {
    schema => $schema,
    rs_moniker   => $rs_moniker,
    id_column    => $arg->{id_column}    || 'object_id',
    name_column  => $arg->{name_column}  || 'extra_name',
    value_column => $arg->{value_column} || 'extra_value',
  };

  bless $self => $class;
}

sub id_column       { $_[0]->{id_column}    }
sub name_column     { $_[0]->{name_column}  }
sub value_column    { $_[0]->{value_column} }

sub _rs {
  my ($self, $object) = @_;

  if (eval { $self->{schema}->isa('DBIx::Class::Schema') }) {
    return $self->{schema}->resultset( $self->{rs_moniker} );
  } else {
    my $method = $self->{schema};
    return $self->$method($object)->resultset($self->{rs_moniker});
  }
}

sub exists_extra {
  my ($self, $object, $id, $name) = @_;

  my $count = $self->_rs($object)->count({
    $self->id_column   => $id,
    $self->name_column => $name,
  });

  return ! ! $count;
}

sub get_extra {
  my ($self, $object, $id, $name) = @_;

  my $row = $self->_rs($object)->find({
    $self->id_column   => $id,
    $self->name_column => $name,
  });

  return undef unless $row;

  my $value_column = $self->value_column;
  return $row->$value_column;
}

sub get_all_extra {
 
  Carp::confess 'get_all_extra is fatal outside of list context'
    unless wantarray;

 my ($self, $object, $id, $name) = @_;

  my @rows = $self->_rs($object)->search({
    $self->id_column => $id,
  });

  return unless @rows;

  my $name_column  = $self->name_column;
  my $value_column = $self->value_column;
  my @all = map { $_->$name_column, $_->$value_column } @rows;

  return @all;
}

sub get_all_extra_names {
  my ($self, $object, $id) = @_;

  Carp::confess 'get_all_extra_names is fatal outside of list context'
    unless wantarray;

  my %extra = $self->get_all_extra($object, $id);
  return keys %extra;
}

sub get_all_detailed_extra {
  my ($self, $object, $id) = @_;

  Carp::confess 'get_all_detailed_extra is fatal outside of list context'
    unless wantarray;

  my @rows = $self->_rs($object)->search({
    $self->id_column => $id,
  });

  my $name_column  = $self->name_column;
  my $value_column = $self->value_column;

  my %return;
  for my $row (@rows) {
    $return{ $row->name_column } = { value => $row->$value_column };
  }

  return %return;
}

sub set_extra {
  my ($self, $object, $id, $name, $value) = @_;

  my $id_column    = $self->id_column;
  my $name_column  = $self->name_column;
  my $value_column = $self->value_column;

  my $obj = $self->_rs($object)->update_or_create({
    $self->id_column    => $id,
    $self->name_column  => $name,
    $self->value_column => $value,
  });
}

sub delete_extra {
  my ($self, $object, $id, $name) = @_;

  $self->_rs($object)->search({
    $self->id_column   => $id,
    $self->name_column => $name,
  })->delete;
}

sub delete_all_extra {
  my ($self, $object, $id, $name) = @_;

  $self->_rs($object)->search({
    $self->id_column => $id,
  })->delete;
}

sub _setup_class {
  my ($self, $value, $arg) = @_;
  $value ||= {};

  Carp::croak("no table name supplied") unless $value->{table};

  $value->{pk_column}    ||= 'id';
  $value->{id_column}    ||= 'object_id';
  $value->{name_column}  ||= 'extra_name';
  $value->{value_column} ||= 'extra_value';

  my $target = $arg->{into};

  # ensure target isa DBIx::Class

  $target->load_components(qw(Core));

  $target->table($value->{table});

  $target->add_columns(
    $value->{pk_column} => {
      data_type   => 'int',
      is_nullable => 0,
      is_auto_increment => 1,
    },

    $value->{id_column} => {
      data_type   => 'int',
      is_nullable => 0,
    },

    $value->{name_column} => {
      data_type   => 'varchar',
      size        => 32,
      is_nullable => 0,
    },

    $value->{value_column} => {
      data_type   => 'varchar',
      size        => 64,
      is_nullable => 0,
    },
  );

  $target->set_primary_key($value->{pk_column});

  $target->add_unique_constraint(
    "$value->{id_column}_$value->{name_column}" => [
      $value->{id_column}, $value->{name_column}
    ],
  );

  return 1;
};

use Sub::Exporter -setup => {
  collectors => [ -setup => \'_setup_class' ],
};

1;

__END__

=pod

=head1 NAME

Mixin::ExtraFields::Driver::DBIC - store Mixin::ExtraFields data in a DBIx::Class store

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This class provides a driver for storing Mixin::ExtraFields data in
DBIx::Class storage.  You'll need to create a table resultsource for the
storage of entires and you'll need to use Mixin::ExtraFields in the class that
gets the extras.

So, you might create:

  package My::Schema::ObjectExtra;
  use Mixin::ExtraFields::Driver::DBIC -setup => { table => 'object_extras' };
  1;

...and elsewhere;

  package My::Schema::Object;
  use parent 'DBIx::Class';
  ...
  use Mixin::ExtraFields -fields => {
    driver => { class => 'DBIC', rs_moniker => 'ObjectExtra' }
  };

=head1 DRIVER ARGS

The following arguments may be provided when defining the driver when setting
up Mixin::ExtraFields:

  schema       - the schema for the DBIx::Class storage (see below)
  rs_moniker   - the moniker of the result source for extras
  id_column    - the name of the column that stores object ids
  name_column  - the name of the column that stores extra field names
  value_column - the name of the column that stores extra field values

C<schema> may be an actual DBIx::Class::Schema object or a coderef which, when
called on an object, returns a schema.  The default value assumes that objects
will be DBIx::Class::Row objects, and returns their schema.

=head1 SETUP ARGS

When using Mixin::ExtraFields::Driver::DBIC to set up a table result source,
the following values may be in the argument to C<-setup> in the import call:

  table        - (required) the name of the table in the storage
  id_column    - the name of the column that stores object ids
  name_column  - the name of the column that stores extra field names
  value_column - the name of the column that stores extra field values

=for Pod::Coverage   id_column
  name_column
  value_column

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
