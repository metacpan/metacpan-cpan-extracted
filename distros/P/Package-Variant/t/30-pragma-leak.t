use strictures 2;
use Test::More;
use Test::Fatal;
use Package::Variant ();

BEGIN {
  package TestPragma;
  use Package::Variant
    importing => [ 'strict' ];
  sub make_variant { }
  $INC{'TestPragma.pm'} = __FILE__;
}

is exception {
  eval q{
    no strict;
    use TestPragma;
    $var = $var;
    1;
  } or die $@;
}, undef, 'pragmas not applied where PV package used';

is exception {
  eval q{
    no strict;
    BEGIN { my $p = TestPragma(); }
    $var2 = $var2;
    1;
  } or die $@;
}, undef, 'pragmas not applied where PV generator used';

done_testing;
