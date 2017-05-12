package Seis::Instant;
use strict;
use warnings;
use utf8;
use 5.010_001;

use overload (
    q{""} => sub {
        "Instant:" . $_[0]->x
    },
    q{eq} => sub {
        $_[0]->x eq $_[1]->x
    },
    q{>} => sub {
        $_[0]->x > $_[1]->x
    },
    q{<} => sub {
        $_[0]->x < $_[1]->x
    },
    q{-} => sub {
        my ($x,$y,$reversed) = @_;
        if ($reversed) {
            ...
        } else {
            if (UNIVERSAL::isa($_[1], __PACKAGE__)) {
                Seis::Duration->_new($_[0]->x - $_[1]->x)
            } else {
                Seis::Instant->_new($x->{x} - $y);
            }
        }
    },
    q{+} => sub {
        my ($x,$y,$reverse) = @_;
        if ($reverse) {
            Seis::Instant->_new($x->{x} + $y);
        } else {
            if (UNIVERSAL::isa($_[1], __PACKAGE__)) {
                Seis::Exception->throw("Instant + Instant is illegal");
            } elsif (UNIVERSAL::isa($_[1], 'Seis::Duration')) {
                Seis::Instant->_new($x->{x} + $$y);
            } else {
                Seis::Instant->_new($x->{x} + $y);
            }
        }
    },
);

sub _new {
    my ($class, $x) = @_;
    bless {x => $x}, $class;
}

sub x { shift->{x} }

sub fromーposix {
    my ($class, $x) = @_;
    $class->_new($x);
}

1;

