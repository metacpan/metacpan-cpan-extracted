package TPath::Selector::Test;
$TPath::Selector::Test::VERSION = '1.007';
# ABSTRACT: role of selectors that apply some test to a node to select it


use v5.10;
no if $] >= 5.018, warnings => "experimental";

use Moose::Role;
use TPath::TypeConstraints;
use TPath::Test::Node::Complement;


with 'TPath::Selector::Predicated';


has f => ( is => 'ro', does => 'TPath::Forester', required => 1 );


has axis =>
  ( is => 'ro', isa => 'Axis', writer => '_axis', default => 'child' );


has first_sensitive => ( is => 'ro', isa => 'Bool', default => 0 );

# axis translated into a forester method
has faxis => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        ( my $v = $self->axis ) =~ tr/-/_/;
        $self->f->can("axis_$v");
    },
);

# axis used in a first-sensitive context
has sensitive_axis => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        for ( $self->axis ) {
            when ('child') { return $self->f->can('axis_self') }
            when ('descendant') {
                return $self->f->can('axis_descendant_or_self')
            }
            default { return $self->faxis }
        }
    },
);


has is_inverted =>
  ( is => 'ro', isa => 'Bool', default => 0, writer => '_mark_inverted' );

sub _stringify_match {
    my ( $self, $re ) = @_;

    # chop off the "(?-xism:" prefix and ")" suffix
    if ( $re =~ /^\Q(?-xism:\E/ ) {
        $re = substr $re, 8, length($re) - 9;
    }
    elsif ( $re =~ /^\Q(?^:\E/ ) {
        $re = substr $re, 4, length($re) - 5;
    }
    $re =~ s/~/~~/g;
    return "~$re~";
}


has node_test =>
  ( is => 'ro', isa => 'TPath::Test::Node', writer => '_node_test' );

sub _invert {
    my $self = shift;
    $self->_node_test(
        TPath::Test::Node::Complement->new( nt => $self->node_test ) );
    $self->_mark_inverted(1);
}

has _cr1 => ( is => 'rw', isa => 'CodeRef' );
has _cr2 => ( is => 'rw', isa => 'CodeRef' );


sub candidates {
    return (
        $_[0]->_cr1 // do {
            my $axis;
            my $nt = $_[0]->node_test;
            my $f  = $_[0]->f;
            if ( $_[0]->first_sensitive ) {
                $axis = $_[0]->sensitive_axis;
            }
            else {
                $axis = $_[0]->faxis;
            }
            $_[0]->_cr1( sub { $axis->( $f, $_[0], $nt ) } );
          }
    )->( $_[1] ) if $_[2];
    return (
        $_[0]->_cr2 // do {
            my $axis = $_[0]->faxis;
            my $nt   = $_[0]->node_test;
            my $f    = $_[0]->f;
            $_[0]->_cr2( sub { $axis->( $f, $_[0], $nt ) } );
          }
    )->( $_[1] );

    # my ( $self, $ctx, $first ) = @_;
    # my $axis;
    # if ( $first && $self->first_sensitive ) {
    #     $axis = $self->sensitive_axis;
    # }
    # else {
    #    $axis = $self->faxis;
    # }
    # return $self->f->$axis( $ctx, $self->node_test );
}

# implements method required by TPath::Selector
sub select {
    my ( $self, $ctx, $first ) = @_;
    my @candidates = $self->candidates( $ctx, $first );
    return $self->apply_predicates(@candidates);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test - role of selectors that apply some test to a node to select it

=head1 VERSION

version 1.007

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=head1 ATTRIBUTES

=head2 f

Reference to the associated forester for this test. This is used in obtaining
the test axis.

=head2 axis

The axis on which nodes are sought; C<child> by default.

=head2 first_sensitive

Whether this this test may use a different axis depending on whether it is the first
step in a path.

=head2 is_inverted

Whether the test corresponds to a complement selector.

=head2 node_test

The test that is applied to select candidates on an axis.

=head1 METHODS

=head2 candidates

Expects an L<TPath::Context> and whether this is the first selector in its path
and returns nodes selected before filtering by predicates.

=head1 ROLES

L<TPath::Selector>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
