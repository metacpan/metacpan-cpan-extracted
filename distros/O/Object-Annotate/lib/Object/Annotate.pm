use warnings;
use strict;
package Object::Annotate;
# ABSTRACT: mix in logging-to-database to objects (deprecated)
$Object::Annotate::VERSION = '0.025';
use Carp ();
use UNIVERSAL::moniker 0.01;

#pod =head1 SYNOPSIS
#pod
#pod B<Achtung!>  This library was an experiment.  It failed.  Consider using
#pod L<Mixin::ExtraFields> instead.
#pod
#pod   package Your::Class;
#pod   use Object::Annotate annotate => { dsn => '...', table => 'notes' };
#pod
#pod   ...
#pod
#pod   my $object = Your::Class->new( ... );
#pod   $object->annotate({ event => "created", comment => "(as example)" });
#pod
#pod =head1 DESCRIPTION
#pod
#pod Object::Annotate is a mixin that provides any class with method for storing
#pod and retrieving notes about its objects.  It can also produce objects which
#pod exist only to store annotations about abstract (uninstantiated) objects,
#pod procedures, or concepts.
#pod
#pod =head1 USAGE
#pod
#pod To mix Object::Annotate into a class, just C<use> it.  To create a classless
#pod annotator object, use Object::Annotate's C<new> method.  Both of these usages
#pod accept the same arguments:
#pod
#pod   db        - options for the database in which notes are stored; a hashref:
#pod
#pod     dsn       - the DSN to pass to Class::DBI to create a connection
#pod     user      - the username to use in connecting to the database
#pod     pass      - the password to use in connecting to the database
#pod     table     - the table in which annotations are stored
#pod     sequence  - if given, the Class::DBI table's primary key values comes from
#pod                 this sequence; see L<Class::DBI> for more information
#pod
#pod   columns   - columns for the annotation table
#pod   obj_class - the class name to use for annotations for this class
#pod               (defaults to Class->moniker, see UNIVERSAL::moniker)
#pod   id_attr   - the object attribute to use for "id"; called as a method
#pod               if it's a scalar ref, it's de-ref'd and used as a constant string
#pod
#pod =cut

# We'll store the constructed Class::DBI subclasses here.
# $class_for->{ $dsn }->{ $table } = $class
my $class_for = {};

# We'll keep a counter, here, to use to form unique class names.
my $current_suffix = 0;

# The "id" column isn't here because we want it first, always.
my %note_columns = (
  mandatory => [ qw(class object_id created) ],
  # I plan to use these values in the future. -- rjbs, 2006-01-13
  # default   => [ qw(event attr old_val new_val via comment expire_time) ],
  default   => [ qw(event attr old_val new_val via comment expire_time) ],
);

use Sub::Exporter 0.92 -setup => {
  groups => { annotator => \&setup_class },
};

#pod =head2 new
#pod
#pod You can use the C<new> method to create a singularity -- an object that can
#pod annotate as if it was of a class that used Object::Annotate, but is of its own
#pod unique class.
#pod
#pod   my $notepad = Object::Annotate->new({ db => { ... } });
#pod
#pod =cut

sub new {
  my ($self, $arg) = @_;
  my $class = (ref $self) ? ref $self : $self;

  my $target
    = sprintf '%s::Singularity::0x%08x', $class, ++$current_suffix;

  $self->setup_class($target, $arg);

  my $singularity = \do { undef };
  bless $singularity => $target;
}

#pod =head1 METHODS
#pod
#pod These methods are not provided by Object::Annotate, but are installed into
#pod classes that use Object::Annotate.
#pod
#pod =head2 annotations_class
#pod
#pod   my $annotations_class = Your::Class->annotations_class;
#pod
#pod This method returns the name of the automatically constructed class that
#pod handles annotations for the class or object on which it is installed.
#pod
#pod =head2 annotate
#pod
#pod   $object->annotate({
#pod     event => 'update',
#pod     attr  => 'priority',
#pod     old_val => 1,
#pod     new_val => 3,
#pod   });
#pod
#pod This method creates an annotation for the object on which it is called.
#pod
#pod =head2 search_annotations
#pod
#pod   # search all annotations for this class
#pod   my @notes = Class->search_annotations({ event => 'explosion' });
#pod
#pod   # searches only annotations for this object
#pod   my @notes = $object->search_annotations({ event => 'explosion' });
#pod
#pod This method searches through the annotations for a class or an object, using
#pod the Class::DBI C<search> method.
#pod
#pod =cut

