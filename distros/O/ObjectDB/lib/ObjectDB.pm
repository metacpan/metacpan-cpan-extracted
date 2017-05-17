package ObjectDB;

use strict;
use warnings;
use mro;

require Carp;
use Scalar::Util ();
use SQL::Composer;
use ObjectDB::DBHPool;
use ObjectDB::Meta;
use ObjectDB::Quoter;
use ObjectDB::RelatedFactory;
use ObjectDB::Table;
use ObjectDB::With;
use ObjectDB::Util qw(execute merge_rows filter_columns);

our $VERSION = '3.20';

$Carp::Internal{(__PACKAGE__)}++;
$Carp::Internal{"ObjectDB::$_"}++ for qw/
  With
  Related
  Related::ManyToOne
  Related::OneToOne
  Related::ManyToMany
  Related::OneToMany
  Meta::Relationship
  Meta::Relationship::ManyToOne
  Meta::Relationship::OneToOne
  Meta::Relationship::ManyToMany
  Meta::Relationship::OneToMany
  Meta::RelationshipFactory
  Table
  Util
  Quoter
  DBHPool
  Meta
  RelationshipFactory
  Exception
  /;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my (%columns) = @_;

    my $self = {};
    bless $self, $class;

    foreach my $column (keys %columns) {
        if (   $self->meta->is_column($column)
            || $self->meta->is_relationship($column))
        {
            $self->set_column($column => $columns{$column});
        }
    }

    $self->{is_in_db}    = 0;
    $self->{is_modified} = 0;

    return $self;
}

sub is_in_db {
    my $self = shift;

    if (@_) {
        $self->{is_in_db} = $_[0];
        return $self;
    }

    return $self->{is_in_db};
}

sub is_modified {
    my $self = shift;

    return $self->{is_modified};
}

sub dbh { &init_db }

sub init_db {
    my $self = shift;

    no strict;

    my $class = ref($self) ? ref($self) : $self;

    my $dbh;
    if (@_) {
        if (@_ == 1 && ref $_[0]) {
            ${"$class\::DBH"} = shift;
        }
        else {
            ${"$class\::DBH"} = ObjectDB::DBHPool->new(@_);
        }

        $dbh = ${"$class\::DBH"};
    }
    else {
        $dbh = ${"$class\::DBH"};

        if (!$dbh) {
            my $parents = mro::get_linear_isa($class);
            foreach my $parent (@$parents) {
                if ($dbh = ${"$parent\::DBH"}) {
                    last;
                }
            }
        }

        Carp::croak('Setup a dbh first') unless $dbh;
    }

    return $dbh->isa('ObjectDB::DBHPool')
      ? $dbh->dbh
      : $dbh;
}

sub txn {
    my $self = shift;
    my ($cb) = @_;

    my $dbh = $self->init_db;

    my $retval;
    eval {
        $dbh->{AutoCommit} = 0;

        $retval = $cb->($self);

        $self->commit;
    } || do {
        my $e = $@;

        $self->rollback;

        Carp::croak($e);
    };

    return $retval;
}

sub commit {
    my $self = shift;

    my $dbh = $self->init_db;

    if ($dbh->{AutoCommit} == 0) {
        $dbh->commit;
        $dbh->{AutoCommit} = 1;
    }

    return $self;
}

sub rollback {
    my $self = shift;

    my $dbh = $self->init_db;

    if ($dbh->{AutoCommit} == 0) {
        $dbh->rollback;
        $dbh->{AutoCommit} = 1;
    }

    return $self;
}

sub meta {
    my $class = shift;
    $class = ref $class if ref $class;

    return ObjectDB::Meta->find_or_register_meta($class, @_);
}

sub table {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;

    return ObjectDB::Table->new(class => $class, dbh => $self->init_db);
}

sub columns {
    my $self = shift;

    my @columns;
    foreach my $key ($self->meta->columns) {
        if (exists $self->{columns}->{$key}) {
            push @columns, $key;
        }
    }

    return @columns;
}

sub column {
    my $self = shift;

    $self->{columns} ||= {};

    if (@_ == 1) {
        return $self->get_column(@_);
    }
    elsif (@_ == 2) {
        $self->set_column(@_);
    }

    return $self;
}

