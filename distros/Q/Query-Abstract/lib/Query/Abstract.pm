package Query::Abstract;

use v5.10;
use strict;
use warnings;

use Class::Load qw/load_class/;
use Carp qw/croak/;
use Data::Dumper;

our $VERSION = '0.01';

sub new {
    my $class  = shift;
    my %args   = @_;
    my $driver = $args{driver};
    croak "Wrong driver" unless ref $driver;

    my $self = bless {}, $class;

    if ( ref $driver eq 'ARRAY' ) {
        my $driver_class = 'Query::Abstract::Driver::' . $driver->[0];
        load_class($driver_class);

        $self->{driver} = $driver_class->new( @{ $driver->[1] || [] } );
    } elsif ( $driver->isa('Query::Abstract::Driver::Base') ) {
        $self->{driver} = $driver;
    } else {
        croak "Wrong driver [$driver]";
    }

    $self->init();

    return $self;
}

sub init {
    my $self = shift;
    $self->{driver}->init(@_);
}


sub convert_query {
    my ($self, @args) = @_;
    my %query = $self->_normalize_query(@args);
    return $self->{driver}->convert_query(%query);
}

sub convert_filter {
    my ($self, $filter) = @_;

    return $self->{driver}->convert_filter(
        $self->_normalize_where($filter)
    );
}


sub convert_sort {
    my ($self, $sort_by) = @_;

    return $self->{driver}->convert_sort(
        $self->_normalize_sort_by($sort_by)
    );
}

sub _normalize_query {
    my $self = shift;
    my %query;

    if ( ref($_[0]) eq 'ARRAY' ) {
        $query{where} = $_[0];
    } else {
        %query = @_;
    }

    my $where   = $self->_normalize_where($query{where});
    my $sort_by = $self->_normalize_sort_by($query{sort_by});

    return (
        where   => $where,
        sort_by => $sort_by
    );
}

sub _normalize_where {
    my ($self, $where) = @_;
    return [] unless $where;

    my @norm_where;

    for (my $i = 0; $i < @$where; $i+=2) {
        my $field = $where->[$i];
        my ($oper, $restriction);
        if ( ref($where->[$i+1]) eq 'HASH' ) {
            my $condition = $where->[$i+1];
            ($oper, $restriction) = %$condition;
        } else {
            $oper = ref($where->[$i+1]) eq 'ARRAY' ? 'in' : 'eq';
            $restriction = $where->[$i+1];
        }

        die "UNSUPPORTED OPERATOR [$oper]"
            unless grep { $oper eq $_ } qw/eq in ne gt lt le gt ge like < > <= >=/;

        push @norm_where, $field => {$oper => $restriction} ;
    }

    return \@norm_where;
}

sub _normalize_sort_by {
    my ($self, $sort_by) = @_;
    return [] unless $sort_by;
    return $sort_by if ref $sort_by eq 'ARRAY';
    # TODO add validation

    return [ split(/\s*,\s*/, $sort_by, 2) ];
}

1; # End of Query::Abstract

=head1 NAME

Query::Abstract - Create filters in Perlish way and transforms them into coderefs or SQL

=head1 SYNOPSIS

    # Pure Perl filtering
    my $qa = Query::Abstract->new( driver => ['ArrayOfHashes'] );

    my $query_sub = $qa->convert_query(
        where => [
            name => 'John',
            age => { '>' => 25 },
            last_name => { like => 'ing' }
        ],
        sort_by => 'last_name DESC, login ASC'
    );

    $filtered_and_sorted_users = $query_sub->(\@users);

    # Preparing SQL statement
    my $qa = Query::Abstract->new( driver => ['SQL' => [table => 'users']] );

    ## The same but explicilty creating driver object.
    my $qa = Query::Abstract->new( driver => Query::Abstract::Driver::SQL->new(table => 'users') );

    my $sql_statement = $qa->convert_query(
        where => [
            name => 'John',
            age => { '>' => 25 },
            last_name => { like => 'ing' }
        ],
        sort_by => 'last_name DESC, login ASC'
    );

=head1 WARNING

    This software is under the heavy development and considered ALPHA quality.
    Things might be broken, not all features have been implemented, and APIs will be likely to change.
    YOU HAVE BEEN WARNED.

=head1 DESCRIPTION

L<Query::Abstract> - allows you to write queries and then tranform them into another format(depends in driver). Queries are almost compatible with Rose::DB::Object queries.
This module apperared because I wanted to have pure Perl queries but with ability to convert them into SQL(or other format).

Currently this module has two standard drivers - ArrayOfHashes and SQL.(You can write your own)

=head1 METHODS

=head2 C<convert_filter>

    $self->convert_filter([ name => 'John', age => { '>' => 25 }, last_name => { like => 'ing' } ]);

"SQL" Driver will return 'WHERE' clause and bind values.

"ArrayOfHashes" will return a coderef which takes hashref and returns true or false depending on condition testing result.

    my $tester = $self->convert_filter([ name => 'John', age => { '>' => 25 }, last_name => { like => 'ing' } ]);
    @filtered = grep { $tester->($_) } ( {name => 'Anton', age => 37, last_name => 'Corning'}, {name => 'John'} ... )

=head2 C<convert_sort>

    $self->convert_sort('name DESC, age ASC, last_name DESC');

"SQL" Driver will return 'ORDER BY' clause.

"ArrayOfHashes" will return a coderef for "sort" function

    my $sort_sub = $self->convert_sort(...);
    @sorted = sort $sort_sub @data;

=head2 C<convert_query>

    $self->convert_query( where => [name => 'John'], sort_by => 'last_name DESC' );

"SQL" Driver will return 'SELECT' with 'WHERE' and 'ORDER BY' conditions.

"ArrayOfHashes" will return a coderef for quering data

    my $query_sub = $self->convert_query(...);
    $filtered_and_sorted = $query_sub->( \@data );

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Query-Abstract>

=head1 SEE ALSO

L<Rose::DB::Object::QueryBuilder>, L<SQL::Abstract>, L<SQL::Maker>

=cut