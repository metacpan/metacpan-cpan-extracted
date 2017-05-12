
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

use T6AttrRequired::TestPackage;

pass("Syntax Compiles");

sub cr { return T6AttrRequired::TestPackage->new(@_) }

for ( {}, { roattr => "v" }, { rwattr => "v" }, { bareattr => 'v' } ) {
  isnt( exception { cr( %{$_} ) }, undef, 'Constraints on requirements still work' );
}

is( exception { cr( rwattr => 'v', roattr => 'v', bareattr => 'v', ) }, undef, 'Construction still works' );

my $i = cr( rwattr => 'v', roattr => 'v', bareattr => 'v', );

isnt( exception { $i->roattr('x') }, undef, "RO works still" );

is( exception { $i->rwattr('x') }, undef, 'RW works still' );

is( $i->rwattr(), 'x', "RW Works as expected" );

done_testing;
