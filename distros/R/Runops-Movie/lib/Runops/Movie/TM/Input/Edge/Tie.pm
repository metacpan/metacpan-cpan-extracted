package Runops::Movie::TM::Input::Edge::Tie;
use strict;
use warnings;
use feature ':5.10';
use constant SIZE   => 0;
use constant EDGE   => 1;
use constant TYPE   => 2;
use constant NAMES  => 3;
use constant NAME   => 4;
use constant COLORS => {
    NULL => 'grey',
    PVGV => 'red',
    PVAV => 'green',
    PVFM => 'cyan',
    PVCV => 'cyan',
    PVMG => 'goldenrod1',
    PVIO => 'goldenrod1',
    ''   => 'black',
    PVBM => 'yellow',
    NV   => 'yellow',
    PVLV => 'yellow',
    PV   => 'blue',
    IV   => 'yellow',
    RV   => 'orange',
    PVIV => 'yellow',
    PVNV => 'yellow',
    PVHV => 'brown',
};
use Judy::1;
use Judy::L;

my %seen;
sub TIEHASH {
    my ( undef, @s ) = @_;
    bless \ @s, $_[0];
}
sub FETCH {
    my ( $self, $key ) = @_;

    given ( $key ) {
        when('colour') {
            my $name = $self->[NAME];
            my $type = $self->[TYPE]{ pack 'i', $name };
            if ( ! defined $type ) {
                say "Missing type $name";
                $type = '';
            }
            my $color;
            if ( ! exists COLORS->{$type} ) {
                say "Missing color [$type]";
                $color = COLORS->{''};
            }
            else {
                $color = COLORS->{$type};
            }
            return $color;
        }
        when ('children') {
            my $class    = ref $self;
            my ( $pyedge, $yedge ) = Judy::L::Get($self->[EDGE],$self->[NAME]);
            return if ! $pyedge;

            my @children;

            my $y = Judy::1::First($yedge,0);
            while ( defined $y ) {
                my %child;
                tie %child, $class,
                    $self->[SIZE],
                    $self->[EDGE],
                    $self->[TYPE],
                    $self->[NAMES],
                    $y;

                push @children, \ %child;

                $y = Judy::1::Next($yedge,$y);
            }

            return \ @children;
        }
        when ('name') {
            return $self->[NAMES]{ pack 'i', $self->[NAME] } // sprintf '%x', $self->[NAME];
            #return $self->[NAME];
        }
        when ('size') {
            if ( exists $self->[SIZE] ) {
                my ( undef, $size ) = Judy::L::Get($self->[SIZE],$self->[NAME]);
                return $size;
            }
            else {
                warn "Missing size $self->[NAME]";
                return 0;
            }
        }
        default {
            die "@_";
        }
    }
}

1;