sub get_column {
    my $self = shift;
    my ($name) = @_;

    if ($self->meta->is_column($name)) {
        unless (exists $self->{columns}->{$name}) {
            if (exists $self->meta->get_column($name)->{default}) {
                my $default = $self->meta->get_column($name)->{default};
                return ref $default eq 'CODE' ? $default->() : $default;
            }
            else {
                return undef;
            }
        }

        return $self->{columns}->{$name};
    }
    elsif ($self->meta->is_relationship($name)) {
        return
          exists $self->{relationships}->{$name}
          ? $self->{relationships}->{$name}
          : undef;
    }
    else {
        return $self->{virtual_columns}->{$name};
    }
}

sub set_columns {
    my $self = shift;
    my %values = ref $_[0] ? %{$_[0]} : @_;

    while (my ($key, $value) = each %values) {
        $self->set_column($key => $value);
    }

    return $self;
}

sub set_column {
    my $self = shift;
    my ($name, $value) = @_;

    if ($self->meta->is_column($name)) {
        if (   !defined $value
            && !$self->meta->get_column($name)->{is_null})
        {
            $value = q{};
        }

        if (
            !exists $self->{columns}->{$name}
            || !(
                   (defined $self->{columns}->{$name} && defined $value)
                && ($self->{columns}->{$name} eq $value)
            )
          )
        {
            $self->{columns}->{$name} = $value;
            $self->{is_modified} = 1;
        }
    }
    elsif ($self->meta->is_relationship($name)) {
        my $related_value;
        if (Scalar::Util::blessed($value)) {
            $related_value = $value;
        }
        elsif (ref $value eq 'ARRAY') {
            $related_value = [];
            foreach my $sub_value (@$value) {
                next unless defined $sub_value && ref $sub_value;

                Carp::croak(
                    qq{Value of related object(s) '$name' has to be a reference}
                ) unless ref $sub_value;

                if (Scalar::Util::blessed($sub_value)) {
                    push @$related_value, $sub_value;
                }
                elsif (ref($sub_value) eq 'HASH') {
                    if (!$self->_is_empty_hash_ref($sub_value)) {
                        push @$related_value,
                          $self->meta->get_relationship($name)
                          ->class->new(%$sub_value);
                    }
                }
                else {
                    Carp::croak(qq{Unexpected reference found }
                          . qq{when setting '$name' related object});
                }
            }

            undef $related_value unless @$related_value;
        }
        elsif (!$self->_is_empty_hash_ref($value)) {
            $related_value =
              $self->meta->get_relationship($name)->class->new(%$value);
        }

        if ($related_value) {
            if ($self->meta->get_relationship($name)->is_multi
                && ref($related_value) ne 'ARRAY')
            {
                $related_value = [$related_value];
            }

            $self->{relationships}->{$name} = $related_value;
        }
    }
    else {
        $self->{virtual_columns}->{$name} = $value;
    }

    return $self;
}

sub clone {
    my $self = shift;

    my %columns;
    foreach my $column ($self->meta->columns) {
        next
          if $self->meta->is_primary_key($column)
          || $self->meta->is_unique_key($column);
        $columns{$column} = $self->column($column);
    }

    return (ref $self)->new->set_columns(%columns);
}

sub create {
    my $self = shift;

    Carp::croak(q{Calling 'create' on already created object})
      if $self->is_in_db;

    my $sql = SQL::Composer->build(
        'insert',
        driver => $self->init_db->{Driver}->{Name},
        into   => $self->meta->table,
        values => [map { $_ => $self->{columns}->{$_} } $self->columns]
    );

    my $rv = execute($self->init_db, $sql, context => $self);

    if (my $auto_increment = $self->meta->auto_increment) {
        $self->set_column(
            $auto_increment => $self->init_db->last_insert_id(
                undef, undef, $self->meta->table, $auto_increment
            )
        );
    }

    $self->{is_in_db}    = 1;
    $self->{is_modified} = 0;

    foreach my $rel_name (keys %{$self->meta->relationships}) {
        if (my $rel_values = $self->{relationships}->{$rel_name}) {
            if (ref $rel_values eq 'ARRAY') {
                @$rel_values = grep { !$_->is_in_db } @$rel_values;
                next unless @$rel_values;
            }
            else {
                next if $rel_values->is_in_db;
            }

            my $rel = $self->meta->get_relationship($rel_name);
            my @related = $self->create_related($rel_name, $rel_values);

            $self->{relationships}->{$rel_name} =
              $rel->is_multi ? \@related : $related[0];
        }
    }

    return $self;
}

