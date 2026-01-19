# -*- indent-tabs-mode: nil -*-

=head1 SEE ALSO

L<Graphics::ColorObject>

L(<https://qiita.com/yoya/items/96c36b069e74398796f3>

=cut

package Term::ANSIColor::Concise::ColorObject;

our $VERSION = "3.02";

use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use parent 'Graphics::ColorObject';

{
    no strict 'refs';
    no warnings 'redefine';
    for my $sub (qw(namecolor)) {
        my $name = "Graphics::ColorObject::$sub";
        my $save = \&{$name};
        *{$name} = sub {
            $_[1] // return;
            goto $save;
        }
    }
}

# RGB
sub rgb {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        bless $self->SUPER::new_RGB255(\@_), $class;
    } else {
        map int, @{$self->as_RGB255};
    }
}

# HSL
sub hsl {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        my($h, $s, $l) = @_;
        bless $self->SUPER::new_HSL([ $h, $s/100, $l/100 ]), $class;
    } else {
        my($h, $s, $l) = @{$self->as_HSL};
        map int, ($h, $s * 100, $l * 100);
    }
}

# Lab
sub lab {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        bless Graphics::ColorObject->new_Lab(\@_), $class;
    } else {
        @{$self->as_Lab};
    }
}

# Luv
sub luv {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        my($L, $u, $v) = @_;
        bless Graphics::ColorObject->new_Luv([ $L, $u / 100, $v / 100 ]), $class;
    } else {
        my($L, $u, $v) = @{$self->as_Luv};
        map int, ($L, $u * 100, $v * 100);
    }
}

# LCHab
sub lch {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        bless Graphics::ColorObject->new_LCHab(\@_), $class;
    } else {
        @{$self->as_LCHab};
    }
}

# YIQ
sub yiq {
    my $self = shift;
    my $class = ref $self || $self;
    if (@_) {
        bless Graphics::ColorObject->new_YIQ(\@_), $class;
    } else {
        @{$self->as_YIQ};
    }
}

sub luminance {
    my $self = shift;
    if (@_) {
        $self->set_luminance(@_);
    } else {
        $self->get_luminance;
    }
}

use List::Util qw(pairs);

sub set {
    my $map = shift;
    $_[$_->[0]] = $_->[1] for pairs @$map;
    @_;
}

sub get_luminance {
    int $_[0] -> as_Lab -> [0];
}

sub in_rgb_gamut {
    my $self = shift;
    my @rgb = @{$self->as_RGB};
    !grep { $_ < 0 || $_ > 1 } @rgb;
}

sub set_luminance {
    my($self, $L) = @_;
    my @lab = $self->lab;
    my $new = __PACKAGE__->lab(set([ 0 => $L ], @lab));
    return $new if $new->in_rgb_gamut;

    # Reduce chroma to fit in RGB gamut using binary search
    my($a, $b) = @lab[1, 2];
    my($lo, $hi) = (0, 100);
    while ($hi - $lo > 1) {
        my $mid = ($lo + $hi) / 2;
        my $test = __PACKAGE__->lab($L, $a * $mid / 100, $b * $mid / 100);
        if ($test->in_rgb_gamut) {
            $lo = $mid;
        } else {
            $hi = $mid;
        }
    }
    __PACKAGE__->lab($L, $a * $lo / 100, $b * $lo / 100);
}

1;
