### RAS::PortMaster.pm
### PERL 5 module for accessing a Livingston PortMaster
#########################################################

package RAS::PortMaster;
$RAS::PortMaster::VERSION = "1.16";

use strict;

# This uses Net::Telnet to connect to the RAS
use Net::Telnet ;

# The name $ras will be used consistently as the
# reference to the RAS::PortMaster object we're handling


# The constructor method, of course
sub new {
   my($class) = shift ;
   my($ras) = {} ;
   %{$ras} = @_ ;
   $ras->{'VERSION'} = $RAS::PortMaster::VERSION;
   bless($ras);
}


# for debugging - printenv() prints to STDERR
# the entire contents of %$ras
sub printenv {
   my($ras) = shift;
   while (my($key,$value) = each(%{$ras})) { print "$key = $value\n"; }
}


# This runs the specified commands on the router and returns
# a list of refs to arrays containing the commands' output
sub run_command {
   my($ras) = shift;
   my(@returnlist);

   while (my $command = shift) {
      my($session) = new Net::Telnet;
      $session->errmode("return");

      # connect
      $session->open($ras->{'hostname'});
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras),' - ',$session->errmsg,"\n"; return(); }
      # login
      $session->login($ras->{'login'},$ras->{'password'});
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras),' - ',$session->errmsg,"\n"; return(); }
      # we got logged in, so send the command
      $session->print($command);
      $session->print(""); # for some reason, this is necessary to make the prompt appear after the output

      my(@output);
      while (1) {
         my($line) = $session->getline;
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras),' - ',$session->errmsg,"\n"; return(); }
         if ($line =~ /^\s*$/) { next; }
         if ($line =~ /^-- Press Return for More --\s+$/) { $session->print(""); next; }
         if ($line =~ /^[\w\.\-]+\>\s+$/) { $session->print("quit"); $session->close; last; }
         push(@output, $line);
      }


      # Net::Telnet to the PM leaves the echoed command at the start
      shift(@output);
      push(@returnlist, \@output);
   } # end of shifting commands

   # We're returning a list of references to lists.
   # Each ref points to an array containing the returned text
   # from the command, and the list of refs corresponds
   # to the list of commands we were given
   return(@returnlist);
} # end of run_command


# usergrep() - takes a username and returns an array of
# ports on which the user was found
sub usergrep {
   my($ras) = shift;
   my($username) = shift; return() unless $username;
   my($output) = $ras->run_command('sho ses');
   my(@ports);

   foreach (@$output) {
      next unless /^(S\d+)\s+$username\s+/;
      push(@ports, $1);
   }
   return(@ports);
}


# portusage() returns a list: # of ports, list of users
sub portusage {
   my($ras) = shift;
   my($output) = $ras->run_command('sho ses');
   my(@users,$totalports);
   $totalports = 0;

   foreach (@$output) {
      next unless /^S\d+\s+(\S+)\s+/;
      $totalports++;
      next if ($1 =~ /^PPP|\-$/);
      push(@users, $1);
   }
   return($totalports,@users);
}


# This does a usergrep() and then disconnects the specified user
sub userkill {
   my($ras) = shift;
   my($username); $username = shift; return() unless $username;
   my(@ports) = $ras->usergrep($username);
   return('') unless @ports;

   my @resetcmd = ();
   foreach (@ports) { push(@resetcmd,"reset $_"); }
   $ras->run_command(@resetcmd);

   return(@ports);
}


#############################################################
1;#So PERL knows we're cool
__END__;

=head1 NAME

RAS::PortMaster.pm - PERL Interface to Livingston PortMaster 2

Version 1.15, January 17, 2000

Gregor Mosheh (stigmata@blackangel.net)

=head1 SYNOPSIS

B<RAS::PortMaster> is a PERL 5 module for interfacing with a Livingston PortMaster remote access server. Using this module, one can very easily construct programs to find a particular user in a bank of PMs, disconnect users, get usage statistics, or execute arbitrary commands on a PM.


=head1 PREREQUISITES AND INSTALLATION

This module uses Jay Rogers' B<Net::Telnet module>. If you don't have B<Net::Telnet>, get it from CPAN or this module won't do much for you.

Installation is easy, thanks to MakeMaker:

=over 4

=item 1.

"perl Makefile.PL && make && make test"

=item 2.

If the tests went well, do a "make install"

=item 3.

Check out the EXAMPLES section of this document for examples on how you'd want to use this module.

=back

=head1 DESCRIPTION

At this time, the following methods are implemented:

=over 4

=item creating an object with new

Call the new method while supplying the  "hostname", "login", and "password" hash, and you'll get an object reference returned.

   Example:
      use RAS::PortMaster;
      $foo = new RAS::PortMaster(
         hostname => 'dialup1.example.com',
         login => '!root',
         password => 'mysecret'
      );

Since there's no sense in dynamically changing the hostname, password, etc. no methods are supplied for modifying them and they must be supplied statically to the constructor. No error will be generated if anything is left out, though it's likely that your program won't get far without supplying a proper hostname and password...


=item VERSION

This is an attribute, not a method, containing a string of the module version:

   Example:
      printf("Module version %s", $foo->{'VERSION'});


=item printenv

This is for debugging only. It prints to STDOUT a list of its configuration hash, e.g. the hostname, login, and password. The printenv method does not return a value.

   Example:
      $foo->printenv;


=item run_command

This takes a list of commands to be executed on the PortMaster, executes the commands, and returns a list of references to arrays containg the text of each command's output. 

