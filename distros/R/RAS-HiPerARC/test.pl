#!/usr/bin/perl
# test script for RAS::HiPerARC
#######################################################


print <<EOF;

Test Suite for RAS::HiPerARC
EOF

### Get the hostname of the ARC to test
print <<EOF;

The tests will connect to a HiPerARC
and run some benign commands to verify that 
things are working properly.
Enter the hostname or IP address of a
HiPerARC that will be used for the tests.
Enter nothing to skip the tests.
EOF

print "Hostname or IP of ARC: ";
chomp($pm = <STDIN>);
exit unless $pm;


print <<EOF;

Please enter the login and password used 
to log into the ARC for the tests. This
login and password should start an interactive
shell with the ARC (e.g. a MANAGE user), not 
a PPP session (e.g. a NETWORK user).
EOF

print "Login for ARC: ";
chomp($login = <STDIN>);
print "Password for ARC: ";
chomp($password = <STDIN>);



print <<EOF;

Please enter a regular expression representing
the prompt on the HiPerARC. Do not include delimiters
or anchors. If you enter nothing, the default
of 'HiPer>> ' will be used, which usually works
just fine.
EOF

print "Prompt for HiPerARC: ";
chomp($prompt= <STDIN>);



print <<EOF;

The usergrep() test looks for a specified user on a bank
of ARCs. The userkill() function will look for
the specified user and knock them offline.
Specify here the user that will be located
and terminated. Enter nothing for 
these tests to be skipped.
EOF

print "Username for seek/kill tests: ";
chomp($testuser = <STDIN>);
print "\n\n";


######################################################
### And now that we have our data, the actual tests

use RAS::HiPerARC;

### Create a new instance
print "### Testing new() method for host $pm\n\n";
$foo = new RAS::HiPerARC(
   hostname => $pm,
   login => $login,
   password => $password,
   prompt => $prompt,
);
die "ERROR: Couldn't create object. Stopped " unless $foo;
print "OK.\n\n";

print "### Testing the printenv() method:\n";
$foo->printenv;
print "\n\n";

print "### Testing the run_command() method:\n";
($x,$y) = $foo->run_command('list interfaces','list connections');
print "Output of \'list interfaces\' on $pm:\n@$x\n\n";
print "Output of \'list connections\' on $pm:\n@$y\n\n";

print "### Testing portusage() method:\n";
@x = $foo->portusage;
print "There are ", shift(@x), " modems in all.\n";
print "There are ", scalar(@x), " users online. ";
print "They are:\n@x\n\n";

print "### Testing userports() method:\n";
%x = $foo->userports;
print "USERNAME  \tPORTS\n";
foreach (keys(%x)) {
   print "$_", (' ' x (10 - length($_))), "\t", join("\t",@{$x{$_}}), "\n";
}




if ($testuser) {
   print "### Testing usergrep() method on user $testuser\n";
   @x = $foo->usergrep($testuser);
   print "Found user $testuser on $pm ports: @x\n\n" if @x;
}
else { print "### Skipping usergrep() test\n"; }

if ($testuser) {
   print "### Testing userkill() method on user $testuser\n";
   @x = $foo->userkill($testuser);
   print "Killed user $testuser on $pm ports: @x\n\n" if @x;
}
else { print "### Skipping userkill() test\n"; }

print "Finished with tests.\n";


