package Number::Object::Plugin::ArithmeticOperation;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub add :Method {
    my($self, $c, @values) = @_;
    my $value = $c->{value};
    $value += $_ for @values;
    $c->clone($value);
}

sub sub :Method {
    my($self, $c, @values) = @_;
    my $value = $c->{value};
    $value -= $_ for @values;
    $c->clone($value);
}

sub mul :Method {
    my($self, $c, @values) = @_;
    my $value = $c->{value};
    $value *= $_ for @values;
    $c->clone($value);
}

sub div :Method {
    my($self, $c, @values) = @_;
    my $value = $c->{value};
    $value /= $_ for @values;
    $c->clone($value);
}

1;
