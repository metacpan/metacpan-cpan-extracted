package Test::CallFlow::ArgCheck::Regexp;
use strict;
use base 'Test::CallFlow::ArgCheck';

=head1 Test::CallFlow::ArgCheck::Regexp

  die "Unfit" unless defined
    my $fit =
      Test::CallFlow::ArgCheck::Regexp->new( qr/^..$/ )->check( 0, [ 'foo' ] );

Checks arguments against a regular expression. See base class C<Test::CallFlow::ArgCheck>.

=head1 FUNCTIONS

=head2 check

  $checker->check( 1, [ 'foo', 'bar' ] ) ? 'ok' : die;

Checks the argument at given position in referred array against a regular expression.

=cut

sub check {
    my ( $self, $at, $args ) = @_;
    defined $args->[$at]
        and $args->[$at] =~ $self->{test};
}

1;