#pod =head1 INTERNALS
#pod
#pod =head2 setup_class
#pod
#pod   Object::Annotate->setup_class('annotator', \%arg, \%col);
#pod
#pod This method does the heavy lifting needed to turn the class named by C<$target>
#pod into one that does annotation.  It is a group generator as described in
#pod L<Sub::Exporter>.
#pod
#pod =cut

sub setup_class {
  my ($self, $name, $arg, $col) = @_;

  $arg->{db}{dsn}   ||= $self->default_dsn;
  $arg->{db}{table} ||= $self->default_table;

  $arg->{db}{user}  ||= $self->default_user;
  $arg->{db}{pass}  ||= $self->default_pass;

  $arg->{db}{sequence} ||= $self->_default_sequence;

  if ($arg->{noun} xor $arg->{verb}) {
    Carp::croak 'you must supply either both or neither "noun" and "verb"';
  } elsif (not ($arg->{noun} or $arg->{verb})) {
    @$arg{qw(noun verb)} = qw(annotations annotate);
  }

  my $class     = $self->class_for($arg);

  my $obj_class = $arg->{obj_class};

  my %build_option = (
    obj_class => $obj_class,
    id_attr   => $arg->{id_attr} || 'id',

    noun => $arg->{noun},
    verb => $arg->{verb},
  );

  my $annotator = $self->build_annotator({
    %build_option,
    columns   => $arg->{columns},
    set_time  => ($arg->{db}{dsn} && (scalar $arg->{db}{dsn} =~ /SQLite/)),
  });

  my $return = {
    "$arg->{noun}_class"  => sub { $class },
    $arg->{verb}          => $annotator,
    "search_$arg->{noun}" => $self->build_searcher(\%build_option),
  };
}

#pod =head2 class_for
#pod
#pod   my $class = Object::Annotate->class_for(\%arg);
#pod
#pod This method returns the class to use for the described database and table,
#pod constructing it (see C<L</construct_class>>) if needed.
#pod
#pod Valid arguments are (for all, see the L</USAGE> section): dsn, table, db_user,
#pod db_pass, sequence
#pod
#pod See the L</USAGE> section, above, for information on these arguments, which
#pod typically are passed along by the import routine.
#pod
#pod =cut

sub class_for {
  my ($self, $arg) = @_;

  my $dsn   = $arg->{db}{dsn};
  my $table = $arg->{db}{table};

  my $user  = $arg->{db}{user};
  my $pass  = $arg->{db}{pass};

  # Try to find an already-constructed class.
  my $class = ! $arg->{extra_setup}
           && exists $class_for->{ $dsn }
           && exists $class_for->{ $dsn }->{ $table }
           && $class_for->{ $dsn }->{ $table };

  return $class if $class;

  # If we have no class built for this combination, build it.
  $class = $self->construct_cdbi_class({
    dsn      => $dsn,
    user     => $user,
    pass     => $pass,
    table    => $table,
    columns  => $arg->{columns},
    sequence => $arg->{db}{sequence},
    base_class => $arg->{base_class},
  });

  $arg->{extra_setup}->($class) if $arg->{extra_setup};

  return $class;
}

#pod =head2 default_dsn
#pod
#pod =head2 default_table
#pod
#pod =head2 default_user
#pod
#pod =head2 default_pass
#pod
#pod These methods return the default database settings to use if none is specified
#pod when importing Object::Annotate.  The built-in behavior is to return the
#pod OBJ_ANNOTATE_DSN, OBJ_ANNOTATE_TABLE, etc. environment variables.
#pod
#pod =head2 default_base_class
#pod
#pod This method returns the class from which the annotator subclass will inherit.
#pod It defaults to Class::DBI.
#pod
#pod =cut

sub default_dsn   { $ENV{OBJ_ANNOTATE_DSN};   }
sub default_table { $ENV{OBJ_ANNOTATE_TABLE}; }
sub default_user  { $ENV{OBJ_ANNOTATE_USER}; }
sub default_pass  { $ENV{OBJ_ANNOTATE_PASS}; }
sub default_base_class  { 'Class::DBI' }

sub _default_sequence {  }

#pod =head2 construct_cdbi_class
#pod
#pod   my $new_class = Object::Annotate->construct_cdbi_class(\%arg);
#pod
#pod This method sets up a new Class::DBI subclass that will store in the database
#pod described by the arguments.
#pod
#pod Valid arguments are:
#pod
#pod   dsn     - the dsn for the database in which to store
#pod   user    - the database user as whom to connect
#pod   pass    - the database password
#pod   table   - the table in which to store annotations
#pod   columns - the extra columns for the table
#pod   base_class - class from which the new class inherits (default: Class::DBI)
#pod
#pod =cut

