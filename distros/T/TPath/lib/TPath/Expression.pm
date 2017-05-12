package TPath::Expression;
$TPath::Expression::VERSION = '1.007';
# ABSTRACT: a compiled TPath expression


use TPath::TypeCheck;
use TPath::TypeConstraints;
use TPath::Context;
use Scalar::Util qw(refaddr);
use Moose;

use overload '""' => \&to_string;


with qw(TPath::Test TPath::Numifiable);


has f => ( is => 'ro', does => 'TPath::Forester', required => 1 );

has _selectors =>
  ( is => 'ro', isa => 'ArrayRef[ArrayRef[TPath::Selector]]', required => 1 );

has string =>
  ( is => 'ro', isa => 'Str', lazy => 1, builder => '_stringify_exp' );

has needs_uniq => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 1 if @{ $self->_selectors } > 1;
        return 1 if @{ $self->_selectors->[0] } > 1;
        return 0;
    },
);


has 'vars' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );


sub select {
    my ( $self, $n, $i, %opts ) = @_;
    confess 'select called on a null node' unless defined $n;
    $n = $self->f->wrap( $n, %opts );
    $self->f->_typecheck($n);
    $i //= $self->f->index($n);
    $i->index;
    my $ctx = TPath::Context->new( n => $n, i => $i );
    my $sel = $self->_select( $ctx, 1 );
    return wantarray ? map { $_->n } @$sel : @$sel ? $sel->[0]->n : undef;
}

# select minus the initialization steps
sub _select {
    my ( $self, $ctx, $first ) = @_;

    my @sel;
    for my $fork ( @{ $self->_selectors } ) {
        push @sel, @{ _sel( $ctx, $fork, 0, $first ) };
    }
    @sel = uniq(@sel) if $self->needs_uniq;

    return \@sel;
}


sub to_num {
    my ( $self, $ctx ) = @_;
    my $nodes = $self->_select( $ctx, 1 );
    return scalar @$nodes;
}

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    !!$self->select( $ctx->n, $ctx->i );
}

# goes down steps of path
sub _sel {
    my ( $ctx, $fork, $idx, $first ) = @_;
    my $selector = $fork->[ $idx++ ];
    my @c = uniq( $selector->select( $ctx, $first ) );
    return \@c if $idx == @$fork;

    my @sel;
    push @sel, @{ _sel( $_, $fork, $idx, 0 ) } for @c;
    return \@sel;
}

# a substitute for List::MoreUtils::uniq which uses reference address rather than stringification to establish identity
# the list filtered is assumed to be of TPath::Context objects
sub uniq {
    return @_ if @_ < 2;
    my %seen = ();
    grep { not $seen{ refaddr $_->n }++ } @_;
}

sub to_string { $_[0]->string }

sub _stringify_exp {
    my $self = shift;
    my $s    = '';
    for my $selectors ( @{ $self->_selectors } ) {
        $s .= '|' if $s;
        my $non_first = 0;
        for my $sel (@$selectors) {
            $s .= $sel->to_string( !$non_first++ );
        }
    }
    return $s;
}


sub case_insensitive { shift->f->case_insensitive }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Expression - a compiled TPath expression

=head1 VERSION

version 1.007

=head1 SYNOPSIS

  my $f     = MyForester->new;             # make a new forester for my sort of tree
  my $path  = $f->path('//foo[@bar][-1]'); # select the last foo with the bar property
  my $tree  = next_tree();                 # get the next tree (hypothetical function)
  my ($foo) = $path->select($tree);        # get the desired node
  $foo      = $path->first($tree);         # achieves the same result

=head1 DESCRIPTION

An object that will get us the nodes identified by our path expression.

=head1 ATTRIBUTES

=head2 f

The expression's L<TPath::Forester>.

=head2 vars

Variables available during the application of this expression.

=head2 to_num

Required by L<TPath::Numifiable>. Returns the number of nodes selected given the L<TPath::Context>.

=head1 METHODS

=head2 select( $n, [$i], [%opts] )

Takes a tree and, optionally, an index and options. Returns the nodes selected 
from this tree by the path if you want a list or the first node selected if you want a
scalar. 

The options, if any, will be passed through to the forester's C<wrap> method to
define any coercion necessary.

If you are doing many selections on a particular tree, you may save some work by 
using a common index for all selections.

=head2 case_insensitive

Returns whether this expression was created by a case insensitive forester.

=head1 ROLES

L<TPath::Test>, L<TPath::Stringifiable>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
