package ShortDoubleVector;
# ABSTRACT: numeric vector that compares elements using 

use 5.010;

use Scalar::Util qw(looks_like_number);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP::Double';
use Statistics::R::REXP;

around _eq => sub {
    my $orig = shift;

    return unless Statistics::R::REXP::_eq @_;
    
    my ($self, $obj) = (shift, shift);

    my $a = $self->elements;
    my $b = $obj->elements;
    return undef unless scalar(@$a) == scalar(@$b);
    for (my $i = 0; $i < scalar(@{$a}); $i++) {
        my $x = $a->[$i];
        my $y = $b->[$i];
        if (defined($x) && defined($y)) {
            return undef unless
                $x eq $y ||
                (abs($x - $y) < 1e-13);
        } else {
            return undef if defined($x) or defined($y);
        }
    }
    
    1
};


## we have to REXPs `_compare_deeply` this way because private methods
## aren't available in the subclass
sub _compare_deeply {
    Statistics::R::REXP::Double::_compare_deeply(@_)
}

sub _type { 'shortdouble'; }

1;
