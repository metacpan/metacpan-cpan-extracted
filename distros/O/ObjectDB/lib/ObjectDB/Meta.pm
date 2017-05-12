package ObjectDB::Meta;

use strict;
use warnings;
use mro;

our $VERSION = '3.19';

require Storable;
require Carp;
use List::Util qw(first);

use ObjectDB::Meta::RelationshipFactory;

my %OBJECTS;

sub find_or_register_meta {
    my $class = shift;
    my ($meta_class, @args) = @_;

    return $OBJECTS{$meta_class} ||=
      ObjectDB::Meta->new(class => $meta_class, @args);
}

sub new {
    my $class = shift;
    my (%params) = @_;

    Carp::croak('Class is required when building meta') unless $params{class};

    if (my $parent = $class->_is_inheriting($params{class})) {
        return $parent;
    }

    Carp::croak('Table is required when building meta') unless $params{table};

    my $self = {
        class => $params{class},
        table => $params{table}
    };
    bless $self, $class;

    if ($params{discover_schema}) {
        $self->discover_schema;
    }

    $self->set_columns($params{columns}) if $params{columns};
    $self->set_primary_key($params{primary_key}) if $params{primary_key};
    $self->set_unique_keys($params{unique_keys}) if $params{unique_keys};
    $self->set_auto_increment($params{auto_increment})
      if $params{auto_increment};

    $self->_build_relationships($params{relationships});

    if ($params{generate_columns_methods}) {
        $self->generate_columns_methods;
    }

    if ($params{generate_related_methods}) {
        $self->generate_related_methods;
    }

    return $self;
}

sub class          { $_[0]->{class} }
sub table          { $_[0]->{table} }
sub relationships  { $_[0]->{relationships} }
sub column         { shift->get_column(@_); }
sub columns        { $_[0]->get_columns; }
sub primary_key    { $_[0]->get_primary_key; }
sub auto_increment { $_[0]->get_auto_increment; }

sub is_primary_key {
    my $self = shift;
    my ($name) = @_;

    return !!first { $name eq $_ } $self->get_primary_key;
}

sub is_unique_key {
    my $self = shift;
    my ($name) = @_;

    foreach my $key (@{$self->{unique_keys}}) {
        return 1 if first { $name eq $_ } @$key;
    }

    return 0;
}

sub get_class {
    my $self = shift;

    return $self->{class};
}

sub get_table {
    my $self = shift;

    return $self->{table};
}

sub set_table {
    my $self = shift;
    my ($value) = @_;

    $self->{table} = $value;

    return $self;
}

sub is_column {
    my $self = shift;
    my ($name) = @_;

    Carp::croak('Name is required') unless $name;

    return !!first { $name eq $_->{name} } @{$self->{columns}};
}

sub get_column {
    my $self = shift;
    my ($name) = @_;

    Carp::croak("Unknown column '$name'") unless $self->is_column($name);

    return first { $_->{name} eq $name } @{$self->{columns}};
}

sub get_columns {
    my $self = shift;

    return map { $_->{name} } @{$self->{columns}};
}

sub get_regular_columns {
    my $self = shift;

    my @columns;

    foreach my $column ($self->get_columns) {
        next if first { $column eq $_ } $self->get_primary_key;

        push @columns, $column;
    }

    return @columns;
}

sub set_columns {
    my $self = shift;

    $self->{columns} = [];

    $self->add_columns(@_);

    return $self;
}

sub add_columns {
    my $self = shift;
    my (@columns) = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    my $count = 0;
    while (my ($name, $options) = @columns[$count, $count + 1]) {
        last unless $name;

        if (ref $options eq 'HASH') {
            $self->add_column($name, $options);
        }
        else {
            $self->add_column($name);

            $count++;
            next;
        }

        $count += 2;
    }

    return $self;
}

sub add_column {
    my $self = shift;
    my ($name, $attributes) = @_;

    Carp::croak('Name is required') unless $name;
    Carp::croak("Column '$name' already exists") if $self->is_column($name);

    $attributes ||= {};

    push @{$self->{columns}}, {name => $name, %$attributes};

    return $self;
}

sub remove_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name && $self->is_column($name);

    $self->{columns} = [grep { $_->{name} ne $name } @{$self->{columns}}];

    return $self;
}

sub get_primary_key {
    my $self = shift;

    return @{$self->{primary_key} || []};
}

sub set_primary_key {
    my $self = shift;
    my (@columns) = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    foreach my $column (@columns) {
        Carp::croak("Unknown column '$column' set as primary key")
          unless $self->is_column($column);
    }

    $self->{primary_key} = [@columns];

    return $self;
}

sub get_unique_keys {
    my $self = shift;

    return @{$self->{unique_keys}};
}

sub set_unique_keys {
    my $self = shift;
    my (@columns) = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    $self->{unique_keys} = [];

    $self->add_unique_keys(@columns);

    return $self;
}

