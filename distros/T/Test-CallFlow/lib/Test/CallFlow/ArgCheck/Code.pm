package Test::CallFlow::ArgCheck::Code;
use strict;
use base 'Test::CallFlow::ArgCheck';

=head1 Test::CallFlow::ArgCheck::Code

  my $truth = 
    Test::CallFlow::ArgCheck::Code
      ->new( 
        test => sub { 
          my ($self, $at, $args) = @_; 
          ref $args->[$at] =~ $self->{re} 
        }, 
        re => qr/Good/
      )
      ->check( bless {}, 'My::Godness' );

Delegates decision about validity of arguments to associated code reference (sub).

See base class C<Test::CallFlow::ArgCheck>.

=head1 FUNCTIONS

=head2 check

  $checker->check( 1, [ 'foo', 'bar' ] ) ? 'ok' : die;

Checks given argument by calling associated code reference with it.

Arguments passed to called sub are

  0. this ArgChecker object
  1. position of argument to test
  2. reference to array of arguments.

This way the associated sub can be written like a member of this class, using its properties.

=cut

sub check {
    $_[0]->{test}->(@_);
}

1;

