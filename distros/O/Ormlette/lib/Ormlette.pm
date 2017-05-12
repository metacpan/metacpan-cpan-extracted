package Ormlette;

use strict;
use warnings;

our $VERSION = 0.005;

use Carp;

sub init {
  my ($class, $dbh, %params) = @_;

  croak 'First param to Ormlette->init must be a connected database handle'
    unless $dbh->isa('DBI::db');

  my $namespace = $params{namespace} || caller;

  my $tbl_names = _scan_tables($dbh, $namespace, %params);

  my $self = bless {
    dbh         => $dbh,
    debug       => $params{debug} ? 1 : 0,
    ignore_root => $params{ignore_root},
    isa         => $params{isa},
    namespace   => $namespace,
    readonly    => $params{readonly} ? 1 : 0,
    tbl_names   => $tbl_names,
  }, $class;

  $self->_build_root_pkg unless $self->{ignore_root};
  $self->_build_table_pkg($_) for keys %$tbl_names;

  return $self;
}

sub dbh { $_[0]->{dbh} }

sub _scan_tables {
  my ($dbh, $namespace, %params) = @_;

  my @tables = $dbh->tables(undef, undef, undef, 'TABLE');
  if (my $quote_char = $dbh->get_info(29)) {
    for (@tables) {
      s/$quote_char$//;
      s/^.*$quote_char//;
    }
  }

  if ($params{tables}) {
    my %include = map { $_ => 1 } @{$params{tables}};
    @tables = grep { $include{$_} } @tables;
  } elsif ($params{ignore_tables}) {
    my %exclude = map { $_ => 1 } @{$params{ignore_tables}};
    @tables = grep { !$exclude{$_} } @tables;
  }

  my %tbl_names;
  for (@tables) {
    my $tbl = lc $_;
    $tbl =~ s/__(.)/::\U$1/g;
    my @words = split '_', $tbl;
    $tbl_names{$_} = $namespace . '::' . (join '', map { ucfirst } @words);
  }

  return \%tbl_names;
}

sub _scan_fields {
  my ($self, $tbl_name) = @_;

  my $sth = $self->dbh->prepare("SELECT * FROM $tbl_name LIMIT 0");
  $sth->execute;
  return $sth->{NAME};
}

# Code generation methods below

sub _build_root_pkg {
  my $self = shift;
  my $pkg_name = $self->{namespace};

  my $pkg_src = $self->_pkg_core($pkg_name);
  $pkg_src .= $self->_root_methods;

  $self->_compile_pkg($pkg_src) unless $pkg_name->can('_ormlette_init');
  $pkg_name->_ormlette_init_root($self);
}

sub _build_table_pkg {
  my ($self, $tbl_name) = @_;
  my $pkg_name = $self->{tbl_names}{$tbl_name};

  my $field_list = $self->_scan_fields($tbl_name);

  my $pkg_src = $self->_pkg_core($pkg_name);
  $pkg_src .= $self->_table_methods($tbl_name, $field_list);

  $self->_compile_pkg($pkg_src) unless $pkg_name->can('_ormlette_init');
  $pkg_name->_ormlette_init_table($self, $tbl_name);
}

sub _compile_pkg {
  my ($self, $pkg_src) = @_;
  local $@;
  print STDERR $pkg_src if $self->{debug};
  eval $pkg_src;
  die $@ if $@;
}

sub _pkg_core {
  my ($self, $pkg_name) = @_;

  my $core = <<"END_CODE";
package $pkg_name;

use strict;
use warnings;

use Carp;

END_CODE

  no strict 'refs';
  if ($self->{isa} && !@{ $pkg_name . '::ISA' }) {
    my $isa = $self->{isa};
    $core .= <<"END_CODE";
our \@ISA = '$isa';

END_CODE
  }
  use strict 'refs';

  $core .= <<"END_CODE";
my \$_ormlette_dbh;

sub dbh { \$_ormlette_dbh }

sub _ormlette_init {
  my (\$class, \$ormlette) = \@_;
  \$_ormlette_dbh = \$ormlette->dbh;
}

END_CODE

  return $core;
}