sub save {
    my $self = shift;

    if ($self->is_in_db) {
        return $self->update;
    }
    else {
        return $self->create;
    }
}

sub find { shift->table->find(@_) }

sub load {
    my $self = shift;
    my (%params) = @_;

    my @columns;

    foreach my $name ($self->columns) {
        push @columns, $name if $self->meta->is_primary_key($name);
    }

    if (!@columns) {
        foreach my $name ($self->columns) {
            push @columns, $name if $self->meta->is_unique_key($name);
        }
    }

    Carp::croak(ref($self) . ': no primary or unique keys specified')
      unless @columns;

    my $where = [map { $_ => $self->{columns}->{$_} } @columns];

    my $with = ObjectDB::With->new(meta => $self->meta, with => $params{with});

    my $columns = filter_columns([$self->meta->get_columns], \%params);

    my $select = SQL::Composer->build(
        'select',
        driver     => $self->init_db->{Driver}->{Name},
        columns    => $columns,
        from       => $self->meta->table,
        where      => $where,
        join       => $with->to_joins,
        for_update => $params{for_update},
    );

    my ($rv, $sth) = execute($self->init_db, $select, context => $self);

    my $rows = $sth->fetchall_arrayref;
    return unless $rows && @$rows;

    my $row_object = $select->from_rows($rows)->[0];

    $self->{columns} = {};
    $self->{relationships} = {};

    $self->set_columns(%$row_object);

    $self->{is_modified} = 0;
    $self->{is_in_db}    = 1;

    return $self;
}

sub load_or_create
{
    my $self = shift;

    my @columns;
    foreach my $name ($self->columns) {
        push @columns, $name if $self->meta->is_primary_key($name);
    }

    if (!@columns) {
        foreach my $name ($self->columns) {
            push @columns, $name if $self->meta->is_unique_key($name);
        }
    }

    my $object;
    $object = $self->load if @columns;
    $object ||= $self->create;

    return $object;
}

sub update {
    my $self = shift;

    return $self unless $self->is_modified;

    my %where;
    foreach my $name ($self->columns) {
        $where{$name} = $self->{columns}->{$name}
          if $self->meta->is_primary_key($name);
    }

    if (!keys %where) {
        foreach my $name ($self->columns) {
            $where{$name} = $self->{columns}->{$name}
              if $self->meta->is_unique_key($name);
        }
    }

    Carp::croak(ref($self) . ': no primary or unique keys specified')
      unless keys %where;

    my @columns = grep { !$self->meta->is_primary_key($_) } $self->columns;
    my @values  = map  { $self->{columns}->{$_} } @columns;

    my %columns_set;
    @columns_set{@columns} = @values;
    my $sql = SQL::Composer->build(
        'update',
        driver => $self->init_db->{Driver}->{Name},
        table  => $self->meta->table,
        values => [%columns_set],
        where  => [%where]
    );

    my $rv = execute($self->init_db, $sql, context => $self);

    Carp::croak('No rows were affected') if $rv eq '0E0';

    $self->{is_modified} = 0;
    $self->{is_in_db}    = 1;

    return $self;
}

sub delete : method {
    my $self = shift;

    my %where;
    foreach my $name ($self->columns) {
        $where{$name} = $self->{columns}->{$name}
          if $self->meta->is_primary_key($name);
    }

    if (!keys %where) {
        foreach my $name ($self->columns) {
            $where{$name} = $self->{columns}->{$name}
              if $self->meta->is_unique_key($name);
        }
    }

    Carp::croak(ref($self) . ': no primary or unique keys specified')
      unless keys %where;

    my $sql = SQL::Composer->build(
        'delete',
        driver => $self->init_db->{Driver}->{Name},
        from   => $self->meta->table,
        where  => [%where]
    );

    my $rv = execute($self->init_db, $sql, context => $self);

    Carp::croak('No rows were affected') if $rv eq '0E0';

    %$self = ();

    return $self;
}

