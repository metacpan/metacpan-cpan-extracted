package SQL::OOP::Delete;
use strict;
use warnings;
use SQL::OOP::Base;
use SQL::OOP::Where;
use base qw(SQL::OOP::Command);

sub ARG_TABLE() {1} ## no critic
sub ARG_WHERE() {2} ## no critic

### ---
### Get Names of set arguments in array ref
### ---
sub KEYS {
    return [ARG_TABLE, ARG_WHERE];
}

### ---
### Get prefixes for each clause in hash ref
### ---
sub PREFIXES {
    return {
        ARG_TABLE() => 'DELETE FROM',
        ARG_WHERE() => 'WHERE',
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

SQL::OOP::Delete

=head1 SYNOPSIS
    
    use SQL::OOP::Delete;
    
    my $delete= SQL::OOP::Delete->new();
    
    # set clause
    $delete->set(
        $delete->ARG_TABLE => 'some_table',
        $delete->ARG_WHERE => SQL::OOP::Where->cmp('=', 'a', 'b'),
    );
    
    # reset clause by plain text
    $delete->set(
        $delete->ARG_WHERE => 'a = b'
    );
    
    my $sql  = $delete->to_string;
    my @bind = $sth->execute($delete->bind);

=head1 DESCRIPTION

SQL::OOP::Delete class represents Delete commands.

=head1 SQL::OOP::Delete CLASS

=head2 SQL::OOP::Delete->new(%clause)

Constructor. It takes arguments in hash. The Hash keys are provided by
following methods. They can call either class method or instance method.
    
    ARG_TABLE
    ARG_WHERE

=head2 $instance->set(%clause)

This method resets the clause data. It takes same argument as constructor.

=head2 $instance->to_string

=head2 $instance->bind

=head1 CONSTANTS

=head2 KEYS

=head2 PREFIXES

=head2 ARG_TABLE

argument key for table name(=1)

=head2 ARG_WHERE

argument key for where clause(=2)

=head1 SEE ALSO

=cut
