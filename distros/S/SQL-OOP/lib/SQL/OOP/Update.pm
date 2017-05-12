package SQL::OOP::Update;
use strict;
use warnings;
use SQL::OOP::Base;
use SQL::OOP::Where;
use SQL::OOP::Dataset;
use base qw(SQL::OOP::Command);

sub ARG_TABLE()     {1} ## no critic
sub ARG_DATASET()   {2} ## no critic
sub ARG_FROM()      {3} ## no critic
sub ARG_WHERE()     {4} ## no critic

### ---
### Get Names of set arguments in array ref
### ---
sub KEYS {
    return [ARG_TABLE, ARG_DATASET, ARG_FROM, ARG_WHERE];
}

### ---
### Get prefixes for each clause in hash ref
### ---
sub PREFIXES {
    return {
        ARG_TABLE()     => 'UPDATE',
        ARG_DATASET()   => 'SET',
        ARG_FROM()      => 'FROM',
        ARG_WHERE()     => 'WHERE',
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
    my ($self) = @_;
    local $SQL::OOP::Base::quote_char = $self->quote_char;
    $self->{array}->[1]->generate(SQL::OOP::Dataset->MODE_UPDATE);
    return shift->SUPER::to_string(@_);
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

SQL::OOP::Update

=head1 SYNOPSIS

    my $update = SQL::OOP::Update->new;

    # set clause by plain text
    $update->set(
        $update->ARG_TABLE      => 'some_table',
        $update->ARG_DATASET    => 'a = b, c = d',
        $update->ARG_WHERE      => 'a = c',
    );
    
    # reset clauses using objects
    $update->set(
        $select->ARG_TABLE      => SQL::OOP::ID->new('some_table'),
        $update->ARG_DATASET    => SQL::OOP::Dataset->new(@data),
        $select->ARG_WHERE      => $where->cmp('=', "some_fileld", 'value')
    );
    my $sql  = $update->to_string;
    my @bind = $update->bind;

=head1 DESCRIPTION

SQL::OOP::Select class represents Select commands.

=head1 SQL::OOP::Update CLASS

=head2 SQL::OOP::Update->new(%clause)

Constructor. It takes arguments in hash. The Hash keys are provided by
following methods. They can call either class method or instance method.
    
    ARG_TABLE
    ARG_DATASET
    ARG_FROM
    ARG_WHERE

=head2 $instance->set(%clause)

This method resets the clause data. It takes same argument as constructor.

=head2 $instance->to_string

=head2 $instance->bind

=head1 CONSTANTS

=head2 KEYS

=head2 PREFIXES

=head2 ARG_TABLE

argument key for TABLE(=1)

=head2 ARG_DATASET

argument key for DATASET(=2)

=head2 ARG_FROM

argument key for FROM clause(=3)

=head2 ARG_WHERE

argument key for WHERE clause(=4)

=head1 SEE ALSO

=cut
