# ABSTRACT: mock repository - table class
package Test::PONAPI::Repository::MockDB::Table;

use Moose;

use Test::PONAPI::Repository::MockDB::Table::Relationships;

has [qw/TYPE TABLE ID_COLUMN/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has COLUMNS => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has RELATIONS => (
    is  => 'ro',
    isa => 'HashRef[Test::PONAPI::Repository::MockDB::Table::Relationships]',
    default => sub { {} },
);

sub insert_stmt {
    my ($self, %args) = @_;

    my $table  = $args{table};
    my $values = $args{values};

    # NOTE: this is a bunch of bad practices rolled together.
    # We're crafting our own SQL and not escaping the table/columns,
    # as well as using sqlite-specific features.
    # Ordinarily, you'd use DBIx::Class or at least SQL::Composer
    # for this, but we got reports that packaging PONAPI::Server
    # becomes hugely complex by adding either of those as dependencies.
    # Since this is just for testing, let's forgo a couple of good practices
    # and do it all manually.
    my @keys   = keys %$values;
    my @values = values %$values;
    my $sql = "INSERT INTO $table " . (@keys
        ? '(' . join( ",", @keys) . ') VALUES (' . join(',', ('?') x @keys) . ')'
        : 'DEFAULT VALUES');

    my $stmt = {
        sql  => $sql,
        bind => \@values,
    };

    return $stmt;
}

sub delete_stmt {
    my ($self, %args) = @_;

    my $table = $args{table};
    my $where = $args{where};

    my @keys  = keys %$where;
    my @values = values %$where;

    my $sql = "DELETE FROM $table WHERE "
            . join " AND ", map "$_=?", @keys;

    my $stmt = { sql => $sql, bind => \@values };

    return $stmt;
}

sub select_stmt {
    my ($self, %args) = @_;

    my $type    = $args{type};
    my $filters = $self->_stmt_filters($type, $args{filter});

    my %limit   = %{ $args{page} || {} };
    my $sort    = $args{sort} || [];

    my @order_by = map {
        my ($desc, $col) = /\A(-?)(.+)\z/s;
        join ' ', $col => uc( $desc ? 'desc' : 'asc' );
    } @$sort;

    my $columns = $self->_stmt_columns(\%args);
    my @values = map { ref($_) ? @$_ : $_ } values %$filters;
    my $sql = join "\n",
            'SELECT ' . join(',', @$columns),
            'FROM '   . $type,
            (%$filters
                ? 'WHERE ' . join(' AND ', map {
                    my $val = $filters->{$_};
                    ref($val)
                        ? "$_ IN (@{[ join ',', ('?') x @$val ]})"
                        : "$_=?"
                } keys %$filters)
                : ''
            ),
            (@order_by ? 'ORDER BY ' . join(', ', @order_by) : ''),
            (%limit    ? "LIMIT $limit{limit} OFFSET $limit{offset}" : '' );

    my $stmt = {
        sql  => $sql,
        bind => \@values,
    };

    return $stmt;
}

sub update_stmt {
    my ($self, %args) = @_;

    my $id     = $args{id};
    my $table  = $args{table};
    my $values = $args{values} || {};
    my $where  = $args{where};

    my @cols   = keys %$values;
    my @values = values %$values;
    push @values, values %$where;

    my $sql = join "\n",
            "UPDATE $table",
            "SET "   . join(', ', map "$_=?", @cols),
            "WHERE " . join( ' AND ', map "$_=?", keys %$where );

    my $stmt = {
        sql  => $sql,
        bind => \@values,
    };

    return $stmt;
}

sub _stmt_columns {
    my $self = shift;
    my $args = shift;
    my ( $fields, $type ) = @{$args}{qw< fields type >};

    my $ref = ref $fields;

    return [ $self->ID_COLUMN, @$fields ] if $ref eq 'ARRAY';

    $ref eq 'HASH' and exists $fields->{$type}
        or return $self->COLUMNS;

    my @fields_minus_relationship_keys =
        grep { !exists $self->RELATIONS->{$_} }
        @{ $fields->{$type} };

    return +[ $self->ID_COLUMN, @fields_minus_relationship_keys ];
}

sub _stmt_filters {
    my ( $self, $type, $filter ) = @_;

    return $filter if $self->TABLE ne $type;

    return +{
        map  { $_  => $filter->{$_} }
        grep { exists $filter->{$_} }
        @{ $self->COLUMNS }
    };
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PONAPI::Repository::MockDB::Table - mock repository - table class

=head1 VERSION

version 0.003003

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
