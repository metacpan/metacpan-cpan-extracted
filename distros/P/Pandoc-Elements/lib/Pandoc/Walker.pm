package Pandoc::Walker;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.27';

use Scalar::Util qw(reftype blessed);
use Carp;

use parent 'Exporter';
our @EXPORT = qw(walk query transform);
our @EXPORT_OK = ( @EXPORT, 'action' );

sub _simple_action {
    my $action = shift // return sub { };

    if ( blessed $action and $action->isa('Pandoc::Filter') ) {
        $action = $action->action;
    }
    elsif ( !ref $action or ref $action ne 'CODE' ) {
        croak "expected code reference, got: " . ( $action // 'undef' );
    }

    if (@_) {
        my @args = @_;
        return sub { $_ = $_[0]; $action->( $_[0], @args ) };
    }
    else {
        return $action;
    }
}

sub action {
    my @actions;
    my @args;

    # $selector => $action [, @arguments ]
    if ( !ref $_[0] ) {
        @actions = ( shift, shift );
        @args = @_;
    }

    # { $selector => $code, ... } [, @arguments ]
    elsif ( ref $_[0] eq 'HASH' ) {
        @actions = %{ shift @_ };
        @args    = @_;

        # code [, @arguments ]
    }
    else {
        return _simple_action(@_);
    }

    my $n = ( scalar @actions ) / 2 - 1;

    # check action functions and add arguments
    $actions[ $_ * 2 + 1 ] = _simple_action( $actions[ $_ * 2 + 1 ], @args )
      for 0 .. $n;

    # TODO: compile selectors for performance

    sub {
        my $element = $_[0];

        # get all matching actions
        my @matching =
          map  { $actions[ $_ * 2 + 1 ] }
          grep { $element->match( $actions[ $_ * 2 ] ) } 0 .. $n;

        my @return = ();

        foreach my $action (@matching) {
            $_      = $_[0];    # FIXME: $doc->walk( Section => sub { $_->id } )
            @return = ( $action->(@_) );
        }

        wantarray ? @return : $return[0];
    }
}

sub transform {
    my $ast    = shift;
    my $action = action(@_);

    my $reftype = reftype($ast) || '';

    if ( $reftype eq 'ARRAY' ) {
        for ( my $i = 0 ; $i < @$ast ; ) {
            my $item = $ast->[$i];

            if ( ( reftype $item || '' ) eq 'HASH' and $item->{t} ) {
                my $res = $action->($item);

                if ( defined $res ) {
                    # stop traversal
                    if ( $res eq \undef ) {
                        $i++;
                    # replace current item with result element(s)
                    } else {
                        my @elements =    #map { transform($_, $action, @_) }
                          ( reftype $res || '' ) eq 'ARRAY' ? @$res : $res;
                        splice @$ast, $i, 1, @elements;
                        $i += scalar @elements;
                    }
                    next;
                }
            }
            transform( $item, $action );
            $i++;
        }
    }
    elsif ( $reftype eq 'HASH' ) {

        # TODO: directly transform an element.
        # if (blessed $ast and $ast->isa('Pandoc::Elements::Element')) {
        # } else {
        foreach ( keys %$ast ) {
            transform( $ast->{$_}, $action, @_ );
        }

        # }
    }

    $ast;
}

sub walk(@) {    ## no critic
    my $ast    = shift;
    my $action = action(@_);
    transform( $ast, sub {
        $_ = $_[0];
        my $q = $action->(@_);
        return (defined $q and $q eq \undef) ? \undef : undef
    } );
}

sub query(@) {    ## no critic
    my $ast    = shift;
    my $action = action(@_);

    my $list = [];
    transform( $ast, sub {
        $_ = $_[0];
        my $q = $action->(@_);
        return $q if !defined $q or $q eq \undef;
        push @$list, $q;
        return
    } );
    return $list;
}

1;
__END__

=encoding utf-8

=head1 NAME

Pandoc::Walker - utility functions to process Pandoc documents

=head1 SYNOPSIS

    use Pandoc::Walker;
    use Pandoc::Elements qw(pandoc_json);

    my $ast = pandoc_json(<>);

    # extract all links and image URLs
    my $links = query $ast, 'Link|Image' => sub { $_->url };

    # print all links and image URLs
    walk $ast, 'Link|Image' => sub { say $_->url };

    # remove all links
    transform $ast, sub {
        return ($_->name eq 'Link' ? [] : ());
    };

    # replace all links by their link text angle brackets
    use Pandoc::Elements 'Str';
    transform $ast, Link => sub {
        return (Str " < ", $_->content->[0], Str " > ");
    };

=head1 DESCRIPTION

This module provides utility functions to traverse the abstract syntax tree
(AST) of a pandoc document (see L<Pandoc::Elements> for documentation of AST
elements).

Document elements are passed to action functions by reference, so I<don't
shoot yourself in the foot> by trying to directly modify the element.
Traversing a single element is not reliable neither, so put the element in an
array reference if needed.  For instance to replace links in headers only by
their link text content:

    transform $ast, Header => sub {
        transform [ $_[0] ], Link => sub { # make an array
            return $_[0]->content;         # is an array
        };
    };

See also L<Pandoc::Filter> for an object oriented interface to transformations.

=head1 FUNCTIONS

=head2 action ( [ $selector => ] $code [, @arguments ] )

=head2 action ( { $selector => $code, ... } [, @arguments ] )

Return an an action function to process document elements.

=head2 walk( $ast, ... )

Walks an abstract syntax tree and calls an action on every element or every
element of given name(s). Additional arguments are also passed to the action.

If and only if the action function returns C<\undef> the current element is
not traversed further.

See also function C<pandoc_walk> exported by L<Pandoc::Filter>.

=head2 query( $ast, ... )

Walks an abstract syntax tree and applies one or multiple query functions to
extract results.  The query function is expected to return a list or C<\undef>.
The combined query result is returned as array reference. For instance the
C<string> method of L<Pandoc::Elements> is implemented as following:

    join '', @{
        query( $ast, {
            'Str|Code|Math'   => sub { $_->content },
            'LineBreak|Space' => sub { ' ' }
        } );

=head2 transform( $ast, ... )

Walks an abstract syntax tree and applies an action on every element, or every
element of given name(s), to either keep it (if the action returns C<undef> or
C<\undef>), remove it (if it returns an empty array reference), or replace it
with one or more elements (returned by array reference or as single value).

See also function C<pandoc_filter> exported by L<Pandoc::Filter>.

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

GNU General Public License, Version 2

This module is heavily based on Pandoc by John MacFarlane.

=head1 SEE ALSO

Haskell module L<Text.Pandoc.Walk|http://hackage.haskell.org/package/pandoc-types/docs/Text-Pandoc-Walk.html> for the original.

=cut
