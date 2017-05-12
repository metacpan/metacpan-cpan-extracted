package Test::CallFlow::ArgCheck::Any;
use strict;
use base 'Test::CallFlow::ArgCheck';

=head1 Test::CallFlow::ArgCheck::Any

=head1 SYNOPSIS

  die "Impossible" unless defined
    my $equality =
      Test::CallFlow::ArgCheck::Any
        ->new( test => 'man' )
          ->check( 1, [ 'child', 'woman' ] );

Use objects of this class to pass one or more arguments without checking
in a call to a mocked function.

=head1 FUNCTIONS

=head2 check

Always returns 1.

=cut

sub check { 1 }

1;