sub to_hash {
    my $self = shift;

    my $hash = {};

    foreach my $key ($self->meta->get_columns) {
        if (exists $self->{columns}->{$key}) {
            $hash->{$key} = $self->get_column($key);
        }
        elsif (exists $self->meta->get_column($key)->{default}) {
            $hash->{$key} = $self->get_column($key);
        }
    }

    foreach my $key (keys %{$self->{virtual_columns}}) {
        $hash->{$key} = $self->get_column($key);
    }

    foreach my $name (keys %{$self->{relationships}}) {
        my $rel = $self->{relationships}->{$name};
        next unless defined $rel;

        Carp::croak("unknown '$name' relationship") unless $rel;

        if (ref $rel eq 'ARRAY') {
            $hash->{$name} = [map { $_->to_hash } @$rel];
        }
        else {
            $hash->{$name} = $rel->to_hash;
        }
    }

    return $hash;
}

sub is_related_loaded {
    my $self = shift;
    my ($name) = @_;

    return exists $self->{relationships}->{$name};
}

sub related {
    my $self = shift;
    my ($name) = shift;

    my $rel = $self->meta->get_relationship($name);

    if (!$self->{relationships}->{$name}) {
        $self->{relationships}->{$name} =
          $rel->is_multi
          ? [$self->find_related($name, @_)]
          : $self->find_related($name, @_);
    }

    my $related = $self->{relationships}->{$name};

    return
        wantarray
      ? ref $related eq 'ARRAY'
          ? @$related
          : ($related)
      : $related;
}

sub find_related   { shift->_do_related('find',   @_) }
sub update_related { shift->_do_related('update', @_) }
sub count_related  { shift->_do_related('count',  @_) }
sub delete_related { shift->_do_related('delete', @_) }

sub create_related {
    my $self = shift;
    my $name = shift;

    my @related = @_ == 1 ? ref $_[0] eq 'ARRAY' ? @{$_[0]} : ($_[0]) : ({@_});

    my @rv = $self->_do_related('create', $name, \@related);
    return @rv == 1 ? $rv[0] : @rv;
}

sub _do_related {
    my $self   = shift;
    my $action = shift;
    my $name   = shift;

    Carp::croak('Relationship name is required') unless $name;

    my $related = $self->_build_related($name);

    my $method = "$action\_related";
    return $related->$method($self, @_);
}

sub _build_related {
    my $self = shift;
    my ($name) = @_;

    my $meta = $self->meta->get_relationship($name);

    return ObjectDB::RelatedFactory->new->build($meta->type, meta => $meta);
}

sub _is_empty_hash_ref {
    my $self = shift;
    my ($hash_ref) = @_;

    return 1 unless defined $hash_ref && ref $hash_ref eq 'HASH';

    foreach my $key (keys %$hash_ref) {
        if (defined $hash_ref->{$key} && $hash_ref->{$key} ne '') {
            if (ref($hash_ref->{$key}) eq 'HASH') {
                my $is_empty = $self->_is_empty_hash_ref($hash_ref->{$key});
                return 0 unless $is_empty;
            }
            else {
                return 0;
            }
        }
    }

    return 1;
}

1;
__END__

=pod

=head1 NAME

ObjectDB - usable ORM

