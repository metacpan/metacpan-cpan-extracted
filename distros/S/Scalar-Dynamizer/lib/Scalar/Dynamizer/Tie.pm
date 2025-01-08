package Scalar::Dynamizer::Tie;

use strict;
use warnings;

sub TIESCALAR {
    my ( $class, $code ) = @_;
    return bless { code => $code }, $class;
}

sub FETCH {
    my ($self) = @_;
    return $self->{code}->();
}

sub STORE {
    croak('Cannot assign to a dynamic scalar');
}

=head1 NAME

Scalar::Dynamizer::Tie - Internal implementation for Scalar::Dynamizer

=head1 VERSION

Version 1.000

=cut

our $VERSION = 1.000;

=head1 SYNOPSIS

This module is not intended to be used directly. It is used internally by 
L<Scalar::Dynamizer> to implement the tied scalar behavior.

=head1 DESCRIPTION

C<Scalar::Dynamizer::Tie> is a tied scalar class that computes a dynamic value 
each time the scalar is accessed. The actual logic for computing the value is 
provided via a code reference when the scalar is tied.

=head1 METHODS

=head2 TIESCALAR

    my $object = Scalar::Dynamizer::Tie->TIESCALAR($code);

Constructor for the tied scalar. Takes a code reference as its argument, which 
will be executed each time the scalar's value is accessed.

=head3 Parameters

=over

=item * C<$code> (required)

A code reference that computes the scalar's value on access.

=back

=head3 Returns

A blessed object representing the tied scalar.

=head2 FETCH

    my $value = $object->FETCH();

This method is called whenever the tied scalar's value is accessed. It executes 
the code reference provided during C<TIESCALAR> to compute and return the current 
value of the scalar.

=head3 Returns

The value computed by the code reference.

=head2 STORE

    $object->STORE($value);

This method is called whenever an attempt is made to assign a value to the tied 
scalar. Since dynamic scalars are immutable, this method throws an exception.

=head3 Throws

    Cannot assign to a dynamic scalar

=head1 LIMITATIONS

This class is not intended for direct use. Use L<Scalar::Dynamizer> instead.

=head1 AUTHOR

Jeremi Gosney, C<< <epixoip at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scalar-dynamizer at rt.cpan.org>, 
or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-Dynamizer>.  
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Dynamizer::Tie

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Dynamizer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Scalar-Dynamizer>

=item * Search CPAN

L<https://metacpan.org/release/Scalar-Dynamizer>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Jeremi Gosney.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Scalar::Dynamizer::Tie
