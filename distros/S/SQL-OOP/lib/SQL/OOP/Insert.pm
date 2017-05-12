package SQL::OOP::Insert;
use strict;
use warnings;
use SQL::OOP::Dataset;
use base qw(SQL::OOP::Command);

sub ARG_TABLE()     {1} ## no critic
sub ARG_DATASET()   {2} ## no critic
sub ARG_SELECT()    {3} ## no critic

### ---
### Get Names of set arguments in array ref
### ---
sub KEYS {
    return [ARG_TABLE, ARG_DATASET, ARG_SELECT];
}

### ---
### Get prefixes for each clause in hash ref
### ---
sub PREFIXES {
    return {
        ARG_TABLE()     => 'INSERT INTO',
        ARG_DATASET()   => '',
        ARG_SELECT()    => '',
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
    if ($self->{array}->[1]) {
        $self->{array}->[1]->generate(SQL::OOP::Dataset->MODE_INSERT);
    }
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

SQL::OOP::Insert

=head1 SYNOPSIS

    my $insert = SQL::OOP::Insert->new();
    
    # set clause
    $insert->set(
        $insert->ARG_TABLE => SQL::OOP::ID->new('some_table'),
        $insert->ARG_DATASET => SQL::OOP::Dataset->new(@data),
    );
    
    # reset clause by plain text
    $insert->set(
        $insert->ARG_TABLE => 'some_table',
    );
    
    my $sql  = $delete->to_string;
    my @bind = $delete->bind;

=head1 DESCRIPTION

SQL::OOP::Insert class represents Insert commands.

=head1 SQL::OOP::Insert CLASS

=head2 SQL::OOP::Insert->new(%clause)

Constructor. It takes arguments in hash. The Hash keys are provided by
following methods. They can call either class method or instance method.
    
    ARG_TABLE
    ARG_DATASET
    ARG_SELECT

=head2 $instance->set(%clause)

=head2 $instance->bind

=head2 $instance->to_string

This method resets the clause data. It takes same argument as constructor.

=head1 CONSTANTS

=head2 KEYS

=head2 PREFIXES

=head2 ARG_TABLE

argument key for table name(=1)

=head2 ARG_DATASET

argument key for dataset(=2)

=head2 ARG_SELECT

argument key for select(=3)

=head1 SEE ALSO

=cut
