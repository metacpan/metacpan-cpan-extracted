package SQL::QueryBuilder::Flex;

use strict;
use warnings;
use List::Util qw(first);
use SQL::QueryBuilder::Flex::Join;
use SQL::QueryBuilder::Flex::Exp;
use SQL::QueryBuilder::Flex::Writer;
use base 'SQL::QueryBuilder::Flex::Statement';

our $VERSION = '0.01';

sub get_query { $_[0] };

sub import {
    my ($class, $alias) = @_;

    if ($alias) {
        no strict 'refs';
        *{ $alias =~ /::/ ? $alias : caller(0).'::'.$alias } = sub () { __PACKAGE__ };
    }
}

sub new {
    my ($class, @options) = @_;
    my $self = $class->SUPER::new(
        columns    => [],
        from       => [],
        update     => [],
        insert     => [],
        join       => [],
        where      => undef,
        group_by   => [],
        having     => undef,
        order_by   => [],
        offset     => undef,
        limit      => undef,
        options    => {},
        union      => [],
        @options,
    );
    return $self;
}

sub options {
    my ($self, @options) = @_;
    $self->{options}{$_} = 1 for @options;
    return $self;
}

sub select {
    my ($self, @columns) = @_;

    # Create instance if this method has been called directly
    if (!ref $self) {
        $self = __PACKAGE__->new;
    }

    # Unpack hash refs to "$key AS $value" lines
    @columns = grep { $_ } map {
        if (ref $_ eq 'HASH') {
            my $hash = $_;
            map { "$_ AS $hash->{$_}" } keys %{$hash};
        } else {
            $_;
        }
    } @columns;

    push @{ $self->{columns} }, @columns;
    return $self;
}

sub from {
    my ($self, $table, $alias) = @_;
    push @{ $self->{from} }, [ $table => $alias ];
    return $self;
}

sub update {
    my ($self, $table, $alias) = @_;

    # Create instance if this method has been called directly
    if (!ref $self) {
        $self = __PACKAGE__->new;
    }

    push @{ $self->{update} }, [ $table => $alias ];

    return $self;
}

sub insert {
    my ($self, $table, @columns) = @_;

    # Create instance if this method has been called directly
    if (!ref $self) {
        $self = __PACKAGE__->new;
    }

    push @{ $self->{insert} }, [ $table => undef ];

    $self->set(@columns);

    return $self;
}

sub set {
    my ($self, @columns) = @_;

    while (my $column = shift @columns) {
        if (ref $column) {
            push @{ $self->{columns} }, $column;
        }
        else {
            my $value = shift @columns;
            push @{ $self->{columns} }, [$column, $value];
        }
    }

    return $self;
}

sub where {
    my ($self, $cond, @values) = @_;
    my $exp = $self->{where} ||= SQL::QueryBuilder::Flex::Exp->new(
        parent => $self,
    );
    return $cond
        ? $exp->and($cond, @values)->parent()
        : $exp
    ;
}

sub having {
    my ($self, $cond, @values) = @_;
    my $exp = $self->{having} ||= SQL::QueryBuilder::Flex::Exp->new(
        parent => $self,
    );
    return $cond
        ? $exp->and($cond, @values)->parent()
        : $exp
    ;
}

sub group_by {
    my ($self, $column, $order, @params) = @_;
    push @{ $self->{group_by} }, [ $column => $order, @params ];
    return $self;
}

sub order_by {
    my ($self, $column, $order, @params) = @_;
    push @{ $self->{order_by} }, [ $column => $order, @params ];
    return $self;
}

sub order_by_asc {
    my ($self, $column, @params) = @_;
    return $self->order_by($column, 'ASC', @params);
}

sub order_by_desc {
    my ($self, $column, @params) = @_;
    return $self->order_by($column, 'DESC', @params);
}

sub limit {
    my ($self, $offset, $limit) = @_;
    @$self{qw/offset limit/} = (scalar(@_) == 2)
        ? (undef, $offset)
        : ($offset, $limit)
    ;
    return $self;
}

sub offset {
    my ($self, $offset) = @_;
    $self->{offset} = $offset;
    return $self;
}

sub union {
    my ($self, $query) = @_;
    push @{ $self->{union} }, $query;
    return $self;
}

sub _join {
    my ($self, @options) = @_;
    my $join = SQL::QueryBuilder::Flex::Join->new(
        parent => $self,
        @options,
    );
    push @{ $self->{join} }, $join;
    return $join;
}

sub inner_join {
    my ($self, $table, $alias) = @_;
    return $self->_join(
        type  => 'INNER',
        table => $table,
        alias => $alias,
    );
}

