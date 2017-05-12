########################################################
# Interactive Test - assumes *nix machine on remote end
########################################################
BEGIN{
   use Cwd;
   use File::Basename;
   use vars qw/@INC $dir/;
   $dir = dirname(cwd()) . "/blib/lib";
   unshift(@INC,$dir);
}

use strict;
use Net::SCP::Expect;
use Term::ReadPassword;
use Digest::MD5;
use File::Copy;

print "Using version: ", $Net::SCP::Expect::VERSION, "\n";

my $errors = 0; # Tracks total number of failures.

my $small_file  = "small_file.test";
my $rsmall_file  = "small_file.remote";
my $small_file2  = "small_file2.test";
my $small_file3  = "small_file3.test";

my $medium_file = "medium_file.test";
my $rmedium_file = "medium_file.remote";

my $large_file  = "large_file.test";
my $rlarge_file  = "large_file.remote";

##################################################
# Generate test files if they don't already exist
##################################################

my $file_contents = <<FILE;
This is the small file
For use in testing Net::SCP::Expect only
Delete at your convenience
FILE
foreach ($small_file, $small_file2, $small_file3) {
    unless (-f $_) {
        open(FILE, ">$_") or die "Couldn't create file [$_]: $!";
        print FILE $file_contents for 1..56; #~5KB
        close FILE;
    }
}

unless (-f $medium_file) {
    open(FILE, ">$medium_file") or die "Couldn't create file [$medium_file]: $!";
    print FILE $file_contents for 1..13564; #~1MB
    close FILE;
}
    
unless (-f $large_file) {
    open(FILE, ">$large_file") or die "Couldn't create file [$large_file]: $!";
    print FILE $file_contents for 1..461176; #~40MB
    close FILE;
}

######################
# Interactive section
######################

print "\nHost to copy test files to/from: ";
my $host = <STDIN>;
chomp $host;

print "Telnet or SSH (t/s): ";
my $proto = <STDIN>;
chomp $proto;

if($proto =~ /[tT]/)
{
   eval{ require Net::Telnet };
   if($@){
      print "You don't appear to have Net::Telnet installed; aborting\n";
      exit;
   }
   print "\n(Using Net::Telnet)\n\n";
}
elsif($proto =~ /[sS]/)
{
   eval{ require Net::SSH::Perl };
   if($@){
      print "You don't appear to have Net::SSH::Perl installed; aborting\n";
      exit;
   }
   print "\n(Using Net::SSH::Perl)\n\n";
}
else
{
   print "Unknown option: [$proto]; aborting\n";
   exit;
}

print "Login: ";
my $login = <STDIN>;
chomp $login;

my $password = read_password('Password: ');
chomp $password;

print "\nAttempting to copy files to [$host] as [$login]...\n\n";

# Modify this as you see fit
my $nse = Net::SCP::Expect->new(
   host     => $host,
   user     => $login,
   password => $password,
   auto_yes => 1,
);

##############################
# Setup our remote connection
##############################
my $rsh;
if($proto eq 's')
{
   $rsh = Net::SSH::Perl->new($host);
}
else
{
   $rsh = Net::Telnet->new($host);
}
$rsh->login($login,$password);

###############################
# login@host:file style syntax
###############################

print "1)Testing 'login\@host:filename' syntax\n";
print "=" x 40;
print "\n";

##################
# local to remote
##################
print "\nAttempting to copy $small_file to remote host\n";
$nse->scp($small_file,"$login\@$host:$rsmall_file");
verify($small_file,$rsmall_file,0);

print "\nAttempting to copy $medium_file to remote host\n";
$nse->scp($medium_file,"$login\@$host:$rmedium_file");
verify($medium_file,$rmedium_file,0);

print "\nAttempting to copy $large_file to remote host\n";
$nse->scp($large_file,"$login\@$host:$rlarge_file");
verify($large_file,$rlarge_file,0);

##################
# remote to local
##################
print "\nAttempting to copy $rsmall_file from remote host\n";
$nse->scp("$login\@$host:$rsmall_file",".");
verify($small_file,$rsmall_file,1);

print "\nAttempting to copy $rmedium_file from remote host\n";
$nse->scp("$login\@$host:$rmedium_file",".");
verify($medium_file,$rmedium_file,1);

