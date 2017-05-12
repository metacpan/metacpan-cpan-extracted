package ObjectDB::Table;

use strict;
use warnings;

our $VERSION = '3.19';

use constant DEFAULT_PAGE_SIZE => 10;

require Carp;
use SQL::Composer;
use SQL::Composer::Expression;
use ObjectDB;
use ObjectDB::Quoter;
use ObjectDB::With;
use ObjectDB::Meta;
use ObjectDB::Exception;
use ObjectDB::Util qw(execute merge merge_rows filter_columns);

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{class} = $params{class};
    $self->{dbh}   = $params{dbh};

    return $self;
}

sub meta {
    my $self = shift;

    return $self->{class}->meta;
}

sub dbh {
    my $self = shift;

    return $self->{dbh};
}

sub find {
    my $self = shift;

    my $params = merge { @_ }, {where => [], with => []};

    my $single = $params->{single} || $params->{first};

    unless ($single) {
        my $page = delete $params->{page};
        my $page_size = delete $params->{page_size} || DEFAULT_PAGE_SIZE;

        if (defined $page) {
            $page = 1 unless $page && $page =~ m/^\d+$/smx;
            $params->{offset} = ($page - 1) * $page_size;
            $params->{limit}  = $page_size;
        }
    }

    my $quoter = ObjectDB::Quoter->new(
        meta   => $self->meta,
        driver => $self->dbh->{Driver}->{Name},
    );
    my $where = SQL::Composer::Expression->new(
        quoter         => $quoter,
        expr           => $params->{where},
        default_prefix => $self->meta->table
    );
    my $having = SQL::Composer::Expression->new(
        quoter         => $quoter,
        expr           => $params->{having},
        default_prefix => $self->meta->table
    );
    my $with = ObjectDB::With->new(
        meta => $self->meta,
        with => [@{$params->{with}}, $quoter->with]
    );

    my $columns = filter_columns([$self->meta->columns], $params);

    my $join = $with->to_joins;
    push @$join, @{$params->{join}} if $params->{join};

    my $select = SQL::Composer->build(
        'select',
        driver     => $self->dbh->{Driver}->{Name},
        from       => $self->meta->table,
        columns    => $columns,
        join       => $join,
        where      => $where,
        limit      => $params->{limit},
        offset     => $params->{offset},
        order_by   => $params->{order_by},
        group_by   => $params->{group_by},
        having     => $having,
        for_update => $params->{for_update},
    );

    my ($rv, $sth) = execute($self->dbh, $select, context => $self);

    if (my $cb = $params->{each}) {
        while (my $row = $sth->fetchrow_arrayref) {
            my $rows = [[@$row]];
            $rows = $select->from_rows($rows);

            my $object =
              $self->meta->class->new(%{$rows->[0]});
            $object->is_in_db(1);

            $cb->($object);
        }

        return $self;
    }
    else {
        my $rows = $sth->fetchall_arrayref;
        return unless $rows && @$rows;

        $rows = $select->from_rows($rows);

        my @objects =
          map { $_->is_in_db(1) }
          map { $self->meta->class->new->set_columns(%{$_}) } @$rows;

        return $single ? $objects[0] : @objects;
    }
}

sub find_by_sql {
    my $self = shift;
    my ($sql, $bind, %params) = @_;

    {

        package ObjectDB::Stmt;
        sub new { bless {@_[1 .. $#_]}, $_[0] }
        sub to_sql  { shift->{sql} }
        sub to_bind { @{shift->{bind}} }
    }

    my @bind;
    if (ref $bind eq 'HASH') {
        while ($sql =~ s{:([[:alnum:]]+)}{?}) {
            push @bind, $bind->{$1};
        }
    }
    else {
        @bind = @$bind;
    }

    my $stmt = ObjectDB::Stmt->new(sql => $sql, bind => \@bind);

    my ($rv, $sth) = execute($self->dbh, $stmt, context => $self);

    my @column_names = @{$sth->{NAME_lc}};

    if (my $cb = $params{each}) {
        while (my $row = $sth->fetchrow_arrayref) {
            my $row_copy = [@$row];
            my %values;
            foreach my $column (@column_names) {
                $values{$column} = shift @$row_copy;
            }

            my $object = $self->meta->class->new(%values);
            $object->is_in_db(1);

            $cb->($object);
        }

        return $self;
    }
    else {
        my $rows = $sth->fetchall_arrayref;
        return () unless $rows && @$rows;

        my @objects;
        foreach my $row (@$rows) {
            my %values;
            foreach my $column (@column_names) {
                $values{$column} = shift @$row;
            }
            push @objects, $self->meta->class->new(%values)->is_in_db(1);
        }

        return @objects;
    }
}

sub update {
    my $self = shift;
    my (%params) = @_;

    my $sql = SQL::Composer->build(
        'update',
        driver => $self->dbh->{Driver}->{Name},
        table  => $self->meta->table,
        set    => $params{set},
        where  => $params{where},
    );

    my $rv = execute($self->dbh, $sql, context => $self);
    return $rv;
}

sub delete : method {
    my $self = shift;
    my (%params) = @_;

    my $sql = SQL::Composer->build(
        'delete',
        driver => $self->dbh->{Driver}->{Name},
        from   => $self->meta->table,
        where  => $params{where},
    );

    my $rv = execute($self->dbh, $sql, context => $self);
    return $rv;
}

sub count {
    my $self = shift;
    my (%params) = @_;

    my $quoter = ObjectDB::Quoter->new(
        driver => $self->dbh->{Driver}->{Name},
        meta   => $self->meta
    );
    my $where = SQL::Composer::Expression->new(
        quoter         => $quoter,
        expr           => $params{where},
        default_prefix => $self->meta->table
    );
    my $with =
      ObjectDB::With->new(meta => $self->meta, with => [$quoter->with]);

    my $joins = $with->to_joins;
    push @$joins, @{$params{join}} if $params{join};

    # We have to remove columns, because:
    # 1) we don't need them
    # 2) PostgreSQL complains
    delete $_->{columns} for @$joins;

    my $select = SQL::Composer->build(
        'select',
        driver   => $self->dbh->{Driver}->{Name},
        from     => $self->meta->table,
        columns  => [{-col => \'COUNT(*)', -as => 'count'}],
        where    => $where,
        join     => $joins,
        group_by => $params{group_by},
    );

    my ($rv, $sth) = execute($self->dbh, $select, context => $self);

    my $results    = $sth->fetchall_arrayref;
    my $row_object = $select->from_rows($results);

    return $row_object->[0]->{count};
}

1;
__END__

=pod

=head1 NAME

ObjectDB::Table - actions on tables

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

    my @books = MyBook->table->find(
        with     => 'author',
        order_by => [title => 'ASC'],
        page     => 1,
        per_page => 10
    );

=head1 DESCRIPTION

ObjectDB::Table allows to perform actions on table: find, update, delete many
rows at a time.

=head3 Methods

=over

=item C<find>

Finds specific rows.

    my @books = MyBook->table->find;
    my @books = MyBook->table->find(where => [...]);
    my @books = MyBook->table->find(where => [...], order_by => [...]);
    my @books =
      MyBook->table->find(where => [...], order_by => [...], group_by => [...]);

=item C<count>

A convenient method for counting.

    my $total_books = MyBook->table->count;

=item C<update>

Updates many rows at a time.

    MyBook->table->update(set => {author_id => 1}, where => [author_id => 2]);

=item C<delete>

Deletes many rows at a time.

    MyBook->table->delete;
    MyBook->table->delete(where => [...]);

=back

=cut
