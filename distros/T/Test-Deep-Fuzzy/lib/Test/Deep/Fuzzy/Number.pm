package Test::Deep::Fuzzy::Number;
use strict;
use warnings;

use Test::Deep::Cmp;

use B ();
use Scalar::Util qw/looks_like_number/;
use Math::Round qw/nearest/;

our $RANGE = 0.000001;

sub init {
    my ($self, $value, $range) = @_;
    $self->{value} = $value;
    $self->{range} = $range;
}

sub range { defined $_[0]->{range} ? $_[0]->{range} : $RANGE }

sub is_number {
    my $value = shift;
    return !!0 unless looks_like_number($value);

    $value += 0.0; # numify

    my $flags = B::svref_2object(\$value)->FLAGS;
    return !!($flags & B::SVp_NOK & ~B::SVp_POK);
}

sub descend {
    my ($self, $got) = @_;
    my $expected = $self->{value};
    $got      = nearest($self->range, $got)      if is_number($got);
    $expected = nearest($self->range, $expected) if is_number($expected);
    return $got == $expected;
}

sub diag_message {
    my ($self, $where) = @_;
    my $value = $self->{value};
    my $range = $self->{range} || $RANGE;
    return "Comparing $where equals $value (in range: $range)";
}

sub renderExp {
    my $self = shift;
    return $self->renderGot($self->{value});
}

sub renderGot {
    my ($self, $got) = @_;
    my $value = is_number($got) ? nearest($self->range, $got) : $got;
    return "$value (".Test::Deep::render_val($got).")";
}

1;
__END__
