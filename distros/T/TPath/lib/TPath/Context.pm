package TPath::Context;
$TPath::Context::VERSION = '1.007';
# ABSTRACT: the context in which a node is evaluated during a search


use strict;
use warnings;

use Scalar::Util qw(refaddr);

use overload '""' => \&to_string;

# To be regarded as private. Let TPath code create contexts.
sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = [ $params{n}, $params{i}, [], undef ];
    bless $self, $class;
}

# A constructor that constructs a new context by augmenting an existing context.
# Expects a new node and the collection from which it was chosen. To be regarded
# as private.
sub bud {

    # my ( $self, $n ) = @_;
    return bless [ $_[1], $_[0][1], [ $_[0][0], @{ $_[0][2] } ], undef ];
}

#Makes a context that doesn't preserve the path.
sub wrap {

    # my ( $self, $n ) = @_;
    return bless [ $_[1], $_[0][1], [], undef ];
}


sub previous {
    my $self     = shift;
    my @previous = @{ $self->[2] };
    my $n        = shift @previous;
    return () unless $n;
    return bless [ $n, $self->[1], \@previous, undef ];
}


sub first {
    my $self = shift;
    return $self unless @{ $self->[2] };
    $self->wrap( $self->[2][-1] );
}


sub n { $_[0][0] }


sub i { $_[0][1] }


sub path { $_[0][2] }


sub expression {
    return $_[0][3] if @_ < 2;
    return $_[0][3] = $_[1];
}


sub to_string {
    my $s;
    eval { $s = "$_[0][0]" };
    if ($@) {                  # workaround for odd overload bug
        $s = 'memaddr' . refaddr $_[0][0];
    }
    return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Context - the context in which a node is evaluated during a search

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Basically a data structure holding all the different bits of information that may be useful
to selectors, predicates, or attributes during the evaluation of a node. This class simplifies
method signatures -- instead of passing a list of parameters one passes a single context.

A C<TPath::Context> is a blessed array rather than a hash, and it is a non-Moose class, for a 
little added efficiency. Note, that for still greater efficiency it is sometimes treated as an
array rather than an object, so it must be regarded as a final class not to be tampered with
or extended.

=head1 METHODS

=head2 previous

Returns the context of the node selected immediately before the context node.

=head2 first

Returns the first context in the selection history represented by this context.

=head2 n

The context node.

=head2 i

The L<TPath::Index>.

=head2 path

The previous nodes selected in the course of selecting the context node. These ancestor
nodes are in reverse order, so the node's immediate predecessor is at index 0.

=head2 expression

The expression the context is being used by. This attribute is not guaranteed to be set and
the method, unlike the other accessors, is a setter as well as a getter.

The contextual attribute is available for use by L<TPath::Attributes>, which set the attribute
when they are applied to a context.

=head2 to_string

The stringification of a context is the stringification of its node.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
