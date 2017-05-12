package Statistics::R::REXP::Expression;
# ABSTRACT: an R expression vector
$Statistics::R::REXP::Expression::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed);

use Class::Tiny::Antlers;
use namespace::clean;

extends 'Statistics::R::REXP::List';

use constant sexptype => 'EXPRSXP';

sub to_pl {
    Statistics::R::REXP::Vector::to_pl(@_)
}

sub _type { 'expression' };


1; # End of Statistics::R::REXP::Expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Expression - an R expression vector

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Expression
    
    # Representation of the R call C<expresson(1 + 2))>:
    my $vec = Statistics::R::REXP::Expression->new([
        Statistics::R::REXP::Language->new([
            Statistics::R::REXP::Symbol->new('+'),
            Statistics::R::REXP::Double->new([1]),
            Statistics::R::REXP::Double->new([2])
    ])]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R expression vectors
(C<EXPRSXP>). These objects represent a list of calls, symbols, etc.,
for example as returned by calling R function C<parse> or
C<expression>.

=head1 METHODS

C<Statistics::R::REXP:Expression> inherits from
L<Statistics::R::REXP::List>, with no added restrictions on the value
of its elements.

=over

=item sexptype

SEXPTYPE of expressions is C<EXPRSXP>.

=item to_pl

Perl value of the expression vector is an array reference to the Perl
values of its C<elements>. (That is, it's equivalent to C<map
{$_->to_pl}, $vec->elements>.) Unlike L<List>, elements that are
atomic vectors of length 1 are still represented as a one-element
array reference, rather than scalar values.

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
