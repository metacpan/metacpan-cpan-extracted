package Test::CallFlow::ArgCheck::Equals;
use strict;
use base 'Test::CallFlow::ArgCheck';

=head1 Test::CallFlow::ArgCheck::Equals

=head1 SYNOPSIS

Checks for argument equality.

If test is undefined, arguments must be as well.

=head1 FUNCTIONS

=head2 check

  die "Inequal" unless defined
    my $equality =
      Test::CallFlow::ArgCheck::Equals
        ->new( test => 'man' )
          ->check( 1, [ 'child', 'woman' ] );

=cut

sub check {
    my ( $self, $at, $args ) = @_;
    defined $args->[$at]
        ? $self->{test} eq $args->[$at]
        : !defined $self->{test};
}

1;

