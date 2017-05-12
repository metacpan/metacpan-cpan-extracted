# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl port by Martin Busik <martin.busik@busik.de>
#

{

    package Test::C2FIT::eg::AllPairs::Var;

    sub new {
        my $pkg = shift;
        my ( $index, $files ) = @_;
        return bless {
            files => $files,
            index => $index,
            items => []
        }, $pkg;
    }
    sub size { scalar( @{ $_[0]->{items} } ) }

    sub get {
        my ( $self, $index ) = @_;
        return $self->{items}->[$index];
    }
    1;
};

{

    package Test::C2FIT::eg::AllPairs::Item;

    sub new {
        my $pkg = shift;
        my ( $var, $i, $n ) = @_;
        return bless {
            var   => $var,
            index => $i,
            rank  => $n
        }, $pkg;
    }

    sub file {
        my ($self) = shift;
        return $self->{var}->{files}->[ $self->{index} ];
    }

    sub toString {    # TBD: overload stringify operator?
        my $self = shift;
        $self->file;
    }

    sub isFit {
        my ( $self, $slug ) = @_;
        my $idx = $self->{var}->{index};
        return !defined( $slug->[$idx] ) || $slug->[$idx] == $self;
    }
    1;
}

{

    package Test::C2FIT::eg::AllPairs::Pair;

    sub new {
        my $pkg = shift;
        my ( $allPairsRank, $left, $right ) = @_;
        return bless {
            allPairsRank => $allPairsRank,
            left         => $left,
            right        => $right,
            used         => 0
        }, $pkg;
    }

    sub toString {    # TBD: overload stringify operator?
        my $self = shift;
        my $ls   =
          ( defined( $self->{left} ) ) ? $self->{left}->toString : "null";
        my $rs =
          ( defined( $self->{right} ) ) ? $self->{right}->toString : "null";
        return $ls . "-" . $rs . " (" . $self->{used} . ")";
    }

    sub isFit {
        my ( $self, $slug ) = @_;
        return $self->{left}->isFit($slug)
          && $self->{right}->isFit($slug);
    }

    sub rank {
        my $self    = shift;
        my $parRank = ${ $self->{allPairsRank} };
        return $parRank * ( $parRank * $self->{used} + $self->{left}->{rank} ) +
          $self->{right}->{rank};
    }

    sub compareTo {
        my ( $self, $other ) = @_;
        return $self->rank - $other->rank;
    }

    1;
};

package Test::C2FIT::eg::AllPairs;
use base 'Test::C2FIT::eg::AllCombinations';

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{rank}   = undef;
    $self->{steps}  = 0;
    $self->{toItem} = {};
    $self->{vars}   = [];
    $self->{pairs}  = [];
    return $self;
}

sub combinations2 {
    my $self = shift;
    $self->populate;
    $self->generate;
}

sub populate {
    my $self = shift;
    $self->doAllVars;
    $self->doAllVarPairs;
}

sub doAllVars {
    my $self = shift;
    $self->{rank} = 0;
    for ( my $i = 0 ; $i < @{ $self->{lists} } ; $i++ ) {
        my $files = $self->{lists}->[$i];
        my $var = new Test::C2FIT::eg::AllPairs::Var( $i, $files );
        push( @{ $self->{vars} }, $var );
        $self->doAllItems( $var, $files );
    }
}

sub doAllItems {
    my ( $self, $var, $files ) = @_;
    my $toItem = $self->{toItem};
    for ( my $i = 0 ; $i < @$files ; $i++ ) {
        my $item =
          new Test::C2FIT::eg::AllPairs::Item( $var, $i, $self->{rank}++ );
        $toItem->{ $files->[$i] } = $item;
        push( @{ $var->{items} }, $item );
    }
}

sub doAllVarPairs {
    my ($self) = shift;
    my $vars = $self->{vars};
    for ( my $i = 0 ; $i < @$vars ; $i++ ) {
        for ( my $j = $i + 1 ; $j < @$vars ; $j++ ) {
            $self->doAllItemPairs( $vars->[$i], $vars->[$j] );
        }
    }
}

sub doAllItemPairs {
    my ( $self, $vl, $vr ) = @_;
    for ( my $l = 0 ; $l < $vl->size ; $l++ ) {
        for ( my $r = 0 ; $r < $vr->size ; $r++ ) {
            push(
                @{ $self->{pairs} },
                new Test::C2FIT::eg::AllPairs::Pair(
                    \$self->{rank}, $vl->get($l), $vr->get($r)
                )
            );
        }
    }
}

sub generate {
    my $self = shift;
    while ( $self->getFirstPair()->{used} == 0 ) {
        $self->emit( $self->nextCase );
    }
}

sub nextCase {
    my $self     = shift;
    my $slug     = [];
    my $slugSize = @{ $self->{vars} };
    while ( !$self->isFull( $slug, $slugSize ) ) {
        my $p = $self->nextFit($slug);
        $self->fill( $slug, $p );
    }
    return $slug;
}

sub fill {
    my ( $self, $slug, $pair ) = @_;
    $slug->[ $pair->{left}->{var}->{index} ]  = $pair->{left};
    $slug->[ $pair->{right}->{var}->{index} ] = $pair->{right};
    $pair->{used}++;
    push( @{ $self->{pairs} }, $pair );
}

sub isFull {
    my ( $self, $slug, $targetSize ) = @_;
    return 0 if @$slug != $targetSize;
    foreach (@$slug) {
        return 0 unless defined($_);
    }
    return 1;
}

sub nextFit {
    my ( $self, $slug ) = @_;
    my $hold = [];
    my $pair;
    while ( !( $pair = $self->nextPair )->isFit($slug) ) {
        push( @$hold, $pair );
    }
    push( @{ $self->{pairs} }, @$hold );
    return $pair;
}

sub nextPair {
    my $self  = shift;
    my $first = $self->removeFirstPair;
    $self->{steps}++;
    return $first;
}

sub emit {
    my ( $self, $slug ) = @_;
    my $combination = [];
    for ( my $i = 0 ; $i < @$slug ; $i++ ) {
        push( @$combination, $slug->[$i]->file() );
    }
    $self->doCase($combination);
}

sub getFirstPair
{   # java uses a sorted collection, in the perl port pairs are sorted on demand
    my $self   = shift;
    my $pairs  = $self->{pairs};
    my @sorted = sort { $a->compareTo($b) } @$pairs;
    $self->{pairs} = \@sorted;
    return $self->{pairs}->[0];
}

sub removeFirstPair {
    my $self = shift;
    $self->getFirstPair;
    my $r = shift( @{ $self->{pairs} } );
    return $r;
}

1;
