package Search::QueryParser::SQL::Column;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Carp;

__PACKAGE__->mk_accessors(
    qw( type name alias fuzzy_op fuzzy_not_op callback orm_callback is_int ));

use overload '""' => 'stringify', 'fallback' => 1;

our $VERSION = '0.010';

my $debug = $ENV{PERL_DEBUG} || 0;

=head1 NAME

Search::QueryParser::SQL::Column - SQL column object

=head1 SYNOPSIS

 my $column = Search::QueryParser::SQL::Column->new(
    name        => 'foo',
    type        => 'char',
    alias       => 'bar',
    fuzzy_op    => 'ILIKE',
    fuzzy_not_op => 'NOT ILIKE',
    callback    => sub {
        my ($col, $op, $val) = @_;
        return "$col $op $val";
    },
    orm_callback => sub {
        my ($col, $op, $val) = @_;
        return( $col => { $op => $val } );
    },
 );

=head1 DESCRIPTION

This class represents a column in a database table,
and is used for rendering SQL correctly.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new( I<args> )

Instantiate a new Column object. I<args> may be a hash or hashref.

I<args> keys are also accessor methods:

=over

=item name

The column name. Stringifies to this value.

=item type

SQL column type: char, varchar, integer, datetime, timestamp, etc.

=item alias

Alternate names for the column. May be a scalar string or array ref.

=item fuzzy_op

The operator to use when a column value has a wildcard attached.
For text columns this defaults to C<ILIKE>. For numeric columns
this defaults to ">=".

=item fuzzy_not_op

The operator to use when a column value has a wildcard attached
and is negated. For text columns this defaults to C<NOT ILIKE>.
For numeric columns this defaults to "! >=".

=item callback

Should be a CODE reference expecting three arguments: the Column object,
the operator in play, and the value. Should return a string to be
pushed onto the Query buffer.

=item orm_callback

Like callback but should return a pair of values: the column name
and either a value or a hashref with the operator as the key.

=back

=cut

sub new {
    my $class = shift;
    my $args  = ref( $_[0] ) ? $_[0] : {@_};
    my $self  = $class->SUPER::new($args);
    $self->__setup;
    return $self;
}

sub __setup {
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

=head2 stringify

Returns Column name. Column objects overload to this method.

=cut

sub stringify {
    return shift->name;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-search-queryparser-sql@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


