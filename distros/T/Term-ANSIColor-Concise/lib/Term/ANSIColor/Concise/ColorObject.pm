# -*- indent-tabs-mode: nil -*-

=head1 SEE ALSO

L<Graphics::ColorObject>

L(<https://qiita.com/yoya/items/96c36b069e74398796f3>

=cut

package Term::ANSIColor::Concise::ColorObject;

our $VERSION = "3.01";

use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use parent 'Graphics::ColorObject';

package Graphics::ColorObject {
    no strict 'refs';
    no warnings 'redefine';
    for my $name (qw(namecolor)) {
        my $sub = \&{__PACKAGE__."::$name"};
        *{$name} = sub {
            $_[1] // return;
            goto $sub;
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
        my($L, $u, $v) = @{$self->as_Lab};
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

sub set_luminance {
    my($self, $L) = @_;
    __PACKAGE__->lab(set([ 0 => $L ], $self->lab));
}

1;
