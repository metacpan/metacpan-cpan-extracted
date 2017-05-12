
use strict;
use warnings;

use Test::More;

BEGIN {
  my $mod = 'Moose';
  local $@;
  eval qq[require $mod; 1];
  if ( my $e = $@ ) {
    my $msg = "$e";
    if ( $e =~ /^Can't locate/ ) {
      $msg = "Test requires module '$mod' but it's not found";
    }
    if ( $ENV{RELEASE_TESTING} ) {
      BAIL_OUT($msg);
    }
    else {
      plan skip_all => $msg;
    }
  }
}

use Test::Fatal;
use lib "t/lib";

use T8Saccharin::TestPackage;

sub cr {
  return T8Saccharin::TestPackage->new();
}

pass("Syntax Compiles");

is( exception { cr() }, undef, 'Construction still works' );

my $i = cr();

is( $i->roattr, 'y', 'Builders Still Trigger 1' );
is( $i->rwattr, 'y', 'Builders Still Trigger 2' );

isnt( exception { $i->roattr('x') }, undef, "RO works still" );

is( exception { $i->rwattr('x') }, undef, 'RW works still' );

is( $i->rwattr(), 'x', "RW Works as expected" );

done_testing;
