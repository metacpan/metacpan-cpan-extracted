# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sudo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More  qw(no_plan);
use Data::Dumper;
#use Sudo;

BEGIN { 
	use_ok('Sudo') ;
#	die "FATAL ERROR: you must run these tests interactively!\n" if (!(-t STDIN));
      };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($user,$pass,$sudo,$id,$su,$rc,$sudosh);


print STDERR "\n\n-----\n";
$sudo = '/usr/bin/sudo';
printf STDERR  "sudo found at %s\n",$sudo if (-e $sudo);
SKIP: {
 skip "Not running interactively, so skipping interactive tests", 3 if (!(-t STDIN)); 
 while (! -e $sudo) 
   {
    print  STDERR "Enter full path to sudo (e.g. /usr/bin/sudo): \n";
    chomp($sudo=<>);
   }

$id = '/usr/bin/id';
printf  STDERR "id found at %s\n",$id if (-e $id);
while (! -e $id) 
   {
    print STDERR  "Enter full path to the \"id\" program (e.g. /usr/bin/id): \n ";
    chomp($id=<>);
   }
   
print STDERR  "\n\nEnter a user name to which you have a valid password: \n";
chomp($user=<>);
$pass = Term::ReadPassword::read_password('Enter the correct password for the user name you just entered: ');

$su = Sudo->new(
		{
		 username => $user, 
		 password=>$pass, 
		 sudo => $sudo, 
		 debug => '1',
		 program => $id
		}
	       );
$rc = $su->sudo_run;

ok (exists($rc->{stdout}), "Captured standard output");
ok (exists($rc->{rc}), "Captured return code");
ok (!exists($rc->{error}), "No error messages");
}
$su->{hostname}	= "localhost";  # assume you can ssh to localhost without a password
undef $rc;

SKIP: {
skip "Cannot run sudo tests non-interactively", 3 if (!(-t STDIN));
$rc = $su->sudo_run; 


ok (exists($rc->{stdout}), "Captured standard output");
ok (exists($rc->{rc}), "Captured return code");
ok (!exists($rc->{error}), "No error messages");

}
ok(1, "Got to end of tests");
#v0.20 Sudo.t:  Governed by the Artistic License
#copyright (c) 2004,2005 Scalable Informatics LLC
#http://www.scalableinformatics.com