sub left_join {
    my ($self, $table, $alias) = @_;
    return $self->_join(
        type  => 'LEFT',
        table => $table,
        alias => $alias,
    );
}

sub right_join {
    my ($self, $table, $alias) = @_;
    return $self->_join(
        type  => 'RIGHT',
        table => $table,
        alias => $alias,
    );
}

sub _build_select {
    my ($self, $writer, $indent) = @_;

    $writer->write(
        join(' ', 'SELECT', sort keys %{ $self->{options} })
        , $indent
    );

    my $columns  = $self->{columns};
    my $last     = scalar(@$columns) - 1;
    my ($column, $alias, @params);
    for(my $i = 0; $i <= $last; $i++) {
        $column = $columns->[$i];
        if (ref $column) {
            ($column, $alias, @params) = @$column;
            $writer->add_params(@params) if scalar @params;
            $column = join(' AS ', $column, $alias) if $alias;
        }
        $writer->write($column . ($i == $last ? '' : ',') , $indent + 1);
    }

    return;
}

sub _build_from {
    my ($self, $writer, $indent) = @_;

    $writer->write('FROM', $indent);

    my $from_list = $self->{from};
    my $last      = scalar(@$from_list) - 1;
    my ($table, $alias);
    for(my $i = 0; $i <= $last; $i++) {
        ($table, $alias) = @{ $from_list->[$i] };
        my $term =  $i == $last ? '' : ',';
        if (ref $table) {
            $writer->write('(', $indent);
            $table->build($writer, $indent + 1);
            $writer->write(') AS ' . $alias . $term, $indent + 1);
        }
        else {
            $writer->write( ($alias ? join(' ', $table, $alias) : $table) . $term, $indent + 1 );
        }
    }

    return;
}

sub _build_update {
    my ($self, $writer, $indent) = @_;

    $writer->write(
        join(' ', 'UPDATE', keys %{ $self->{options} })
        , $indent
    );

    my $update_list = $self->{update};
    my $last        = scalar(@$update_list) - 1;
    my ($table, $alias);
    for(my $i = 0; $i <= $last; $i++) {
        ($table, $alias) = @{ $update_list->[$i] };
        my $term =  $i == $last ? '' : ',';
        if (ref $table) {
            $writer->write('(', $indent);
            $table->build($writer, $indent + 1);
            $writer->write(') AS ' . $alias . $term, $indent + 1);
        }
        else {
            $writer->write( ($alias ? join(' ', $table, $alias) : $table) . $term, $indent + 1 );
        }
    }

    return;
}

sub _build_insert {
    my ($self, $writer, $indent) = @_;

    $writer->write(
        join(' ', 'INSERT', keys %{ $self->{options} })
        , $indent
    );

    my $insert_list = $self->{insert};
    my $last        = scalar(@$insert_list) - 1;
    my ($table, $alias);
    for(my $i = 0; $i <= $last; $i++) {
        ($table, $alias) = @{ $insert_list->[$i] };
        my $term =  $i == $last ? '' : ',';
        $writer->write( ($alias ? join(' ', $table, $alias) : $table) . $term, $indent + 1 );
    }

    return;
}

sub _build_set {
    my ($self, $writer, $indent) = @_;

    $writer->write('SET', $indent);

    my $columns  = $self->{columns};
    my $last     = scalar(@$columns) - 1;
    for (my $i = 0; $i <= $last; $i++) {
        my ($column, @params) = @{ $columns->[$i] };
        if (scalar @params) {
            my $firstValue = shift @params;
            if (ref $firstValue) {
                $writer->add_params(@params) if scalar @params;
                $column .= "=$$firstValue";
            }
            else {
                $writer->add_params($firstValue, @params);
                $column .= '=?';
            }
        }
        $writer->write($column . ($i == $last ? '' : ',') , $indent + 1);
    }

    return;
}

sub _build_join {
    my ($self, $writer, $indent) = @_;
    foreach my $join (@{ $self->{join} }) {
        $join->build($writer, $indent + 1);
    }
    return;
}

sub _build_where {
    my ($self, $writer, $indent) = @_;
    if ( $self->{where} && !$self->{where}->is_empty() ) {
        $writer->write('WHERE', $indent);
        $self->{where}->build($writer, $indent + 1);
    }
    return;
}

sub _build_having {
    my ($self, $writer, $indent) = @_;
    if ( $self->{having} && !$self->{having}->is_empty() ) {
        $writer->write('HAVING', $indent);
        $self->{having}->build($writer, $indent + 1);
    }
    return;
}