sub _root_methods {
  my $self = shift;

  return <<"END_CODE";
sub _ormlette_init_root {
  my (\$class, \$ormlette) = \@_;
  \$class->_ormlette_init(\$ormlette);
}

END_CODE
}

sub _table_methods {
  my ($self, $tbl_name, $field_list) = @_;
  my $pkg_name = $self->{tbl_names}{$tbl_name};

  my $select_fields = join ', ', map { "$tbl_name.$_" } @$field_list;
  my $field_vars = '$' . join ', $', @$field_list;
  my $inflate_fields; $inflate_fields .= "$_ => \$$_, " for @$field_list;

  my @accessor_fields = grep { !$pkg_name->can($_) } @$field_list;
  my $code;
  $code = $self->_add_accessors($pkg_name, @accessor_fields)
    if @accessor_fields;

  $code .= <<"END_CODE";
sub table { '$tbl_name' }

sub _ormlette_init_table {
  my (\$class, \$ormlette, \$table_name) = \@_;
  \$class->_ormlette_init(\$ormlette);
}

sub iterate {
  my \$class = shift;
  my \$callback = shift;

  my \$sql = 'SELECT $select_fields FROM $tbl_name';
  \$sql .= ' ' . shift if \@_;
  my \$sth = \$class->dbh->prepare_cached(\$sql);
  \$sth->execute(\@_);

  local \$_;
  while (\$_ = \$class->_ormlette_load_from_sth(\$sth)) {
    \$callback->();
  }
}

sub select {
  my \$class = shift;
  my \@results;
  \$class->iterate(sub { push \@results, \$_ }, \@_);
  return \\\@results;
}

sub _ormlette_load_from_sth {
  my (\$class, \$sth) = \@_;

  \$sth->bind_columns(\\(my ($field_vars)));
  return unless \$sth->fetch;

  return bless { $inflate_fields }, \$class;
}

END_CODE

  $code .= <<"END_CODE";
sub load {
  my \$class = shift;

  croak '->load requires at least one argument' unless \@_;

  my \$sql = 'SELECT $select_fields FROM $tbl_name WHERE ';
  my \@criteria;

END_CODE

  my @key = $self->dbh->primary_key(undef, undef, $tbl_name);
  if (@key == 1) {
    my $key_criteria = $key[0] . ' = ?';

    $code .= <<"END_CODE";

  if (\@_ == 1) {
    \$sql .= '$key_criteria';
    \@criteria = \@_;
  } else {
    croak 'if not using a single-field key, ->load requires a hash of criteria'
      unless \@_ % 2 == 0;

    my \%params = \@_;
    \$sql .= join ' AND ', map { "\$_ = ?" } keys \%params;
    \@criteria = values \%params;
  }
END_CODE
  } else { # primary key absent or multi-field
    $code .= <<"END_CODE";
  croak 'if not using a single-field key, ->load requires a hash of criteria'
    unless \@_ % 2 == 0;

  my \%params = \@_;
  \$sql .= join ' AND ', map { "\$_ = ?" } keys \%params;
  \$sql .= ' LIMIT 1';
  \@criteria = values \%params;
END_CODE
  }

  $code .= <<"END_CODE";
  my \$sth = \$class->dbh->prepare_cached(\$sql);
  \$sth->execute(\@criteria);

  my \$obj = \$class->_ormlette_load_from_sth(\$sth);
  \$sth->finish;

  return \$obj;
}
END_CODE

  $code .= $self->_table_mutators($tbl_name, $field_list)
    unless $self->{readonly};

  return $code;
}

sub _add_accessors {
  my ($self, $pkg_name, @accessor_fields) = @_;

  my $accessor_sub;
  if ($self->{readonly}) {
    $accessor_sub = '$_[0]->{$attr}';
  } else {
    $accessor_sub = '
      $_[0]->{$attr} = $_[1] if defined $_[1];
      $_[0]->{$attr};'
  }

  my $field_list = join ' ', @accessor_fields;
  return <<"END_CODE";
{
  no strict 'refs';
  for my \$attr (qw( $field_list )) {
    *\$attr = sub {
      $accessor_sub
    };
  }
}
END_CODE
}

