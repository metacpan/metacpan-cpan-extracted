use Test::More tests => 4;

use strict;
use warnings;
use FindBin;
use Path::Class;
use MooseX::Templated::Util qw/ where_pm /;

use lib "$FindBin::Bin/lib";

my $libdir = dir( $FindBin::Bin, "lib" );

{
  my ($abs_path, $inc_path, $require) = where_pm( 'Farm::Cow' );

  is( $abs_path, file($libdir, 'Farm', 'Cow.pm') );
  is( $inc_path, $libdir );
  is( $require, file('Farm', 'Cow.pm') );
}

{
  my $abs_path = where_pm( 'Farm::Cow' );
  is( $abs_path, file($libdir, 'Farm', 'Cow.pm') );
}

1;
