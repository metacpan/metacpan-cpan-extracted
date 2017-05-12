package Query::Abstract::Driver::SQL;

our $VERSION = '0.01';

use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Carp;

use base 'Query::Abstract::Driver::Base';

my %CONVERTORS = (
    'eq'   => sub {"$_[0] = ?" },
    'ne'   => sub {"$_[0] <> ?" },
    'lt'   => sub {"$_[0] < ?" },
    'le'   => sub {"$_[0] <= ?" },
    'gt'   => sub {"$_[0] > ?" },
    'ge'   => sub {"$_[0] >= ?" },
    '<'    => sub {"$_[0] < ?" },
    '>'    => sub {"$_[0] > ?" },
    '<='   => sub {"$_[0] <= ?" },
    '>='   => sub {"$_[0] >= ?" },
    'in'   => sub {"$_[0] IN (" . join(', ', ('?') x @{$_[1]} ) . ")"},
    'like' => sub {"$_[0] LIKE ?" },
);

sub  new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(%args);
    croak "Table name is required!" unless $self->{table};

    return $self;
}

sub convert_query {
    my ($self, %query) = @_;

    my $select_sql = "SELECT * FROM $self->{table}";

    my ($where_sql, $bind_values) = $self->convert_filter( $query{where} );
    $select_sql .= " $where_sql" if $where_sql;

    my $sort_sql   = $self->convert_sort( $query{sort_by} );
    $select_sql .= " $sort_sql" if $sort_sql;

    return( $select_sql, $bind_values );
}


sub convert_filter {
    my ( $self, $where ) = @_;

    my @rules;
    my @bind_values;
    for ( my $i = 0; $i < @$where; $i += 2 ) {
        my $field = $where->[$i];
        my $condition = $where->[$i+1];
        my ($oper, $values) = %$condition;

        push @rules, $CONVERTORS{$oper}->($field, $values);
        push @bind_values, @{ ref($values) ? $values : [$values] };
    }

    if (@rules) {
        my $where_str = 'WHERE ' . join(' AND ', @rules);
        return( $where_str, \@bind_values );
    } else {
        return '';
    }
}

sub convert_sort {
    my ( $self, $sort_by ) = @_;
    my @rules;

    foreach my $sort_rule ( @$sort_by ) {
        my ($field, $order) = split(/\s+/, $sort_rule, 2);
        $order ||='ASC';

        push @rules, "$field \U$order\E";
    }

    if (@rules) {
        return @rules ? 'ORDER BY ' . join(' ,', @rules) : '';
    } else {
        return '';
    }
}

1;