sub _table_mutators {
  my ($self, $tbl_name, $field_list) = @_;
  my $pkg_name = $self->{tbl_names}{$tbl_name};

  my $insert_fields = join ', ', @$field_list;
  my $insert_params = join ', ', ('?') x @$field_list;
  my $insert_values = join ', ', map { "\$self->{$_}" } @$field_list;
  my $handle_autoincrement = '';
  my $init_all_attribs = join ",\n    ",
    map { "'$_' => \$params{'$_'}" } @$field_list;

  my @key = $self->dbh->primary_key(undef, undef, $tbl_name);
  if (@key == 1) {
    my $key_field = $key[0];
    $handle_autoincrement = qq(
  \$self->{$key_field} =
    \$self->dbh->last_insert_id(undef, undef, qw( $tbl_name $key_field ))
      unless defined \$self->{$key_field};);
  }

  my $code = <<"END_CODE";

sub _ormlette_new {
  my (\$class, \%params) = \@_;
  bless {
    $init_all_attribs
  }, \$class;
}

sub create {
  my \$class = shift;
  \$class->new(\@_)->insert;
}

sub insert {
  my \$self = shift;
  my \$sql =
    'INSERT INTO $tbl_name ( $insert_fields ) VALUES ( $insert_params )';
  my \$sth = \$self->dbh->prepare_cached(\$sql);
  \$sth->execute($insert_values);
  $handle_autoincrement
  return \$self;
}

sub truncate {
  my \$class = shift;
  croak '->truncate must be called as a class method' if ref \$class;
  my \$sql = 'DELETE FROM $tbl_name';
  my \$sth = dbh->prepare_cached(\$sql);
  \$sth->execute;
}

END_CODE

  if (@key) {
    my $key_criteria = join ' AND ', map { "$_ = ?" } @key;
    my $key_values = join ', ', map { "\$self->{$_}" } @key;
    my $update_fields = join ', ', map { "$_ = ?" } @$field_list;

    $code .= <<"END_CODE";
sub update {
  my \$self = shift;
  my \$sql = 'UPDATE $tbl_name SET $update_fields WHERE $key_criteria';
  my \$sth = \$self->dbh->prepare_cached(\$sql);
  my \$changed = \$sth->execute($insert_values, $key_values);
  \$self->insert unless \$changed > 0;

  return \$self;
}

sub delete {
  my \$self = shift;
  my \$sql = 'DELETE FROM $tbl_name';
  if (ref \$self) {
    \$sql .= ' WHERE $key_criteria';
    \@_ = ( $key_values );
  } else {
    return unless \@_;
    \$sql .= ' ' . shift;
  }
  my \$sth = \$self->dbh->prepare_cached(\$sql);
  \$sth->execute(\@_);
}
END_CODE
  } else { # no primary key
    $code .= <<"END_CODE";
sub delete {
  my \$class = shift;
  croak '->delete may not be called as an instance method for an unkeyed table'
    if ref \$class;
  return unless \@_;
  my \$sql = 'DELETE FROM $tbl_name ' . shift;
  my \$sth = \$class->dbh->prepare_cached(\$sql);
  \$sth->execute(\@_);
}
END_CODE
  }

  unless ($pkg_name->can('new')) {
    $code .= '
sub new { my $class = shift; $class->_ormlette_new(@_); }
';
  }

  if (@key) {
    my $destroy_name =
      $pkg_name->can('DESTROY') ? '_ormlette_DESTROY' : 'DESTROY';
    $code .= "
sub mark_dirty { \$_[0]->{_dirty} = 1 }
sub mark_clean { \$_[0]->{_dirty} = 0 }
sub dirty      { return \$_[0]->{_dirty} }

sub $destroy_name { \$_[0]->update if \$_[0]->{_dirty} }"
  }

  return $code;
}

1;

=pod

=head1 NAME

Ormlette - Light and fluffy object persistence

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $dbh = DBI->connect(...);
  Ormlette->init($dbh, tables => [ 'my_table' ], namespace => Test);

  my $obj = Test::MyTable->create(foo => 1, bar => 3);
  print Test::MyTable->load(foo => 1)->bar; # 3

=head1 DESCRIPTION

Ormlette is a simple object persistence mechanism which is specifically
designed to avoid imposing any requirements on how your code is organized or
what base classes you use.

