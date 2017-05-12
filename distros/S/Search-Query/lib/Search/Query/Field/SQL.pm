package Search::Query::Field::SQL;
use Moo;
extends 'Search::Query::Field';

use namespace::autoclean;

has 'type'         => ( is => 'rw' );
has 'fuzzy_op'     => ( is => 'rw' );
has 'fuzzy_not_op' => ( is => 'rw' );
has 'is_int'       => ( is => 'rw' );

our $VERSION = '0.307';

=head1 NAME

Search::Query::Field::SQL - query field representing a database column

=head1 SYNOPSIS

 my $field = Search::Query::Field::SQL->new( 
    name        => 'foo',
    alias_for   => [qw( bar bing )], 
 );

=head1 DESCRIPTION

Search::Query::Field::SQL implements field
validation and aliasing in SQL search queries.

=head1 METHODS

This class is a subclass of Search::Query::Field. Only new or overridden
methods are documented here.

=head2 BUILD

Available params are also standard attribute accessor methods.

=over

=item type

The column type.

=item fuzzy_op

=item fuzzy_not_op

=item is_int

Set if C<type> matches m/int|float|bool|time|date/.

=back

=cut

sub BUILD {
    my $self = shift;

    $self->{type} ||= 'char';

    # numeric types
    if ( $self->{type} =~ m/int|float|bool|time|date/ ) {
        $self->{fuzzy_op}     ||= '>=';
        $self->{fuzzy_not_op} ||= '! >=';
        $self->{is_int} = 1;
    }

    # text types
    else {
        $self->{fuzzy_op}     ||= 'ILIKE';
        $self->{fuzzy_not_op} ||= 'NOT ILIKE';
        $self->{is_int} = 0;
    }

}

1;