=head1 SYNOPSIS

    package MyDB;
    use base 'ObjectDB';

    sub init_db {
        ...
        return $dbh;
    }

    package MyAuthor;
    use base 'MyDB';

    __PACKAGE__->meta(
        table          => 'author',
        columns        => [qw/id name/],
        primary_key    => 'id',
        auto_increment => 'id',
        relationships  => {
            books => {
                type = 'one to many',
                class => 'MyBook',
                map   => {id => 'author_id'}
            }
        }
    );

    package MyBook;
    use base 'MyDB';

    __PACKAGE__->meta(
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

    my $book_by_id = MyBook->new(id => 1)->load(with => 'author');

    my @books_authored_by_Pushkin =
      MyBook->table->find(where => ['author.name' => 'Pushkin']);

    $author->create_related('books', title => 'New Book');

=head1 DESCRIPTION

ObjectDB is a lightweight and flexible object-relational mapper. While being
light it stays usable. ObjectDB borrows many things from L<Rose::DB::Object>,
but unlike in the last one columns are not objects, everything is pretty much
straightforward and flat.

Supported servers: SQLite, MySQL, PostgreSQL

=head2 Actions on columns

=head3 Methods

=over

=item C<set_columns>

Set columns.

    $book->set_columns(title => 'New Book', pages => 140);

=item C<set_column>

Set column.

    $book->set_column(title => 'New Book');

=item C<get_column>

    my $title = $book->get_column('title');

=item C<column>

A shortcut for C<set_column>/C<get_column>.

    $book->column(title => 'New Book');
    my $title = $book->column('title');

=back

=head2 Actions on rows

Main ObjectDB instance represents a row object. All actions performed on this
instance are performed on one row. For performing actions on several rows see
L<ObjectDB::Table>.

=head3 Methods

=over

=item C<create>

Creates a new row. If C<meta> has an C<auto_increment> column then it is
properly set.

    my $author = MyAuthor->new(name => 'Me')->create;

It is possible to create related objects automatically:

    my $author = MyAuthor->new(
        name  => 'Me',
        books => [{title => 'Book1'}, {title => 'Book2'}]
    )->create;

Which is a convenient way of calling C <create_related> manually .

=item C<load>

Loads an object by primary or unique key.

    my $author = MyAuthor->new(id => 1)->load;

It is possible to load an object with related objects.

    my $book = MyBook->new(title => 'New Book')->load(with => 'author');

=item C<update>

Updates an object.

    $book->set_column(title => 'Old Title');
    $book->update;

=item C<delete>

Deletes an object. Related objects are NOT deleted.

    $book->delete;

=back

=head2 Actions on tables

In order to perform an action on table a L<ObjectDB::Table> object must be
obtained via C<table> method (see L<ObjectDB::Table> for all available actions).
The only exception is C<find>, it is available in a row object for convenience.

    MyBook->table->delete; # deletes ALL records from MyBook

=head2 Actions on related objects

=head3 Methods

=over

=item C<related>

Returns preloaded related objects or loads them on demand.

    # same as find_related but with caching
    my $description = $book->related('book_description');

    # returns from cache
    my $description = $book->related('book_description');

=item C<create_related>

Creates related object, setting appropriate foreign keys. Accepts a list, a hash
reference, an object.

    $author->create_related('books', title => 'New Book');
    $author->create_related('books', MyBook->new(title => 'New Book'));

=item C<find_related>

Finds related object.

    my $books = $author->find_related('books', where => [title => 'New Book']);

=item C<update_related>

Updates related object.

    $author->update_related(
        'books',
        set   => {title => 'Old Book'},
        where => [title => 'New Book']
    );

=item C<delete_related>

Deletes related object.

    $author->delete_related('books', where => [title => 'New Book']);

=back

=head2 Transactions

All the exceptions will be catched, a rollback will be run and exceptions will
be rethrown. It is safe to use C<rollback> or C<commit> inside of a transaction
when you want to do custom exception handling.

    MyDB->txn(
        sub {
            ... do smth that can throw ...
        }
    );

C<txn>'s return value is preserved, so it is safe to do something like:

    my $result = MyDB->txn(
        sub {
            return 'my result';
        }
    );

=head3 Methods

=over

=item C<txn>

Accepts a subroutine reference, wraps code into eval and runs it rethrowing all
exceptions.

=item C<commit>

Commit transaction.

=item C<rollback>

Rollback transaction.

=back

=head2 Utility methods

=head3 Methods

=over

=item C<meta>

Returns meta object. See C<ObjectDB::Meta>.

=item C<init_db>

Returns current C<DBI> instance.

=item C<is_modified>

Returns 1 if object is modified.

=item C<is_in_db>

Returns 1 if object is in database.

=item C<is_related_loaded>

Checks if related objects are loaded.

=item C<clone>

Clones object preserving all columns except primary or unique keys.

=item C<to_hash>

Converts object into a hash reference, including all preloaded objects.

=back

=head1 AUTHOR

Viacheslav Tykhanovskyi

=head1 COPYRIGHT AND LICENSE

Copyright 2013, Viacheslav Tykhanovskyi.

This module is free software, you may distribute it under the same terms as Perl.

=cut
