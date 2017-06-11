package SQL::Composer::Select;

use strict;
use warnings;

require Carp;
use Scalar::Util ();
use SQL::Composer::Join;
use SQL::Composer::Expression;
use SQL::Composer::Quoter;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = { table => $params{from} };
    bless $self, $class;

    $self->{from}    = $params{from};
    $self->{columns} = $params{columns};

    $self->{join} = $params{join};
    $self->{join} = [$self->{join}]
      if $self->{join} && ref $self->{join} ne 'ARRAY';

    $self->{quoter} =
      $params{quoter} || SQL::Composer::Quoter->new(driver => $params{driver});

    my $sql = '';
    my @bind;

    my @columns =
      map { $self->_prepare_column($_, $self->{from}, \@bind) }
      @{$self->{columns}};
    push @columns, $self->_collect_columns_from_joins($self->{join});

    $sql .= 'SELECT ';

    if (@columns) {
        $sql .= join ',', @columns;
    }

    $sql .= ' FROM ';
    $sql .= $self->_quote($params{from});

    if (my $joins = $self->{join}) {
        my ($join_sql, $join_bind) = $self->_build_join($joins);
        $sql .= $join_sql;
        push @bind, @$join_bind;
    }

    if (my $where = $params{where}) {
        if (!Scalar::Util::blessed($where)) {
            $where = SQL::Composer::Expression->new(
                default_prefix => $self->{from},
                quoter         => $self->{quoter},
                expr           => $where
            );
        }

        if (my $where_sql = $where->to_sql) {
            $sql .= ' WHERE ' . $where_sql;
            push @bind, $where->to_bind;
        }
    }

    if (my $group_bys = $params{group_by}) {
        $group_bys = [$group_bys] unless ref $group_bys eq 'ARRAY';

        my @group_by;
        foreach my $group_by (@$group_bys) {
            push @group_by,
              ref($group_by)
              ? $$group_by
              : $self->_quote($group_by, $self->{from});
        }

        $sql .= ' GROUP BY ' . join(', ', @group_by);
    }

    if (my $having = $params{having}) {
        if (!Scalar::Util::blessed($having)) {
            $having = SQL::Composer::Expression->new(
                default_prefix => $self->{from},
                quoter         => $self->{quoter},
                expr           => $having
            );
        }

        if (my $having_sql = $having->to_sql) {
            $sql .= ' HAVING ' . $having->to_sql;
            push @bind, $having->to_bind;
        }
    }

    if (my $order_by = $params{order_by}) {
        $sql .= ' ORDER BY ';
        if (ref $order_by) {
            if (ref($order_by) eq 'ARRAY') {
                my @order;
                while (my ($key, $value) = splice @$order_by, 0, 2) {
                    my $order_type;

                    if (ref $value) {
                        $order_type = ' ' . $$value;
                    }
                    else {
                        $value = '' unless defined $value;
                        $order_type = uc($value);
                        if ($order_type eq 'ASC' || $order_type eq 'DESC') {
                            $order_type = " $order_type";
                        }
                        else {
                            $order_type = '';
                        }
                    }

                    if (ref($key) eq 'SCALAR') {
                        push @order, $$key . $order_type;
                    }
                    else {
                        push @order,
                          $self->_quote($key, $self->{from}) . $order_type;
                    }
                }
                $sql .= join ',', @order;
            }
            elsif (ref($order_by) eq 'SCALAR') {
                $sql .= $$order_by;
            }
            else {
                Carp::croak('unexpected reference');
            }
        }
        else {
            $sql .= $self->_quote($order_by);
        }
    }

    if (defined(my $limit = $params{limit})) {
        $limit = 0 unless $limit =~ m/^[0-9]+$/;
        $sql .= ' LIMIT ' . $limit;
    }

    if (defined(my $offset = $params{offset})) {
        $offset = 0 unless $offset =~ m/^[0-9]+$/;
        $sql .= ' OFFSET ' . $offset;
    }

    if ($params{for_update}) {
        $sql .= ' FOR UPDATE';
    }

    $self->{sql}  = $sql;
    $self->{bind} = \@bind;

    return $self;
}

