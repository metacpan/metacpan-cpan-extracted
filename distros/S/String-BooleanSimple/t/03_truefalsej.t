

use lib '../lib';

use strict;
use warnings;

use String::BooleanSimple ':all';

use Test::More tests => 78;


my @true = qw(true yes active enabled on y ok positive 1 2 3 4 5 6 7 8 9);

my @false = qw(false no inactive disabled off n negative 0);
push @false,"not ok";


foreach my $true (@true) {

  is( isTrue($true) , 1, "isTrue - String is \'$true\'" );
  is( isFalse($true) , 0, "isFalse - String is \'$true\'" );
  is( boolean($true) , 1, "boolean - String is \'$true\'" );

}

foreach my $false (@false) {

  is( isFalse($false) , 1, "isFalse - String is \'$false\'" );
  is( isTrue($false) , 0, "isTrue - String is \'$false\'" );
  is( boolean($false) , 0, "boolean - String is \'$false\'" );

}


1;
