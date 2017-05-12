package TPath::Selector::Quantified;
$TPath::Selector::Quantified::VERSION = '1.007';
# ABSTRACT: handles expressions like C<a?> and C<//foo*>


use v5.10;
no if $] >= 5.018, warnings => "experimental";

use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;


with 'TPath::Selector';


has s => ( is => 'ro', isa => 'TPath::Selector', required => 1 );


has quantifier => ( is => 'ro', isa => 'Quantifier', required => 1 );


has top => ( is => 'ro', isa => 'Int', default => 0 );


has bottom => ( is => 'ro', isa => 'Int', default => 0 );

sub to_string {
    my ( $self, $first ) = @_;
    my $bracket = $self->s->isa('TPath::Selector::Expression');
    for ( $self->quantifier ) {
        when ('e') {
            my $q;
            if ( $self->top == $self->bottom ) {
                $q = '{' . $self->top . '}';
            }
            elsif ( $self->bottom == 0 ) {
                $q = '{,' . $self->top . '}';
            }
            elsif ( $self->top == 0 ) {
                $q = '{' . $self->bottom . ',}';
            }
            else {
                $q = '{' . $self->bottom . ',' . $self->top . '}';
            }
            return '(' . $self->s->to_string($first) . ")$q" if $bracket;
            return $self->s->to_string($first) . $q;
        }
        when ('?') {
            return '(' . $self->s->to_string($first) . ')?' if $bracket;
            return $self->s->to_string($first) . '?';
        }
        when ('+') {
            return '(' . $self->s->to_string($first) . ')+' if $bracket;
            return $self->s->to_string($first) . '+';
        }
        when ('*') {
            return '(' . $self->s->to_string($first) . ')*' if $bracket;
            return $self->s->to_string($first) . '*';
        }
    }
}

sub select {
    my ( $self, $ctx, $first ) = @_;
    my @c = $self->s->select( $ctx, $first );
    for ( $self->quantifier ) {
        when ('?') { return @c, $ctx }
        when ('*') { return @{ _iterate( $self->s, \@c ) }, $ctx }
        when ('+') { return @{ _iterate( $self->s, \@c ) } }
        when ('e') {
            my ( $s, $top, $bottom ) = ( $self->s, $self->top, $self->bottom );
            my $c = _enum_iterate( $s, \@c, $top, $bottom, 1 );
            return @$c, $self->bottom < 2 ? $ctx : ();
        }
    }
}

sub _enum_iterate {
    my ( $s, $c, $top, $bottom, $count ) = @_;
    my @next = map { $s->select($_) } @$c;
    my @return = $count++ >= $bottom ? @$c : ();
    unshift @return, @next
      if $count >= $bottom && ( !$top || $count <= $top );
    unshift @return, @{ _iterate( $s, \@next, $top, $bottom, $count ) }
      if !$top || $count < $top;
    return \@return;
}

sub _iterate {
    my ( $s, $c ) = @_;
    return [] unless @$c;
    my @next = map { $s->select($_) } @$c;
    return [ @{ _iterate( $s, \@next ) }, @$c ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Quantified - handles expressions like C<a?> and C<//foo*>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Selector that applies a quantifier to an ordinary selector.

=head1 ATTRIBUTES

=head2 s

The selector to which the quantifier is applied.

=head2 quantifier

The quantifier.

=head2 top

The largest number of iterations permitted. If 0, there is no limit. Used only by
the C<{x,y}> quantifier.

=head2 bottom

The smallest number of iterations permitted. Used only by the C<{x,y}> quantifier.

=head1 ROLES

L<TPath::Selector>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