Rather than requiring your classes to inherit from it, Ormlette is initialized
by passing an open database handle to C<< Ormlette->init >>, at which point
Ormlette will identify the tables in that database and, for each one, derive a
package name by camel-casing the table name using C<_> in the table name as a
word break (e.g., C<foo_bar> becomes C<FooBar>) and prepending the current
package's name.  It will then inject its methods (see below) into the resulting
package.  It will also create accessors corresponding to each of the table's
fields unless these accessors already exist.

Note that, if you want to define your own methods within a package which will
have methods injected by Ormlette, you should load the corresponding module
(with C<use> or C<require>) before doing any Ormlette initializations affecting
that package so that Ormlette will know what methods you've defined yourself
and avoid interfering with them.

=head1 Ormlette Core Methods

=head2 init ($dbh, %params)

Attaches Ormlette methods to classes corresponding to tables in the database
connected to $dbh.  Recognized parameters:

=over 4

=head3 debug

The C<debug> option will cause additional debugging information to be printed
to STDERR as Ormlette does its initialization.  At this point, this consists
solely of the generated source code for each package affected by Ormlette.

=head3 isa

Specifies that all Ormlette-generated classes should be made subclasses of
the C<isa> package.  This is done by directly setting C<@ISA>, not via C<use
base> or C<use parent>, so you are responsible for ensuring that the
specified class is available to use as a parent.

If Ormlette is adding to a class which already exists and already has a
parent in C<@ISA>, the existing parent will be untouched and the C<isa> option
will have no effect on that class.

=head3 ignore_root

Ormlette will normally inject a C<dbh> method into the base namespace of its
generated code, providing access to the source database.  This is not always
desirable.  In such cases, setting C<ignore_root> will prevent Ormlette from
making any modifications to that package.

=head3 ignore_tables

Ormlette will normally generate classes corresponding to all tables found
in the database.  If there are tables which should be skipped over, a
reference to an array of table names to skip can be passed in the
C<ignore_tables> parameter.

If you prefer to list the tables to include rather than the tables to
exclude, use C<tables>.  There should never be a reason to specify both
C<tables> and C<ignore_tables>, but, if this is done, C<tables> will take
precedence and C<ignore_tables> will be silently ignored.

=head3 namespace

By default, Ormlette will use the name of the package which calls C<init> as
the base namespace for its generated code.  If you want the code to be placed
into a different namespace, use the C<namespace> parameter to override this
default.

=head3 readonly

If C<readonly> is set to a true value, no constructors or database-altering
methods will be created and generated accessors will be read-only.

=head3 tables

If you only require Ormlette code to be generated for some of the tables in
your database, providing a reference to an array of table names in the
C<tables> parameter will cause all other tables to be ignored.

If you prefer to list the tables to exclude rather than those to include,
use C<ignore_tables>.

=back

=head2 dbh

Returns the internal database handle used for database interaction.  Can be
called on the core Ormlette object, the root namespace of its generated code
(unless the C<ignore_root> option is set when calling C<init>), or any of the
persistent classes generated in that namespace.

=head1 Root Namespace Methods

If the C<ignore_root> option is set when calling C<init>, no methods will
be generated in the root namespace.

=head2 dbh

Returns the database handle attached by Ormlette to the root namespace.  If
multiple Ormlette objects have been instantiated with the same C<namespace>,
this will return the handle corresponding to the first Ormlette initialized
there.

=head1 Table Class Methods

In addition to the methods listed below, accessors will be generated for each
field found in the table unless an accessor for that field already exists,
providing the convenience of not having to create all the accessors yourself
while also allowing for custom accessors to be used where needed.  Generated
accessors will be read-only if C<readonly> is set or writable using the
C<< $obj->attr('new value') >> convention otherwise.

Note that the generated accessors are extremely simple and make no attempt at
performing any form of data validation, so you may wish to use another fine
CPAN module to generate accessors before initializing Ormlette.

=head2 create

Constructs an object by calling C<new>, then uses C<insert> to immediately
store it to the database.

This method will not be generated if C<readonly> is set.

=head2 dbh

Returns the database handle used by Ormlette operations on this class.

=head2 delete

