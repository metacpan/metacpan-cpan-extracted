package Statistics::R::REXP::Character;
# ABSTRACT: an R character vector
$Statistics::R::REXP::Character::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;
use namespace::clean;

extends 'Statistics::R::REXP::Vector';
use overload;


use constant sexptype => 'STRSXP';

sub _type { 'character'; }


sub BUILDARGS {
    my $class = shift;
    my $attributes = $class->SUPER::BUILDARGS(@_);

    if (ref($attributes->{elements}) eq 'ARRAY') {
        $attributes->{elements} = [
            Statistics::R::REXP::Vector::_flatten(@{$attributes->{elements}})
        ]
    }
    $attributes
}


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute type
    die "Elements of the 'elements' attribute must be scalar values" if defined($self->elements) &&
        grep { ref($_) } @{$self->elements}
}


1; # End of Statistics::R::REXP::Character

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Character - an R character vector

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Character
    
    my $vec = Statistics::R::REXP::Character->new([
        1, '', 'foo', []
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R character vector
(C<STRSXP>).

=head1 METHODS

C<Statistics::R::REXP:Character> inherits from
L<Statistics::R::REXP::Vector>, with the added restriction that its
elements are scalar values. Elements that are not scalars (i.e.,
numbers or strings) have value C<undef>, as do elements with R value
C<NA>.

=over

=item sexptype

SEXPTYPE of character vectors is C<STRSXP>.

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILDARGS BUILD is_vector

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
