use strict;
use warnings;

use Test::More;

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