sub construct_cdbi_class {
  my ($class, $arg) = @_;

  my $new_class
    = sprintf '%s::Construct::0x%08x', __PACKAGE__, ++$current_suffix;

  $arg->{base_class} ||= $class->default_base_class;

  eval "require $arg->{base_class};" or die $@;
  do {
    no strict 'refs';
    @{$new_class . '::ISA'} = $arg->{base_class};
  };

  if ($arg->{dsn}) {
    $new_class->connection($arg->{dsn}, $arg->{user}, $arg->{pass});
  }

  $new_class->table($arg->{table});

  my @columns = @{ $note_columns{mandatory} };
  my @extra_columns = @{ $arg->{columns} || $note_columns{default} };
  push @columns, @extra_columns;

  $new_class->columns(All => ('id', @columns));

  $new_class->sequence($arg->{sequence}) if $arg->{sequence};

  $new_class->db_Main->{ AutoCommit } = 1;

  return $class_for->{ $arg->{dsn} || '' }->{ $arg->{table} } = $new_class;
}

#pod =head2 build_annotator
#pod
#pod   my $code = Object::Annotate->build_annotator(\%arg);
#pod
#pod This builds the routine that will be installed as "annotate" in the importing
#pod class.  It returns a coderef.
#pod
#pod It takes the following arguments:
#pod
#pod   obj_class - the class name to use for this class's log entries
#pod   id_attr   - the method to use to get object ids; if a scalar ref,
#pod               the dereferenced string is used as a constant
#pod   set_time  - if true, the created value will be created as the current time
#pod
#pod =cut

sub build_annotator {
  my ($self, $arg) = @_;

  my $obj_class = $arg->{obj_class};
  my $id_attr   = $arg->{id_attr};
  my $set_time  = $arg->{set_time};

  my @columns
    = $arg->{columns} ? @{ $arg->{columns} } : @{ $note_columns{default} };

  my $noun      = $arg->{noun};

  my $annotator = sub {
    # This $arg purposefully shadows the previous; I don't want to enclose
    # those args. -- rjbs, 2006-01-05
    my ($self, $arg) = @_;
    my $obj_class = $arg->{obj_class} || $self->moniker;

    my $id;
    if (ref $id_attr) {
      $id = $$id_attr;
    } else {
      $id = $self->$id_attr;
      Carp::croak "couldn't get id for $self via $id_attr" unless $id;
    }

    # build up only those attributes we declared
    my %attr;
    for (@columns) {
      next unless exists $arg->{$_};
      $attr{$_} = $arg->{$_};
    }

    $attr{created} = time if $set_time;

    my $class_name_method = "$noun\_class";
    my $request = $self->$class_name_method->create({
      class     => $obj_class,
      object_id => $id,
      %attr,
    });

    return $request;
  };

  return $annotator;
}

#pod =head2 build_searcher
#pod
#pod   my $code = Object::Annotate->build_searcher(\%arg);
#pod
#pod This builds the routine that will be installed as "search_annotations" in the
#pod importing class.  It returns a coderef.
#pod
#pod It takes the following arguments:
#pod
#pod   obj_class - the class name to use for this class's log entries
#pod   id_attr   - the method to use to get object ids; if a scalar ref,
#pod               the dereferenced string is used as a constant
#pod
#pod =cut

sub build_searcher {
  my ($self, $arg) = @_;

  my $obj_class = $arg->{obj_class};
  my $id_attr   = $arg->{id_attr};

  my $noun      = $arg->{noun};

  my $searcher = sub {
    my ($self, $arg) = @_;
    my $obj_class = $arg->{obj_class} || $self->moniker;
    $arg ||= {};

    my $id;
    if (ref $id_attr) {
      $id = $$id_attr;
    } elsif (ref $self) {
      $id = $self->$id_attr;
      Carp::croak "couldn't get id for $self via $id_attr" unless $id;
    }

    $arg->{class}     = $obj_class;
    $arg->{object_id} = $id if defined $id and not exists $arg->{object_id};

    my $class_name_method = "$noun\_class";
    $self->$class_name_method->search(%$arg);
  }
}

'2. see footnote #1';

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::Annotate - mix in logging-to-database to objects (deprecated)

=head1 VERSION

version 0.025

=head1 SYNOPSIS

