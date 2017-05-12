package LenientSrcFile;
# ABSTRACT: 'srcfile' that is equal to another 'srcfile' if it only differs by 'wd' and 'timestamp'

use 5.010;

use Scalar::Util qw(looks_like_number);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP::Environment';

## Loosen the equality check to accept another srcfile environment if
## it only differs by the value of 'wd' and 'timestamp' elements

around _eq => sub {
    my $orig = shift;

    return unless Statistics::R::REXP::_eq @_;
    
    my ($self, $obj) = (shift, shift);

    # Duplicate from REXP::Environment, except for looser check on the
    # contents of 'wd' and 'timestamp'
    return unless _compare_deeply($self->enclosure, $obj->enclosure);

    my ($a, $b) = ($self->frame, $obj->frame);
    return unless scalar(keys %$a) == scalar(keys %$b);

    foreach my $name (keys %$a) {
        return undef unless exists $b->{$name};
        if ($name eq 'wd' || $name eq 'timestamp') {
            # don't check the exact directory and timestamp, just the
            # class and attributes
            return unless Statistics::R::REXP::_eq $a->{$name}, $b->{$name};
        }
        else {
            # other attributes have to match exactly
            return unless _compare_deeply($a->{$name}, $b->{$name});
        }
    }

    return 1
};


## we have to REXPs `_compare_deeply` this way because private methods
## aren't available in the subclass
sub _compare_deeply {
    Statistics::R::REXP::_compare_deeply(@_)
}

sub _type { 'lenient_srcfile'; }

1; # End of LenientSrcFile
