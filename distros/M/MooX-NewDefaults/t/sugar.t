use strict;
use warnings;

use Test::More tests => 6;

# define two classes, and make sure our sugar works

{

  package TestClassA;
  use Moo;

  has one => ( is => 'ro', lazy => 1, default => sub { 'original default' } );
}
{

  package TestClassB;
  use Moo;

  use MooX::NewDefaults;

  extends @{ ['TestClassA'] };

  default_for one => sub { 'new default!' };
}

can_ok( $_->new, 'one' ) for 'TestClassA', 'TestClassB';

# attribute defaults
is( TestClassA->new->one(), 'original default', 'A has correct default' );
is( TestClassB->new->one(), 'new default!',     'B has correct default' );

my $stash = do {
  no strict;
  \%{'TestClassB::'};
};

delete $stash->{one};

# attribute defaults
is( TestClassA->new->one, 'original default', 'A has correct default' );
is( TestClassB->new->one, 'original default', 'B has correct default' );