B<Achtung!>  This library was an experiment.  It failed.  Consider using
L<Mixin::ExtraFields> instead.

  package Your::Class;
  use Object::Annotate annotate => { dsn => '...', table => 'notes' };

  ...

  my $object = Your::Class->new( ... );
  $object->annotate({ event => "created", comment => "(as example)" });

=head1 DESCRIPTION

Object::Annotate is a mixin that provides any class with method for storing
and retrieving notes about its objects.  It can also produce objects which
exist only to store annotations about abstract (uninstantiated) objects,
procedures, or concepts.

=head1 USAGE

To mix Object::Annotate into a class, just C<use> it.  To create a classless
annotator object, use Object::Annotate's C<new> method.  Both of these usages
accept the same arguments:

  db        - options for the database in which notes are stored; a hashref:

    dsn       - the DSN to pass to Class::DBI to create a connection
    user      - the username to use in connecting to the database
    pass      - the password to use in connecting to the database
    table     - the table in which annotations are stored
    sequence  - if given, the Class::DBI table's primary key values comes from
                this sequence; see L<Class::DBI> for more information

  columns   - columns for the annotation table
  obj_class - the class name to use for annotations for this class
              (defaults to Class->moniker, see UNIVERSAL::moniker)
  id_attr   - the object attribute to use for "id"; called as a method
              if it's a scalar ref, it's de-ref'd and used as a constant string

=head2 new

You can use the C<new> method to create a singularity -- an object that can
annotate as if it was of a class that used Object::Annotate, but is of its own
unique class.

  my $notepad = Object::Annotate->new({ db => { ... } });

=head1 METHODS

These methods are not provided by Object::Annotate, but are installed into
classes that use Object::Annotate.

=head2 annotations_class

  my $annotations_class = Your::Class->annotations_class;

This method returns the name of the automatically constructed class that
handles annotations for the class or object on which it is installed.

=head2 annotate

  $object->annotate({
    event => 'update',
    attr  => 'priority',
    old_val => 1,
    new_val => 3,
  });

This method creates an annotation for the object on which it is called.

=head2 search_annotations

  # search all annotations for this class
  my @notes = Class->search_annotations({ event => 'explosion' });

  # searches only annotations for this object
  my @notes = $object->search_annotations({ event => 'explosion' });

This method searches through the annotations for a class or an object, using
the Class::DBI C<search> method.

=head1 INTERNALS

=head2 setup_class

  Object::Annotate->setup_class('annotator', \%arg, \%col);

This method does the heavy lifting needed to turn the class named by C<$target>
into one that does annotation.  It is a group generator as described in
L<Sub::Exporter>.

=head2 class_for

  my $class = Object::Annotate->class_for(\%arg);

This method returns the class to use for the described database and table,
constructing it (see C<L</construct_class>>) if needed.

Valid arguments are (for all, see the L</USAGE> section): dsn, table, db_user,
db_pass, sequence

See the L</USAGE> section, above, for information on these arguments, which
typically are passed along by the import routine.

=head2 default_dsn

=head2 default_table

=head2 default_user

=head2 default_pass

These methods return the default database settings to use if none is specified
when importing Object::Annotate.  The built-in behavior is to return the
OBJ_ANNOTATE_DSN, OBJ_ANNOTATE_TABLE, etc. environment variables.

=head2 default_base_class

This method returns the class from which the annotator subclass will inherit.
It defaults to Class::DBI.

=head2 construct_cdbi_class

  my $new_class = Object::Annotate->construct_cdbi_class(\%arg);

This method sets up a new Class::DBI subclass that will store in the database
described by the arguments.

Valid arguments are:

  dsn     - the dsn for the database in which to store
  user    - the database user as whom to connect
  pass    - the database password
  table   - the table in which to store annotations
  columns - the extra columns for the table
  base_class - class from which the new class inherits (default: Class::DBI)

=head2 build_annotator

  my $code = Object::Annotate->build_annotator(\%arg);

This builds the routine that will be installed as "annotate" in the importing
class.  It returns a coderef.

It takes the following arguments:

  obj_class - the class name to use for this class's log entries
  id_attr   - the method to use to get object ids; if a scalar ref,
              the dereferenced string is used as a constant
  set_time  - if true, the created value will be created as the current time

=head2 build_searcher

  my $code = Object::Annotate->build_searcher(\%arg);

This builds the routine that will be installed as "search_annotations" in the
importing class.  It returns a coderef.

It takes the following arguments:

  obj_class - the class name to use for this class's log entries
  id_attr   - the method to use to get object ids; if a scalar ref,
              the dereferenced string is used as a constant

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo SIGNES

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