sub _build_group_by {
    my ($self, $writer, $indent) = @_;
    return unless scalar(@{ $self->{group_by} });
    $writer->write(
        join(' ', 'GROUP BY',
            join(', ', map {
                my ($column, $order, @params) = @$_;
                $writer->add_params(@params);
                $order ? join(' ', $column, $order) : $column;
            } @{ $self->{group_by} })
        ),
        $indent
    );
    return;
}

sub _build_order_by {
    my ($self, $writer, $indent) = @_;
    return unless scalar(@{ $self->{order_by} });
    $writer->write(
        join(' ', 'ORDER BY',
            join(', ', map {
                my ($column, $order, @params) = @$_;
                $writer->add_params(@params);
                $order ? join(' ', $column, $order) : $column;
            } @{ $self->{order_by} })
        ),
        $indent
    );
    return;
}

sub _build_limit {
    my ($self, $writer, $indent) = @_;
    return unless defined $self->{limit};
    if ( defined $self->{offset} ) {
        $writer->write('LIMIT ?, ?', $indent, @$self{qw/offset limit/});
        $writer->add_params( @$self{qw/offset limit/} );
    }
    else {
        $writer->write('LIMIT ?', $indent);
        $writer->add_params( $self->{limit} );
    }
    return;
}

sub do_build {
    my ($self, $writer, $indent) = @_;

    $indent ||= 0;

    if (scalar @{ $self->{from} }) {
        $self->_build_select ($writer, $indent);
        $self->_build_from   ($writer, $indent);
        $self->_build_join   ($writer, $indent);
    }
    elsif (scalar @{ $self->{update} }) {
        $self->_build_update ($writer, $indent);
        $self->_build_join   ($writer, $indent);
        $self->_build_set    ($writer, $indent);
    }
    else {
        $self->_build_insert ($writer, $indent);
        $self->_build_set    ($writer, $indent);
    }
    $self->_build_where  ($writer, $indent);
    $self->_build_group_by($writer, $indent);
    $self->_build_having ($writer, $indent);
    $self->_build_order_by($writer, $indent);
    $self->_build_limit  ($writer, $indent);

    foreach my $query ( @{ $self->{union} } ) {
        $writer->write('UNION', $indent);
        $query->do_build($writer, $indent);
    }

    return;
}

sub clear_options {
    my ($self) = @_;
    $self->{options} = {};
    return $self;
}

sub clear_select {
    my ($self) = @_;
    $self->{columns} = [];
    return $self;
}

sub clear_from {
    my ($self) = @_;
    $self->{from} = [];
    return $self;
}

sub clear_join {
    my ($self) = @_;
    $self->{join} = [];
    return $self;
}

sub clear_where {
    my ($self) = @_;
    $self->{where} = undef;
    return $self;
}

sub clear_having {
    my ($self) = @_;
    $self->{having} = undef;
    return $self;
}

sub clear_order_by {
    my ($self) = @_;
    $self->{order_by} = [];
    return $self;
}

sub clear_group_by {
    my ($self) = @_;
    $self->{group_by} = [];
    return $self;
}

sub delete_column {
    my ($self, $name) = @_;
    my @columns = grep {
        if (ref $_) {
            my ($column, $alias) = @$_;
            if (defined $alias) {
                $column = $alias;
            }
            ref $name ? $column !~ $name : $column ne $name
        }
        else {
            ref $name ? $_ !~ $name : $_ ne $name
        }
    } @{ $self->{columns} };
    $self->{columns} = \@columns;
    return $self;
}

sub delete_from {
    my ($self, $name) = @_;
    my @from = grep {
        my $alias = $_->[1] || $_->[0];
        ref $name ? $alias !~ $name : $alias ne $name
    } @{ $self->{from} };
    $self->{from} = \@from;
    return $self;
}

sub delete_join {
    my ($self, $name) = @_;
    my @join = grep {
        my $alias = $_->alias() || $_->table();
        ref $name ? $alias !~ $name : $alias ne $name
    } @{ $self->{join} };
    $self->{join} = \@join;
    return $self;
}

sub find_from {
    my ($self, $name) = @_;
    my $from = first {
        my $alias = $_->[1] || $_->[0];
        ref $name ? $alias =~ $name : $alias eq $name
    } @{ $self->{from} };
    return $from;
}

sub find_join {
    my ($self, $name) = @_;
    my $join = first {
        my $alias = $_->alias() || $_->table();
        ref $name ? $alias =~ $name : $alias eq $name
    } @{ $self->{join} };
    return $join;
}

1;
__END__

=head1 NAME

SQL::QueryBuilder::Flex - Yet another flexible SQL builder

