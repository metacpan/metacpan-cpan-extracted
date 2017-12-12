
package PPIx::Literal;
$PPIx::Literal::VERSION = '0.1.0';
# ABSTRACT: Convert PPI nodes into literal values

use 5.010;
use strict;
use warnings;
use Carp ();

sub convert {
    my $self = shift;
    my @nodes = _prune( map { $_->clone } @_ );
    return $self->_convert_nodes(@nodes);
}

sub _prune {
    my @nodes;
    for my $node (@_) {
        next if $node->isa('PPI::Token::Whitespace');
        $node->prune('PPI::Token::Whitespace') if $node->can('prune');
        push @nodes, $node;
    }
    return @nodes;
}

sub _convert {
    my ( $self, $node ) = ( shift, shift );

    if ( $node->isa('PPI::Token::Quote') && $node->can('literal') ) {
        return $node->literal;
    }
    if ( $node->isa('PPI::Token::Quote::Double') ) {
        $node->simplify;
        return $node->literal if $node->can('literal');
    }
    if ( $node->isa('PPI::Token::Number') ) {
        return $node->literal;
    }
    elsif ( $node->isa('PPI::Token::QuoteLike::Words') ) {
        return $node->literal;
    }
    elsif ( $node->isa('PPI::Token::Word') ) {
        return $node->literal;
    }
    elsif ( $node->isa('PPI::Structure::List') ) {
        return map { $self->_convert($_) } $node->children;
    }
    elsif ( $node->isa('PPI::Structure::Constructor') ) {
        my @v = map { $self->_convert($_) } $node->children;
        return _build_struct( $node->start->content, @v );
    }
    elsif ( $node->isa('PPI::Statement::Expression') ) {
        return $self->_convert_nodes( $node->children );
    }
    elsif ( $node->isa('PPI::Statement') ) {
        return _unknown($node) if $node->specialized;
        return $self->_convert_nodes( $node->children );
    }
    elsif ( $node->isa('PPI::Document') ) {
        return map { $self->_convert($_) } $node->children;
    }
    else {
        return _unknown($node);
    }
}

sub _convert_nodes {
    my ( $self, @nodes ) = @_;

    my @v;
    my $expect = 'value';
    while ( my $node = shift @nodes ) {
        if ( $expect eq 'value' ) {
            push @v, $self->_convert($node);
            $expect = 'comma';
        }
        elsif ( $expect eq 'comma' ) {
            if ( _is_comma($node) ) {
                $expect = 'value';
            }
            else {
                # This and the rest are considered unknowns
                push @v, _unknown( $node, @nodes );
                last;
            }
        }
    }
    return @v;
}

sub _build_struct {
    my ( $start, @values ) = @_;
    if ( $start eq '{' ) {
        return +{@values};
    }
    elsif ( $start eq '[' ) {
        return [@values];
    }
    Carp::croak(qq{Can't build structure with start "$start"});
}

sub _is_comma {
    my $node = shift;
    return $node->isa('PPI::Token::Operator')
      && ( $node->content eq ',' || $node->content eq '=>' );
}

sub _unknown {
    my $content = ( @_ == 1 ) ? { node => shift } : { nodes => [@_] };
    return bless $content, 'PPIx::Literal::Unknown';
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use PPI;
#pod     use PPIx::Literal;
#pod
#pod     my $doc    = PPI::Document->new( \q{(1, "one", 'two')} );
#pod     my @values = PPIx::Literal->convert($doc);
#pod     # (1, "one", "two")
#pod
#pod     my $doc    = PPI::Document->new( \q{ [ 3.14, 'exp', { one => 1 } ] } );
#pod     my @values = PPIx::Literal->convert($doc);
#pod     # [3.14, "exp", { one => 1 }]
#pod
#pod     my $doc    = PPI::Document->new( \q{use zim 'Carp' => qw(carp croak)} );
#pod     my ($use)  = $doc->children;
#pod     my @values = PPIx::Literal->convert( $use->arguments );
#pod     # ("Carp", "carp", "croak")
#pod
#pod =head1 DESCRIPTION
#pod
#pod    This code is alpha quality. It is an early release.
#pod    Interface may change. There may be serious bugs.
#pod
#pod This module implements the conversion of a small subset of Perl
#pod into their literal values. The perl code to be converted
#pod is represented as a list of PPI nodes.
#pod
#pod The conversion works for pieces which gets built from literal tokens
#pod and which don't require any kind of compilation.
#pod
#pod Some examples are:
#pod
#pod     42          # number
#pod     "a + b"     # plain strings
#pod     qw(a b c)   # quoted words
#pod
#pod     []                          # anon array refs
#pod     { -version => '0.3.2' },    # anon hash refs
#pod     (2, 3, 4)                   # literal lists
#pod
#pod The result of the conversion is a list of Perl data structures
#pod which contain plain scalars and "unknowns" as leafs.
#pod The "unknowns" are used to represent PPI nodes which
#pod can't be converted to literals.
#pod
#pod =head1 METHODS
#pod
#pod L<PPIx::Literal> implements the following methods.
#pod
#pod =head2 convert
#pod
#pod     @values = PPIx::Literal->convert(@nodes);
#pod
#pod Convert C<@nodes> into their literal values or into "unknowns".
#pod
#pod =head1 SEE ALSO
#pod
#pod L<PPI>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

PPIx::Literal - Convert PPI nodes into literal values

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use PPI;
    use PPIx::Literal;

    my $doc    = PPI::Document->new( \q{(1, "one", 'two')} );
    my @values = PPIx::Literal->convert($doc);
    # (1, "one", "two")

    my $doc    = PPI::Document->new( \q{ [ 3.14, 'exp', { one => 1 } ] } );
    my @values = PPIx::Literal->convert($doc);
    # [3.14, "exp", { one => 1 }]

    my $doc    = PPI::Document->new( \q{use zim 'Carp' => qw(carp croak)} );
    my ($use)  = $doc->children;
    my @values = PPIx::Literal->convert( $use->arguments );
    # ("Carp", "carp", "croak")

=head1 DESCRIPTION

   This code is alpha quality. It is an early release.
   Interface may change. There may be serious bugs.

This module implements the conversion of a small subset of Perl
into their literal values. The perl code to be converted
is represented as a list of PPI nodes.

The conversion works for pieces which gets built from literal tokens
and which don't require any kind of compilation.

Some examples are:

    42          # number
    "a + b"     # plain strings
    qw(a b c)   # quoted words

    []                          # anon array refs
    { -version => '0.3.2' },    # anon hash refs
    (2, 3, 4)                   # literal lists

The result of the conversion is a list of Perl data structures
which contain plain scalars and "unknowns" as leafs.
The "unknowns" are used to represent PPI nodes which
can't be converted to literals.

=head1 METHODS

L<PPIx::Literal> implements the following methods.

=head2 convert

    @values = PPIx::Literal->convert(@nodes);

Convert C<@nodes> into their literal values or into "unknowns".

=head1 SEE ALSO

L<PPI>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
