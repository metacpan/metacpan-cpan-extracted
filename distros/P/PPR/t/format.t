use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 2;

use PPR;

my $source = q{
format STDOUT =
 ===================================
| NAME     |    AGE     | ID NUMBER |       
|----------+------------+-----------|       
| @<<<<<<< | @||||||||| | @>>>>>>>> |
  $name,     $age,        $ID,
|===================================|       
| COMMENTS                          |
|-----------------------------------|
| ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |~~
  $comments,
 =================================== 
.
};

ok $source =~ m{ \A (?&PerlOWS) (?&PerlFormat) (?&PerlOWS) \Z $PPR::GRAMMAR }xms => 'Matched format';


$source = q{
format =
 ===================================
| NAME     |    AGE     | ID NUMBER |       
|----------+------------+-----------|       
| @<<<<<<< | @||||||||| | @>>>>>>>> |
  $name,     $age,        $ID,
|===================================|       
| COMMENTS                          |
|-----------------------------------|
| ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |~~
  $comments,
 =================================== 
.
};

ok $source =~ m{ \A (?&PerlOWS) (?&PerlFormat) (?&PerlOWS) \Z $PPR::GRAMMAR }xms => 'Matched format';

done_testing();

