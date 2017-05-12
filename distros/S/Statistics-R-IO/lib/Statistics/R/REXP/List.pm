package Statistics::R::REXP::List;
# ABSTRACT: an R generic vector (list)
$Statistics::R::REXP::List::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed weaken);

use Class::Tiny::Antlers;
use namespace::clean;

extends 'Statistics::R::REXP::Vector';
use overload;


use constant sexptype => 'VECSXP';

sub _to_s {
    my $self = shift;
    
    my ($u, $unfold);
    $u = $unfold = sub {
        join(', ', map { ref $_ eq ref [] ?
                             '[' . &$unfold(@{$_}) . ']' :
                             (defined $_? $_ : 'undef') } @_);
    };
    weaken $unfold;
    $self->_type . '(' . &$unfold(@{$self->elements}) . ')';
}


sub to_pl {
    my $self = shift;
    [ map {
        if (blessed $_ && $_->can('to_pl')) {
            my $x = $_->to_pl;
            if (ref $x eq ref []) {
                unless (scalar @{$x} > 1 ||
                        $_->isa('Statistics::R::REXP::List')) {
                    @{$x}
                } else {
                    $x
                }
            } else {
                $x
            }
        } else {
            $_
        }
      } @{$self->elements} ]
}


sub _type { 'list'; }


1; # End of Statistics::R::REXP::List

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::List - an R generic vector (list)

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::List
    
    my $vec = Statistics::R::REXP::List->new([
        1, '', 'foo', ['x', 22]
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R list, also called a generic
vector (C<VECSXP>). List elements can themselves be lists, and so can
form a tree structure.

=head1 METHODS

C<Statistics::R::REXP:List> inherits from
L<Statistics::R::REXP::Vector>, with no added restrictions on the value
of its elements. Missing values (C<NA> in R) have value C<undef>.

=over

=item sexptype

SEXPTYPE of generic vectors is C<VECSXP>.

=item to_pl

Perl value of the list is an array reference to the Perl values of its
C<elements>, but using a scalar value to represent elements that are
atomic vectors of length 1, rather than a one-element array reference.

The idea is that in R, C<1:3>, and C<list(1, 2, 3)> can often be used
interchangeably, even though the list is really composed of three
integer vectors, each of length one. Now, both will have native Perl
representation of C<[1, 2, 3]>.

This only applies to elements that are atomic vectors. An element of
type list will always be represented as an array reference:

C<< list(list(1), list(2), list(3))->to_pl >> -> C<[ [ 1 ], [ 2 ], [ 3 ] ]>

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
