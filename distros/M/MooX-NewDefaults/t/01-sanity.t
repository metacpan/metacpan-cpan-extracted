use strict;
use warnings;

use Test::More tests => 6;

# a set of tests to ensure that my understanding of this part of the MOP is
# correct, and that it stays correct :)

{

  package TestClassA;
  use Moo;

  has one => ( is => 'ro', lazy => 1, default => sub { 'original default' } );
}
{

  package TestClassB;
  use Moo;

  extends @{ ['TestClassA'] };

  sub one { 'new default!' }
}

my $A = TestClassA->new();
my $B = TestClassB->new();

# attribute, locally defined method
is $A->one, 'original default';
is $B->one, 'new default!';

can_ok( $_, 'one' ) for 'TestClassA', 'TestClassB';

my $stash = do {
  no strict;
  \%{'TestClassB::'};
};

delete $stash->{one};

# attribute, ancestor attribute
is $A->one, 'original default';
is $B->one, 'original default';