sub table { shift->{table} }

sub to_sql { shift->{sql} }
sub to_bind { @{shift->{bind} || []} }

sub from_rows {
    my $self = shift;
    my ($rows) = @_;

    my $result = [];
    foreach my $row (@$rows) {
        my $set = {};

        $self->_populate($set, $row, $self->{columns});

        $self->_populate_joins($set, $row, $self->{join});

        push @$result, $set;
    }

    return $result;
}

sub _prepare_column {
    my $self = shift;
    my ($column, $prefix, $bind) = @_;

    if (ref $column eq 'SCALAR') {
        return $$column;
    }
    elsif (ref $column eq 'HASH') {
        return (
            ref($column->{-col})
            ? (
                do {
                    my $value = $column->{-col};
                    if (ref $$value eq 'ARRAY') {
                        my $sql = $$value->[0];
                        push @$bind, @$$value[1 .. $#{$$value}];
                        $sql;
                    }
                    else {
                        $$value;
                    }
                  }
              )
            : $self->_quote($column->{-col}, $prefix)
          )
          . ' AS '
          . $self->_quote($column->{-as});
    }
    else {
        return $self->_quote($column, $prefix);
    }
}

sub _populate {
    my $self = shift;
    my ($set, $row, $columns) = @_;

    my $name;
    foreach my $column (@$columns) {
        if (ref($column) eq 'HASH') {
            $name = $column->{-as};
        }
        elsif (ref($column) eq 'SCALAR') {
            $name = $$column;
        }
        else {
            $name = $column;
        }

        $set->{$name} = shift @$row;
    }
}

sub _populate_joins {
    my $self = shift;
    my ($set, $row, $joins) = @_;

    foreach my $join (@$joins) {
        my $join_source = $join->{rel_name} || $join->{as} || $join->{source};

        $set->{$join_source} ||= {};
        $self->_populate($set->{$join_source}, $row, $join->{columns});

        if (my $subjoins = $join->{join}) {
            $subjoins = [$subjoins] unless ref $subjoins eq 'ARRAY';

            $self->_populate_joins($set->{$join_source}, $row, $subjoins);
        }
    }
}

sub _collect_columns_from_joins {
    my $self = shift;
    my ($joins) = @_;

    return () unless $joins && @$joins;

    my @join_columns;
    foreach my $join_params (@$joins) {
        if (my $join_columns = $join_params->{columns}) {
            push @join_columns, map {
                $self->_prepare_column($_,
                      $join_params->{as}
                    ? $join_params->{as}
                    : $join_params->{source})
            } @$join_columns;
        }

        if (my $subjoins = $join_params->{join}) {
            $subjoins = [$subjoins] unless ref $subjoins eq 'ARRAY';

            push @join_columns, $self->_collect_columns_from_joins($subjoins);
        }
    }

    return @join_columns;
}

sub _build_join {
    my $self = shift;
    my ($joins) = @_;

    $joins = [$joins] unless ref $joins eq 'ARRAY';

    my $sql = '';
    my @bind;
    foreach my $join_params (@$joins) {
        my $join =
          SQL::Composer::Join->new(quoter => $self->{quoter}, %$join_params);

        $sql .= ' ' . $join->to_sql;
        push @bind, $join->to_bind;

        if (my $subjoin = $join_params->{join}) {
            my ($subsql, $subbind) = $self->_build_join($subjoin);
            $sql .= $subsql;
            push @bind, @$subbind;
        }
    }

    return ($sql, \@bind);
}

sub _quote {
    my $self = shift;
    my ($column, $prefix) = @_;

    return $self->{quoter}->quote($column, $prefix);
}

1;
__END__

=pod

=head1

SQL::Composer::Select - SELECT statement

=head1 SYNOPSIS

    my $expr =
      SQL::Composer::Select->new(from => 'table', columns => ['a', 'b']);

    my $sql = $expr->to_sql;        # 'SELECT `table`.`a`,`table`.`b` FROM `table`'
    my @bind = $expr->to_bind;      # []

    $expr->from_rows([['c', 'd']]); # [{a => 'c', b => 'd'}]

=head1 DESCRIPTION

Builds C<SELECT> statement and converts (C<from_rows()>) received arrayref data
to hashref with appropriate column names as keys and joins as nested values.

=head2 Select column with C<AS>

    my $expr = SQL::Composer::Select->new(
        from    => 'table',
        columns => [{-col => 'foo' => -as => 'bar'}]
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`foo` AS `bar` FROM `table`'
    my @bind = $expr->to_bind; # []
    $expr->from_rows([['c']]); # [{bar => 'c'}]

=head2 Select column with raw SQL

    my $expr =
      SQL::Composer::Select->new(from => 'table', columns => [\'COUNT(*)']);

    my $sql = $expr->to_sql;   # 'SELECT COUNT(*) FROM `table`'
    my @bind = $expr->to_bind; # [];
    $expr->from_rows([['c']]); # [{'COUNT(*)' => 'c'}]

=head2 Select with C<WHERE>

For more details see L<SQL::Composer::Expression>.

    my $expr = SQL::Composer::Select->new(
        from    => 'table',
        columns => ['a', 'b'],
        where   => [a => 'b']
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #        FROM `table` WHERE `table`.`a` = ?'
    my @bind = $expr->to_bind; # ['b']

=head2 C<GROUP BY>

    my $expr = SQL::Composer::Select->new(
        from    => 'table',
        columns => ['a', 'b'],
        group_by => 'a'
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #        FROM `table` GROUP BY `table`.`a`'
    my @bind = $expr->to_bind; # []

=head2 C<ORDER BY>

    my $expr = SQL::Composer::Select->new(
        from     => 'table',
        columns  => ['a', 'b'],
        order_by => 'foo'
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #        FROM `table` ORDER BY `foo`'
    my @bind = $expr->to_bind; # []

=head2 C<ORDER BY> with sorting order

    my $expr = SQL::Composer::Select->new(
        from     => 'table',
        columns  => ['a', 'b'],
        order_by => [foo => 'desc', bar => 'asc']
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #      FROM `table`
                               #      ORDER BY `table`.`foo` DESC,
                               #               `table`.`bar` ASC'
    my @bind = $expr->to_bind; # []

=head2 C<LIMIT> and C<OFFSET>

    my $expr = SQL::Composer::Select->new(
        from    => 'table',
        columns => ['a', 'b'],
        limit   => 5,
        offset  => 10
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #        FROM `table` LIMIT 5 OFFSET 10'
    my @bind = $expr->to_bind; # [];

=head2 C<JOIN>

For more details see L<SQL::Composer::Join>.

    my $expr = SQL::Composer::Select->new(
        from    => 'table',
        columns => ['a'],
        join    => [
            {
                source  => 'table2',
                columns => ['b'],
                on      => [a => '1'],
                join    => [
                    {
                        source  => 'table3',
                        columns => ['c'],
                        on      => [b => '2']
                    }
                ]
            }
        ]
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table2`.`b`,`table3`.`c
                               #    FROM `table`
                               #    JOIN `table2` ON `table2`.`a` = ?
                               #    JOIN `table3` ON `table3`.`b` = ?'
    my @bind = $expr->to_bind; # ['1', '2'];

    $expr->from_rows([['c', 'd', 'e']]);
    # [{a => 'c', table2 => {b => 'd', table3 => {c => 'e'}}}];

=head2 C<FOR UPDATE>

    my $expr = SQL::Composer::Select->new(
        from       => 'table',
        columns    => ['a', 'b'],
        for_update => 1
    );

    my $sql = $expr->to_sql;   # 'SELECT `table`.`a`,`table`.`b`
                               #    FROM `table` FOR UPDATE'
    my @bind = $expr->to_bind; # []
};

=cut
