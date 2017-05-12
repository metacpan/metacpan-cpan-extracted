package Statistics::R::REXP::Complex;
# ABSTRACT: an R numeric vector
$Statistics::R::REXP::Complex::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed looks_like_number);
use Math::Complex qw();

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP::Vector';
use overload;


use constant sexptype => 'CPLXSXP';


sub BUILDARGS {
    my $class = shift;
    my $attributes = $class->SUPER::BUILDARGS(@_);

    if (ref($attributes->{elements}) eq 'ARRAY') {
        $attributes->{elements} = [
            map { (blessed($_) && $_->isa('Math::Complex')) ? $_ :
                      looks_like_number $_ ? Math::Complex::cplx($_) :
                          undef }
                Statistics::R::REXP::Vector::_flatten(@{$attributes->{elements}})
        ]
    }
    $attributes
}


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute type
    die "Elements of the 'elements' attribute must be scalar numbers or instances of Math::Complex" if 
        defined $self->elements &&
        grep { defined($_) && !(blessed($_) && $_->isa('Math::Complex') ||
                   Scalar::Util::looks_like_number($_)) }
             @{$self->elements}
}


around _eq => sub {
    my $orig = shift;

    return unless Statistics::R::REXP::_eq(@_);
    
    my ($self, $obj) = (shift, shift);

    my $a = $self->elements;
    my $b = $obj->elements;
    return undef unless scalar(@$a) == scalar(@$b);
    for (my $i = 0; $i < scalar(@{$a}); $i++) {
        my $x = $a->[$i];
        my $y = $b->[$i];
        if (defined($x) && defined($y)) {
            return undef unless
                $x == $y;
        } else {
            return undef if defined($x) or defined($y);
        }
    }
    
    1
};


sub _type { 'complex'; }


1; # End of Statistics::R::REXP::Complex

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Complex - an R numeric vector

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Complex;
    use Math::Complex ();
    
    my $vec = Statistics::R::REXP::Complex->new([
        1, cplx(4, 2), 'foo', 42
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R complex vector
(C<CPLXSXP>).

=head1 METHODS

C<Statistics::R::REXP:Complex> inherits from
L<Statistics::R::REXP::Vector>, with the added restriction that its
elements are complex numbers. Elements that are not numbers have value
C<undef>, as do elements with R value C<NA>.

=over

=item sexptype

SEXPTYPE of complex vectors is C<CPLXSXP>.

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILDARGS BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