Repeat: It doesn't return an array, it returns an array of references to arrays. Each array contains the text output of each command. Think of it as an array-enhanced version of PERL's `backtick` operator.

   Example:
      # Execute a command and print the output
      $command = 'sho ses';
      ($x) = $foo->run_command($command);
      print "Output of command \'$command\':\n", @$x ;

   Example:
      # Execute a string of commands
      # and show the output from one of them
      (@output) = $foo->run_command('reset S15','sho ses');
      print @$output[1] ;


=item usergrep

Supply a username as an argument, and usergrep will return an array of ports on which that user was found (or an empty array if they weren't found). A undefined value is returned if no username was supplied. Internally, this does a run_command("sho ses") and parses the output.

   Example:
      @ports = $foo->usergrep('gregor');
      print "User gregor was found on ports @ports\n";


=item userkill

This does a usergrep, but with a twist: it disconnects the user by resetting the modem on which they're connected. Like usergrep, it returns an array of ports to which the user was connected before they were reset (or an empty array if they weren't found). An undefined value is returned if no username was supplied.

Because the PortMaster shows even ports that are not in use and shows the username as '-', you can userkill a username of "-" to reset all idle modems.

   Examples:
      @foo = $foo->userkill('gregor');
      print "Gregor was on ports @foo - HA HA!\n" if @ports ;

      @duh = $foo->userkill('-');
      print "There were ", scalar(@duh), " ports open.\n";


=item portusage

This returns an array consisting of 2 parts: The 1st element is the number of ports. The rest is a list of users who are currently online.

   Examples:
      @people = $foo->portusage;
      print "There are ", shift(@people), " total ports.\n";
      print "There are ", scalar(@people), "people online.\n";
      print "They are: @people\n";

      ($ports,@people) = $foo->portusage;
      print "Ports free: ", $ports - scalar(@people), "\n";
      print "Ports used: ", scalar(@people), "\n";
      print "Ports total: ", $ports, "\n";


=head1 EXAMPLE PROGRAMS

portusage.pl - Summarizes port usage on a bank of PMs

use RAS::PortMaster;
$used = $total = 0;
foreach ('pm1.example.com','pm2.example.com','pm3.example.com') {
   $foo = new RAS::PortMaster(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   local(@ports,$ports);
   ($ports,@ports) = $foo->portusage;
   $total += $ports;
   $used += scalar(@ports);
}

print "$used out of $total ports are in use.\n";

#####

usergrep.pl - Locate a user on a bank of PMs

($username) = @ARGV;
die "Usage: $0 <username>\nFinds the specified user.\n" unless $username ;

use RAS::PortMaster;

foreach ('pm1.example.com','pm2.example.com','pm3.example.com') {
   $foo = new RAS::PortMaster(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   @ports = $foo->usergrep($username);
   (@ports) && print "Found user $username on $_ ports @ports\n";
}

#####

userkill.pl - Kick a user off a bank of PMs

($username) = @ARGV;
die "Usage: $0 <username>\nDisconnects the specified user.\n" unless $username ;

use RAS::PortMaster;

foreach ('pm1.example.com','pm2.example.com','pm3.example.com') {
   $foo = new RAS::PortMaster(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   @ports = $foo->userkill($username);
   (@ports) && print "$_ : Killed ports @ports\n";
}


=head1 CHANGES IN THIS VERSION

1.16     Cleaned up that stupid $afterprompt code, and made the module work with prompt containing . and - characters. In my testing, the module now seems to work with PortMaster 3. I hope it still works with the PM2, though I don't see why not.

1.15     Cleaned up the code significantly. Fixed the prompt code to avoid infinite loops in the case of a prompt mismatch - it now times out appropriately.

1.14     Fixed a leak in run_command. I swear I test this stuff before I upload it, really!

1.13     Added a test suite. Fixed some documentation errors. Added some error handling.

1.12     Bug fixes. Optimized userkill() for better performance.

1.11     The package name got mangled when I zipped everything up, and was thus useless. This has been fixed. Sorry. Also moved the example programs into this document for easy availability. Also fixed an intermittent problem with PERL not liking my use of shift() on a routine call.

1.00     First release, November 1999.

=head1 BUGS

The set of supplied functions is a bit bare. Since we use this for port usage monitoring, new functions will be added slowly on an as-needed basis. If you need some specific functionality let me know and I'll see what I can do. If you write an addition for this, please send it in and I'll incororate it and give credit.

I make some assumptions about router prompts based on what I have on hand for experimentation. If I make an assumption that doesn't apply to you (e.g. all prompts are /^\w+\>\s+/) then you could get "pattern match timeout" errors. If this happens, you may be using the wrong RAS module to connect the the router (e.g. don't use RAS::PortMaster to connect to a Cisco AS5200). Otherwise, check the regexps in the loop within run_command, and make sure your prompt fits this regex. If not, either fix the regex and/or (even better) PLEASE send me some details on your prompt and what commands you used to set your prompt.


=head1 LICENSE AND WARRANTY

Where would we be if Larry Wall were tight-fisted with PERL itself? For God's sake, it's PERL code. It's free!

This software is hereby released into the Public Domain, where it may be freely distributed, modified, plagiarized, used, abused, and deleted without regard for the original author.

Bug reports and feature requests will be handled ASAP, but without guarantee. The warranty is the same as for most freeware:
   It Works For Me, Your Mileage May Vary.

=cut

