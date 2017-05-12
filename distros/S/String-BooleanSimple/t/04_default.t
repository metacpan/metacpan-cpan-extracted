

use lib '../lib','lib';

use strict;
use warnings;

use String::BooleanSimple ':all';

use Test::More tests => 312;


my @true = qw(true yes active enabled on y ok positive 1 2 3 4 5 6 7 8 9);

my @false = qw(false no inactive disabled off n negative 0);
push @false,"not ok";


foreach my $true (@true) {

  is( isTrue("",$true) , 1, "isTrue - String is \'$true\'" );
  is( isFalse("",$true) , 0, "isFalse - String is \'$true\'" );
  is( boolean("",$true) , 1, "boolean - String is \'$true\'" );


  is( isTrue("a",$true) , 1, "isTrue - String is \'$true\'" );
  is( isFalse("b",$true) , 0, "isFalse - String is \'$true\'" );
  is( boolean("c",$true) , 1, "boolean - String is \'$true\'" );

  is( isTrue($true,"false") , 1, "isTrue - String is \'$true\'" );
  is( isFalse($true,"false") , 0, "isFalse - String is \'$true\'" );
  is( boolean($true,"false") , 1, "boolean - String is \'$true\'" );

  is( isTrue($true,$true) , 1, "isTrue - String is \'$true\'" );
  is( isFalse($true,$true) , 0, "isFalse - String is \'$true\'" );
  is( boolean($true,$true) , 1, "boolean - String is \'$true\'" );


}

foreach my $false (@false) {


  is( isFalse("",$false) , 1, "isFalse - String is \'$false\'" );
  is( isTrue("",$false) , 0, "isTrue - String is \'$false\'" );
  is( boolean("",$false) , 0, "boolean - String is \'$false\'" );

  is( isFalse("a",$false) , 1, "isFalse - String is \'$false\'" );
  is( isTrue("b",$false) , 0, "isTrue - String is \'$false\'" );
  is( boolean("c",$false) , 0, "boolean - String is \'$false\'" );

  is( isFalse($false,"true") , 1, "isFalse - String is \'$false\'" );
  is( isTrue($false,"true") , 0, "isTrue - String is \'$false\'" );
  is( boolean($false,"true") , 0, "boolean - String is \'$false\'" );

  is( isFalse($false,$false) , 1, "isFalse - String is \'$false\'" );
  is( isTrue($false,$false) , 0, "isTrue - String is \'$false\'" );
  is( boolean($false,$false) , 0, "boolean - String is \'$false\'" );
# 
}


