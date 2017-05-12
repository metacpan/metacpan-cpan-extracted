package Statistics::R::REXP::Language;
# ABSTRACT: an R language vector
$Statistics::R::REXP::Language::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed);

use Class::Tiny::Antlers;
use namespace::clean;

extends 'Statistics::R::REXP::List';

use constant sexptype => 'LANGSXP';


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute type
    die 'The first element must be a Symbol or Language' if defined $self->elements &&
        !(blessed $self->elements->[0] &&
              ($self->elements->[0]->isa('Statistics::R::REXP::Language') ||
               $self->elements->[0]->isa('Statistics::R::REXP::Symbol')))
}

sub to_pl {
    Statistics::R::REXP::Vector::to_pl(@_)
}

sub _type { 'language' };


1; # End of Statistics::R::REXP::Language

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Language - an R language vector

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Language
    
    # Representation of the R call C<mean(c(1, 2, 3))>:
    my $vec = Statistics::R::REXP::Language->new([
        Statistics::R::REXP::Symbol->new('mean'),
        Statistics::R::REXP::Double->new([1, 2, 3])
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R language vector (C<LANGSXP>).
These objects represent calls (such as model formulae), with first
element a reference to the function being called, and the remainder
the actual arguments of the call. Names of arguments, if given, are
recorded in the 'names' attribute (itself as
L<Statistics::R::REXP::Character> vector), with unnamed arguments
having name C<''>. If no arguments were named, the language objects
will not have a defined 'names' attribute.

=head1 METHODS

C<Statistics::R::REXP:Language> inherits from
L<Statistics::R::REXP::Vector>, with the added restriction that its
first element has to be a L<Statistics::R::REXP::Symbol> or another
C<Language> instance. Trying to create a Language instance that
doesn't follow this restriction will raise an exception.

=over

=item sexptype

SEXPTYPE of language vectors is C<LANGSXP>.

=item to_pl

Perl value of the language vector is an array reference to the Perl
values of its C<elements>. (That is, it's equivalent to C<map
{$_->to_pl}, $vec->elements>.

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