=head1 SYNOPSIS

    use SQL::QueryBuilder::Flex 'SQL';

    my ($stmt, @bind) = SQL
        ->select(qw/user_id name/)
        ->from('user')
        ->where('user_id = ?', 1)
        ->to_sql
    ;
    # $stmt: SELECT user_id, name FROM user
    # @bind: (1)


    my ($stmt, @bind) = SQL
        ->select(
            'user_id',
            'now() AS now',
            ['LEFT(name, ?)', 'name', 5],
            {
                name     => 'user_name',
                group_id => 'group_id',
            },
        )
        ->from(qw/user u/)
        ->left_join(
                SQL
                    ->select('user_id', 'SUM(balance) AS balance')
                    ->from('balance')
                    ->where
                        ->or('group_id = ?', 1)
                        ->or('group_id = ?', 2)
                    ->group_by('user_id')
                , 'b'
            )->on
                ->and('u.user_id = b.user_id')
                ->and('b.balance > 0')
        ->where
            ->and('u.user_id = ?', 7)
            ->and('b.balance BETWEEN ? AND ?', 100, 200)
            ->and_exp
                ->or('group_id = ?', 1)
                ->or('group_id = ?', 2)
                ->or_in('group_id', 5, 6)
            ->parent
        ->group_by('LEFT(name, ?)', undef, 2)
        ->order_by(qw/name desc/)
        ->limit(10)
        ->to_sql(1)
    ;
    # SELECT
    #   user_id,
    #   now() AS now,
    #   LEFT(name, ?) AS name,
    #   group_id AS group_id,
    #   name AS user_name
    # FROM
    #   user u
    #   LEFT JOIN (
    #     SELECT
    #       user_id,
    #       SUM(balance) AS balance
    #     FROM
    #       balance
    #     WHERE
    #       group_id = ?
    #       OR group_id = ?
    #     GROUP BY user_id
    #   ) AS b
    #   ON
    #     u.user_id = b.user_id
    #     AND b.balance > 0
    # WHERE
    #   u.user_id = ?
    #   AND b.balance BETWEEN ? AND ?
    #   AND (
    #     group_id = ?
    #     OR group_id = ?
    #     OR group_id IN(?,?)
    #   )
    # GROUP BY LEFT(name, ?)
    # ORDER BY name desc
    # LIMIT ?
    # @bind: (5, 1, 2, 7, 100, 200, 1, 2, 5, 6, 2, 10)


    my ($stmt, @bind) = SQL
        ->select('name')
        ->from('user1')
        ->union( SQL->select('name')->from('user2') )
        ->to_sql
    ;
    # SELECT name FROM user1 UNION SELECT name FROM user2


    my ($stmt, @bind) = SQL
        ->update('user')
        ->set(
            status  => 'expired',
            updated => \'NOW()',
        )
        ->where('(last_activity + INTERVAL ? DAY) < NOW()', 30)
        ->to_sql
    ;
    # UPDATE user SET status=?, updated=NOW() WHERE (last_activity + INTERVAL ? DAY) < NOW()
    # @bind: ('expired', 30)


    my ($stmt, @bind) = SQL
        ->insert('user',
            name    => 'User',
            status  => 'active',
            updated => \'NOW()',
        )
        ->options(qw/LOW_PRIORITY IGNORE/)
        ->to_sql
    ;
    # INSERT LOW_PRIORITY IGNORE user SET name=?, status=?, updated=NOW()
    # @bind: ('User', 'active')


    my $q1 = SQL
        ->select(qw/user_id balance/)
        ->from('balance')
    ;
    my $q2 = SQL
        ->select(qw/
            name
            b.balance
        /)
        ->from('user')
        ->left_join($q1, 'b')->using('user_id')->parent
    ;
    $q2->where('b.balance < 0') if 1;
    my ($stmt, @bind) = $q2->to_sql(1);
    # SELECT
    #   name,
    #   b.balance
    # FROM
    #   user
    #   LEFT JOIN (
    #     SELECT
    #       user_id,
    #       balance
    #     FROM
    #       balance
    #   ) AS b
    #   USING (user_id)
    # WHERE
    #   b.balance < 0


=head1 DESCRIPTION

SQL::QueryBuilder::Flex is yet another flexible SQL builder.

=head1 METHODS

=over 4

=item new(<%options>)

Create instance.

my $query = SQL::QueryBuilder::Flex->new()

=item to_sql(<indent>)

Build SQL.

my ($stmt, @bind) = $query->to_sql()

=back

=head1 AUTHOR

=over 4

Yuriy Ustushenko, E<lt><yoreek@yahoo.com>E<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Yuriy Ustushenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

