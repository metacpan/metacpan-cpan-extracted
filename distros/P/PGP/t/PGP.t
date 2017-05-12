# This will be the regression testing file

use PGP::Pipe;
use Cwd;

$text = 'This is some secret text';
$passwd = 'test';
$thisdir = getcwd;

			    
# test to see that the constructor works
$pgp = new PGP::Keyring $thisdir && print "1..ok\n";
@keys = List_Keys $pgp && print "2..ok\n";
Add_Key $pgp File => 'hickey.asc' && print "3..ok\n";
@keys = List_Keys $pgp && print "4..ok\n";

 