print "\nAttempting to copy $rlarge_file from remote host\n";
$nse->scp("$login\@$host:$rlarge_file",".");
verify($large_file,$rlarge_file,1);

###############################################################################
# Note - I only test the small files from here on.  I figure if it worked
# once it will work again.  The primary reason for these tests is to verify
# that the syntax works properly.
###############################################################################

###############################
# host:file style syntax
###############################

print "\n2) Testing 'host:filename' syntax\n";
print "=" x 40;
print "\n";

# local to remote
print "\nAttempting to copy $small_file to remote host\n";
$nse->scp($small_file,"$host:$rsmall_file");
verify($small_file,$rsmall_file,0);

# remote to local
print "\nAttempting to copy $rsmall_file from remote host\n";
$nse->scp("$host:$rsmall_file",".");
verify($small_file,$rsmall_file,1);

#####################
# :file style syntax
#####################

print "\n3) Testing ':filename' syntax\n";
print "=" x 40;
print "\n";

# local to remote
print "\nAttempting to copy $small_file to remote host\n";
$nse->scp($small_file,":$rsmall_file");
verify($small_file,$rsmall_file);

# remote to local
print "\nAttempting to copy $small_file from remote host\n";
$nse->scp(":$rsmall_file",".");
verify($small_file,$rsmall_file,1);

###########################################################################
# : style syntax (note that this syntax is impossible in a remote-to-local
# scenario, so no test is done for that.
###########################################################################

print "\n4) Testing ':' syntax\n";
print "=" x 40;
print "\n";

# local to remote
print "\nAttempting to copy $small_file to remote host\n";
$nse->scp($small_file,":");
verify($small_file,$small_file); # Yes, this is correct.

##############################################
# If no ':' is found, assume local to remote.
##############################################
print "\n5) Testing assumed local to remote\n";
print "=" x 40;
print "\n";

# local to remote (only)
print "\nAttempting to copy $small_file to remote host\n";
$nse->scp($small_file,$rsmall_file);
verify($small_file,$rsmall_file); # Yes, this is correct.

################
# Test globbing
################
print "\n6) Testing glob copy\n";
print "=" x 40;
print "\n";

$nse->scp("small*.test",":");
verify("small_file.test","small_file.test");
verify("small_file2.test","small_file2.test");
verify("small_file3.test","small_file3.test");

# Move the .test files to .orig
move("small_file.test","small_file.orig");
move("small_file2.test","small_file2.orig");
move("small_file3.test","small_file3.orig");

# The text displayed here will be slightly erroneous, but the test is correct
$nse->scp(":small*.test",".");
verify("small_file.orig","small_file.test");
verify("small_file2.orig","small_file2.test");
verify("small_file3.orig","small_file3.test");

print "\nALL TESTS FINISHED\n";
print "=" x 40;
print "\n\n";

if($errors){
   print "TOTAL NUMBER OF FAILD TESTS: $errors\n";
}
else{
   print "ALL TESTS SUCCESSFUL!\n\n";
   print "Do you want to delete the test files (recommended) ? (y/n): ";
   my $ans = <STDIN>;
   chomp($ans);
   if($ans =~ /[Yy]/){
      unlink("*.test");
      unlink("*.orig");
      unlink("*.remote");
   }
}

##########################################################################
# Verifies checksum for two files.  The third argument is merely used to
# determine whether or not the second filename should be deleted.
##########################################################################
sub verify
{
   my($filename,$rfilename,$delete) = @_;

   my $cmd = "md5sum $rfilename";

   my($out,$err,$exit) = $rsh->cmd($cmd);

   chomp($out);
   my($rdigest) = split(/\s+/,$out);

   open(FH,$filename) or die "Couldn't open [$filename]: $!\n";
   my $ldigest = Digest::MD5->new->addfile(*FH)->hexdigest;
   close FH;

   if($rdigest == $ldigest){
      print "The file [$filename] was copied successfully\n";
   }
   else{
      print "The file [$filename] did NOT copy successfully\n";
      $errors++;
   }

   if($delete){ $rsh->cmd("rm -f $rfilename") }
}
