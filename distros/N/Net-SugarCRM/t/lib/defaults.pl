#!perl
package Test;
use File::Temp;

our $login='admin';
our $pass='admin';
our $url='http://intranet.int.qindel.com/sugarcrm/service/v4/rest.php';
our $testcampaign='Demo Campaign';
our $testprospectlist='Demo users';
our $testemailmarketing='Demo User send password';
our $testdsn='DBI:mysql:database=sugarcrm;host=db.qindel.com';
our $testdbuser='sugarcrm';
our $testdbpass='sugarcrm';
our $testemail1='test@mailinator.com';
our $testemail2='test2@mailinator.com';
1;