sub add_unique_keys {
    my $self = shift;
    my (@columns) = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    foreach my $column (@columns) {
        $self->add_unique_key($column);
    }

    return $self;
}

sub add_unique_key {
    my $self = shift;
    my (@columns) = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    foreach my $column (@columns) {
        Carp::croak("Unknown column '$column' set as unique key")
          unless $self->is_column($column);
    }

    push @{$self->{unique_keys}}, [@columns];

    return $self;
}

sub get_auto_increment {
    my $self = shift;

    return $self->{auto_increment};
}

sub set_auto_increment {
    my $self = shift;
    my ($column) = @_;

    Carp::croak("Unknown column '$column' set as auto increment")
      unless $self->is_column($column);

    $self->{auto_increment} = $column;

    return $self;
}

sub is_relationship {
    my $self = shift;
    my ($name) = @_;

    return exists $self->{relationships}->{$name};
}

sub get_relationship {
    my $self = shift;
    my ($name) = @_;

    Carp::croak("Unknown relationship '$name'")
      unless exists $self->{relationships}->{$name};

    return $self->{relationships}->{$name};
}

sub add_relationship {
    my $self = shift;
    my ($name, $options) = @_;

    Carp::croak('Name and options are required') unless $name && $options;

    $self->{relationships}->{$name} =
      ObjectDB::Meta::RelationshipFactory->new->build(
        $options->{type}, %{$options},
        orig_class => $self->get_class,
        name       => $name
      );
}

sub add_relationships {
    my $self = shift;

    my $count = 0;
    while (my ($name, $options) = @_[$count, $count + 1]) {
        last unless $name && $options;

        $self->add_relationship($name, $options);

        $count += 2;
    }
}

sub discover_schema {
    my $self = shift;

    eval { require DBIx::Inspector; 1 } or do {
        Carp::croak('DBIx::Inspector is required for auto discover');
    };

    my $dbh = $self->class->init_db;

    my $inspector = DBIx::Inspector->new(dbh => $dbh);

    my $table = $inspector->table($self->table);

    $self->set_columns(
        map {
            $_->name => defined $_->column_def
              ? ({default => $_->column_def =~ /^'(.*?)'/ ? $1 : $_->column_def})
              : ($_->is_nullable ? {default => undef, is_null => 1} : ())
        } $table->columns
    );

    $self->set_primary_key(map { $_->name } $table->primary_key);

    return $self;
}

sub generate_columns_methods {
    my $self = shift;

    no strict 'refs';
    no warnings 'redefine';
    foreach my $column ($self->get_columns) {
        *{$self->class . '::' . $column} =
          sub { shift->column($column, @_) };
    }

    return $self;
}

sub generate_related_methods {
    my $self = shift;

    no strict 'refs';
    no warnings 'redefine';
    foreach my $rel_name (keys %{$self->relationships}) {
        *{$self->class . '::' . $rel_name} =
          sub { shift->related($rel_name, @_) };
    }

    return $self;
}

sub _build_relationships {
    my $self = shift;
    my ($relationships) = @_;

    $self->{relationships} ||= {};

    foreach my $rel (keys %{$relationships}) {
        $self->{relationships}->{$rel} =
          ObjectDB::Meta::RelationshipFactory->new->build(
            $relationships->{$rel}->{type}, %{$relationships->{$rel}},
            orig_class => $self->{class},
            name       => $rel
          );
    }
}

sub _is_inheriting {
    my $class = shift;
    my ($for_class) = @_;

    my $parents = mro::get_linear_isa($for_class);
    foreach my $parent (@$parents) {
        if (my $parent_meta = $OBJECTS{$parent}) {
            my $meta = Storable::dclone($parent_meta);

            $meta->{class} = $for_class;

            return $meta;
        }
    }

    return;
}

1;
__END__

=pod

=head1 NAME

ObjectDB::Meta - meta object

=head1 SYNOPSIS

    ObjectDB::Meta->new(
        table          => 'book',
        columns        => [qw/id author_id title/],
        primary_key    => 'id',
        auto_increment => 'id',
        relationships  => {
            author => {
                type = 'many to one',
                class => 'MyAuthor',
                map   => {author_id => 'id'}
            }
        }
    );

=head1 DESCRIPTION

Meta object is used internally for describing the table schema.

=head2 Inheritance

The key feature is inheritance. You can inherit schema, add or remove columns,
specify new relationships and so on.

    package Parent;
    use base 'MyDB';

    __PACKAGE__->schema(
        table       => 'parent',
        columns     => [qw/id title/],
        primary_key => 'id'
    );

    package Child;
    use base 'Parent';

    __PACKAGE__->schema->add_column('description');

=head2 Schema

=over

=item C<table>

Table name.

=item C<columns>

Column names.

=item C<primary_key>

Primary key.

=item C<auto_increment>

Auto increment field. This field is updated as soon as object is created.

=item C<unique_keys>

Unique keys.

=item C<relationships>

Relationships.

=back

=cut