=head2 delete('WHERE name = ?', 'John Doe')

As a class method, deletes all objects matching the criteria specified in the
parameters.  In an attempt to avoid data loss from accidentally calling
C<delete> as a class method when intending to use it as an instance method,
nothing will be done if no criteria are provided.

As an instance method, deletes the object from the database.  In this case, any
parameters will be ignored.  The in-memory object is unaffected and remains
available for further use, including re-saving it to the database.

This method will not be generated if C<readonly> is set.  The instance method
variant will only be generated for tables which have a primary key.

=head2 dirty

Read-only flag indicating whether an object is "dirty" (i.e., has unsaved
changes).  This flag is not maintained automatically; code using the object
must use its C<mark_dirty> method to set the flag and C<mark_clean> to clear
it.

If an object is destroyed while dirty, a C<DESTROY> handler will automatically
call its C<update> method to write changes to the database.  If the class
already has a C<DESTROY> handler prior to Ormlette initialization, this check
is instead placed into an C<_ormlette_DESTROY> method, which the other
C<DESTROY> should call if autoupdate functionality is desired.

The C<dirty> attribute, C<mark_dirty> and C<mark_clean> methods, and C<DESTROY>
handler will not be generated if C<readonly> is set or for tables which do
not have a primary key.

=head2 insert

Inserts the object into the database as a new record.  This method will fail if
the record cannot be inserted.  If the table uses an autoincrement/serial
primary key and no value for that key is set in the object, the in-memory
object will be updated with the id assigned by the database.

This method will not be generated if C<readonly> is set.

=head2 iterate(sub { print $_->id })

=head2 iterate(sub { print $_->name }, 'WHERE age > ?', 18)

Takes a sub reference as the first parameter and passes each object returned by
the subsequent query to the referenced sub in C<$_> for processing.  The
primary difference between this method and C<select> is that C<iterate> only
loads one record into memory at a time, while C<select> loads all records at
once, which may require unacceptable amounts of memory when dealing with larger
data sets.

=head2 mark_clean

Clears an object's C<dirty> flag.

=head2 mark_dirty

Sets an object's C<dirty> flag.

=head2 new

Basic constructor which accepts a hash of values and blesses them into the
class.  If a ->new method has already been defined, it will not be replaced.
If you wish to retain the default constructor functionality within your
custom ->new method, you can call $class->_ormlette_new to do so.

This method will not be generated if C<readonly> is set.

=head2 load(1)

=head2 load(foo => 1, bar => 2)

Retrieves a single object from the database based on the specified criteria.

If the table has a single-field primary key, passing a single argument will
retrieve the record with that value as its primary key.

Lookups on non-key fields or multiple-field primary keys can be performed by
passing a hash of field => value pairs.  If more than one record matches the
given criteria, only one will be returned; which one is returned may or may
not be consistent from one call to the next.

Returns undef if no matching record exists.

=head2 select

=head2 select('WHERE id = 42');

=head2 select('WHERE id > ? ORDER BY name LIMIT 5', 3);

Returns a reference to an array containing all objects matching the query
specified in the parameters, in the order returned by that query.  If no
parameters are provided, returns objects for all records in the database's
natural sort order.

As this method simply appends its parameters to "SELECT (fields) FROM (table)",
arbitrarily-complex queries can be built up in the parameters, including joins
and subqueries.

=head2 table

Returns the table name in which Ormlette stores this class's data.

=head2 update

Updates the object's existing database record.  This method will implicitly
call C<insert> if the object does not already exist in the database.

This method will not be generated if C<readonly> is set or for tables which
do not have a primary key.

=head1 TO DO

=over 4

=item *

Verify functionality with DBD back-ends other than SQLite

=item *

Add support for multi-level package hierarchies

=item *

Allow all Ormlette functions to be overridden, not just C<new> and accessors

=item *

Add transaction support

=item *

Cache loaded objects to prevent duplication

=back

=head1 CREDITS

Although it is not intended as a drop-in replacement, Ormlette's API and
general coding style are heavily influenced by Adam Kennedy's L<ORLite>.

=head1 AUTHOR

Dave Sherohman <dsheroh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Sherohman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Light and fluffy object persistence

