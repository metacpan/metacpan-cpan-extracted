package SQL::OOP::Select;
use strict;
use warnings;
use SQL::OOP::Base;
use SQL::OOP::Where;
use SQL::OOP::Order;
use base qw(SQL::OOP::Command);

sub ARG_FIELDS()    {1} ## no critic
sub ARG_FROM()      {2} ## no critic
sub ARG_WHERE()     {3} ## no critic
sub ARG_GROUPBY()   {4} ## no critic
sub ARG_ORDERBY()   {5} ## no critic
sub ARG_LIMIT()     {6} ## no critic
sub ARG_OFFSET()    {7} ## no critic

### ---
### Get Names of set arguments in array ref
### ---
sub KEYS {
    return
    [ARG_FIELDS, ARG_FROM, ARG_WHERE,
     ARG_GROUPBY, ARG_ORDERBY, ARG_LIMIT, ARG_OFFSET];
}

### ---
### Get prefixes for each clause in hash ref
### ---
sub PREFIXES {
    return {
        ARG_FIELDS()    => 'SELECT',
        ARG_FROM()      => 'FROM',
        ARG_WHERE()     => 'WHERE',
        ARG_GROUPBY()   => 'GROUP BY',
        ARG_ORDERBY()   => 'ORDER BY',
        ARG_LIMIT()     => 'LIMIT',
        ARG_OFFSET()    => 'OFFSET',
    }
}

### ---
### Constructor
### ---
sub new {
    my ($class, %hash) = @_;
    return $class->SUPER::new(%hash);
}

### ---
### Set elements
### ---
sub set {
    my ($class, %hash) = @_;
    return $class->SUPER::set(%hash);
}

### ---
### Get SQL snippet
### ---
sub to_string {
    my $self = shift;
    local $SQL::OOP::Base::quote_char = $self->quote_char;
    return $self->SUPER::to_string(@_);
}

### ---
### Get binded values in array
### ---
sub bind {
    return shift->SUPER::bind(@_);
}

1;

__END__

=head1 NAME

SQL::OOP::Select

=head1 SYNOPSIS

    my $where = SQL::OOP::Where->new();
    my $select = SQL::OOP::Select->new();
    
    # set clause by plain text
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => 'some_table',
        $select->ARG_WHERE  => q("some_filed" > 5)
        $select->ARG_GROUPBY   => 'some_field',
        $select->ARG_ORDERBY   => 'some_field ASC',
        $select->ARG_LIMIT     => '10',
        $select->ARG_OFFSET    => '2',
    );

    # reset clauses using objects
    my $where = SQL::OOP::Where->new();
    $select->set(
        $select->ARG_FIELDS => SQL::OOP::ID->new('some_field'),
        $select->ARG_FROM   => SQL::OOP::ID->new('some_table'),
        $select->ARG_WHERE  => $where->cmp('=', "some_fileld", 'value')
        $select->ARG_ORDERBY=> SQL::OOP::Order->new('a', 'b'),
    );
    
    # clause can treats subs so that temporary variables don't mess around
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => 'some_table',
        $select->ARG_WHERE  => sub {
            my $where = SQL::OOP::Where->new();
            return $where->cmp('=', "some_fileld", 'value');
        }
    );
    
    # SQL::OOP::Select can be part of any SQL::OOP::Base sub classes
    my $select2 = SQL::OOP::Select->new();
    $select2->set(
        $select2->ARG_FIELDS => q("col1", "col2"),
        $select2->ARG_FROM   => $select,
    );
    
    my $where = SQL::OOP::Where->new();
    $where->cmp('=', q{some_field}, $select); # some_filed = (SELECT ..)
    
    my $sql  = $select->to_string;
    my @bind = $select->bind;

=head1 DESCRIPTION

SQL::OOP::Select class represents Select commands. 

=head2 SQL::OOP::Select->new(%clause)

Constructor. It takes arguments in hash. The Hash keys are provided by
following methods. They can be called as either class or instance method.
    
    ARG_FIELDS
    ARG_FROM
    ARG_WHERE
    ARG_GROUPBY
    ARG_ORDERBY
    ARG_LIMIT
    ARG_OFFSET

=head2 $instance->set(%clause)

This method resets the clause data. It takes same argument as
SQL::OOP::Select->new().

=head2 $instance->to_string

Get SQL snippet in string

=head2 $instance->bind

Get binded values in array

=head1 CONSTANTS

=head2 KEYS

=head2 PREFIXES

=head2 ARG_FIELDS

argument key for FIELDS(=1)

=head2 ARG_FROM

argument key for FROM clause(=2)

=head2 ARG_WHERE

argument key for WHERE clause(=3)

=head2 ARG_GROUPBY

argument key for GROUP BY clause(=4)

=head2 ARG_ORDERBY

argument key for ORDER BY clause(=5)

=head2 ARG_LIMIT

argument key for LIMIT clause(=6)

=head2 ARG_OFFSET

argument key for OFFSET clause(=7)

=head1 EXAMPLE

Here is a comprehensive example for SELECT. You also can find some examples in
test scripts.

    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => 'table',
        $select->ARG_WHERE  => sub {
            my $where = SQL::OOP::Where->new;
            return $where->and(
                $where->cmp('=', 'a', 1),
                $where->cmp('=', 'b', 1),
            )
        },
    );

=head1 SEE ALSO

=cut
