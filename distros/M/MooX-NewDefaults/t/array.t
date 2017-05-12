use strict;
use warnings;

use Test::More tests => 16;

# define two classes, and make sure our sugar works with arrays.

{

  package TestClassA;
  use Moo;

  has one => ( is => 'ro', lazy => 1, default => sub { 'original default' } );
  has two => ( is => 'ro', lazy => 1, default => sub { 'original default(two)' } );
}
{

  package TestClassB;
  use Moo;

  use MooX::NewDefaults;

  extends @{ ['TestClassA'] };

  default_for [ 'one', 'two' ] => sub { 'new default!' };
}

our $ctx    = "";
our $nfails = 0;
our $left   = '';

sub my_subtest {
  my ( $reason, $code ) = @_;
  local $nfails = 0;
  my $pctx = ( length $ctx ? " (in $ctx)" : "" );
  local $ctx = "$reason" . $pctx;
  note "$left subtest: $reason$pctx {";
  {
    local $left = "$left   ";
    $code->();
  }
  note "$left }";
  return $nfails == 0;
}

# attribute defaults
my_subtest 'attr one' => sub {
  can_ok( $_->new, 'one' ) for 'TestClassA', 'TestClassB';

  is( TestClassA->new->one(), 'original default', 'A has correct default ' . $ctx );
  is( TestClassB->new->one(), 'new default!',     'B has correct default ' . $ctx );
};
my_subtest 'attr two' => sub {

  can_ok( $_->new, 'two' ) for 'TestClassA', 'TestClassB';

  is( TestClassA->new->two(), 'original default(two)', 'A has correct default ' . $ctx );
  is( TestClassB->new->two(), 'new default!',          'B has correct default ' . $ctx );
};

my_subtest 'delete accessor' => sub {
  my $stash = do {
    no strict;
    \%{'TestClassB::'};
  };

  delete $stash->{one};
  delete $stash->{two};

  my_subtest 'attr one' => sub {
    can_ok( $_->new, 'one' ) for 'TestClassA', 'TestClassB';

    is( TestClassA->new->one(), 'original default', 'A has correct default ' . $ctx );
    is( TestClassB->new->one(), 'original default', 'B has correct default ' . $ctx );
  };
  my_subtest 'attr two' => sub {

    can_ok( $_->new, 'two' ) for 'TestClassA', 'TestClassB';

    is( TestClassA->new->two(), 'original default(two)', 'A has correct default ' . $ctx );
    is( TestClassB->new->two(), 'original default(two)', 'B has correct default ' . $ctx );
  };
};
