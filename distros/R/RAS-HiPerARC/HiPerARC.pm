## RAS::HiPerARC.pm
### PERL module for accessing a 3Com/USR Total Control HiPerARC
#########################################################

package RAS::HiPerARC;
$VERSION = "1.03";

use strict "subs"; use strict "refs";

# This uses Net::Telnet to connect to the RAS
use Net::Telnet ;

# The name $ras will be used consistently as the
# reference to the RAS::HiPerARC object we're handling

# The constructor method, of course
sub new {
   my($class) = shift ;
   my($ras) = {} ;
   %$ras = @_ ;

   unless ($ras->{hostname}) { warn "ERROR: ", (ref($class) || $class), " - Hostname not specified.\n"; return(); }
   $ras->{'VERSION'} = $VERSION;
   $ras->{prompt} = 'HiPer>> ' unless $ras->{prompt};

   bless($ras, ref($class) || $class);
}


# for debugging - printenv() prints to STDERR
# the entire contents of %$ras
sub printenv {
   my($ras) = shift;
   while (($key,$value) = each(%$ras)) { warn "$key = $value\n"; }
}


# This runs the specified commands on the router and returns
# a list of refs to arrays containing the commands' output
sub run_command {
   my($ras) = shift;
   my(@returnlist);
   my($prompt) = '/' . $ras->{prompt} . '$/';

   while ($command = shift) {
      my($session) = new Net::Telnet;
      $session->errmode("return");
      $session->open($ras->{hostname});
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras)," - Cannot connect to host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
      $session->login($ras->{login},$ras->{password});
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras)," - Logging in to host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
      $session->print("\n"); $session->waitfor($prompt);
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras)," - Waiting for command prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
      $session->print($command);
      my(@output);

      while (1) {
         $session->print(""); my($line) = $session->getline ;
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting on output from command \"$command\" on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
         if ($line =~ /^$ras->{prompt}$/) { $session->print('quit'); $session->close; last; }

         # After the 1st More prompt, the ARC sends
         # ^M\s{a whole line's worth}^M to clear each line for printing
         $line =~ s/^--More--\s+\015?\s*\015?//;
         # Trim off trailing whitespace
         $line =~ s/\s*$/\n/;

         push(@output, $line);
      }

      shift(@output); # Trim the echoed command
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
   my($output) = $ras->run_command('list connections');
   my(@ports);

   foreach (@$output) {
      my($port,$user);
      next unless /^slot:\d+\/mod:\d+\s+/;
      $port = unpack("x0 a15", $_) ; $port =~ s/^\s*(\S+)\s*$/$1/;
      $user = unpack("x15 a20", $_); $user =~ s/^\s*(\S+)\s*$/$1/;
      ($user eq $username) && push(@ports,$port);
   }
   return(@ports);
}


# userports() returns a hash of arrays
# keys are the usernames of all users currently connected
# values are arrays of ports that that user in connected on
sub userports {
   my($ras) = shift;
   my($output) = $ras->run_command('list conn');
   my(%userports);

   foreach (@$output) {
      my($port,$user);
      next unless /^slot:\d+\/mod:\d+\s+/;
      $port = unpack("x0 a15", $_) ; $port =~ s/^\s*(\S+)\s*$/$1/;
      $user = unpack("x15 a20", $_); $user =~ s/^\s*(\S+)\s*$/$1/;
      push(@{$userports{$user}},$port);
   }
   return(%userports);
}


# portusage() returns a list: # of ports, list of users
sub portusage {
   my($ras) = shift;
   my($interfaces,$connections) = $ras->run_command('list interfaces','list connections');
   my(@users);

   @$interfaces = grep(/^slot:\d+\/mod:\d+\s+Up\s+Up\s*$/, @$interfaces);

   foreach (@$connections) {
      my($port,$user);
      next unless /^slot:\d+\/mod:\d+\s+/;
      $user = unpack("x15 a20", $_); $user =~ s/^\s*(\S+)\s*$/$1/;
      next if ($user =~ /^\s*$/);
      push(@users,$user);
   }

   return(scalar(@$interfaces),@users);
}


# This does a usergrep() and then disconnects the specified user
sub userkill {
   my($ras) = shift;
   my($username); $username = shift; return() unless $username;
   my(@ports) = $ras->usergrep($username);
   return('') unless @ports;

   my($resetcmd) = "reset modems " . join(',',@ports);
   $ras->run_command($resetcmd);
   return(@ports);
}


#############################################################
1;#So PERL knows we're cool
__END__;

=head1 NAME

RAS::HiPerARC.pm - PERL Interface to 3Com/USR Total Control HiPerARC

Version 1.03, June 9, 2000


=head1 SYNOPSIS

B<RAS::HiPerARC> is a PERL 5 module for interfacing with a 3Com/USR Total Control HiPerARC remote access server. Using this module, one can very easily construct programs to find a particular user in a bank of ARCs, disconnect users, get usage statistics, or execute arbitrary commands on a ARC.


=head1 PREREQUISITES AND INSTALLATION

This module uses Jay Rogers' B<Net::Telnet module>. If you don't have B<Net::Telnet>, get it from CPAN or this module won't do much for you.

Installation is easy, thanks to MakeMaker:

=over 4

=item 1.

"perl Makefile.PL && make && make test"

=item 2.

If the tests worked all right, "make install"

=item 3.

Check out the examples in this documentation.

=back

=head1 DESCRIPTION

At this time, the following methods are implemented:

=over 4


=item creating an object with new

Use the new() method to create a new object.

   Example:
      use RAS::HiPerARC;
      $foo = new RAS::HiPerARC(
         hostname => 'dialup1.example.com',
         login => '!root',
         password => 'mysecret',
      );

The following variables are useful:
   hostname - The hostname of the router to connect to
   login - The login name to get a command-line on the router
   password - The password to the login name supplied
   prompt - See below


Since there's no point in dynamically changing the hostname, login, etc. these settings are static and must be supplied to the constructor. No error will be returned if these settings are not specified (except for the hostname, which is required), but your program will likely not get very far without at least a hostname and a correct password.

Prompt handling has been vastly improved. If a prompt is not specified, a reasonable default is assumed that should work just fine. If you want to specify a prompt, supply a regular expression without delimiters or anchors that represents your router's prompt, e.g. prompt => 'hiper>' If you get errors about a bad match operator or a bad delimiter, you likely have a bad prompt string.


=item printenv

This is for debugging only. It prints to STDOUT a list of its configuration hash, e.g. the hostname, login, and password. The printenv method does not return a value.

   Example:
      $foo->printenv;


=item run_command

This takes a list of commands to be executed on the ARC, executes the commands, and returns a list of references to arrays containg the text of each command's output. 

Repeat: It doesn't return an array, it returns an array of references to arrays. Each array contains the text output of each command. Think of it as an array-enhanced version of PERL's `backtick` operator.

   Example:
      # Execute a command and print the output
      $command = 'list conn';
      ($x) = $foo->run_command($command);
      print "Output of command \'$command\':\n", @$x ;

   Example:
      # Execute a string of commands
      # and show the output from one of them
      (@output) = $foo->run_command('list interface','list con');
      print "Modems:\n@$output[0]\n\n";;
      print "Current connections:\n@$output[1]\n\n";;


=item usergrep

Supply a username as an argument, and usergrep will return an array of ports on which that user was found (or an empty array, if they're not found). If no username is supplied, returns undefined. Internally, this does a run_command('list connections') and parses the output.

   Example:
      @ports = $foo->usergrep('gregor');
      print "User gregor was found on ports @ports\n";


=item userkill

This does a usergrep, but with a twist: it disconnects the user by resetting the modem on which they're connected. Like usergrep, it returns an array of ports to which the user was connected before they were reset or an empty array if they weren't found. An undef is returned if no username was supplied.

   Examples:
      @foo = $foo->userkill('gregor');
      print "Gregor was on ports @foo - HA HA!\n" if @ports ;

      @duh = $foo->userkill('-');
      print "There were ", scalar(@duh), " ports open.\n";


=item portusage

This returns an array consisting of 2 items: The 1st element is the number of ports. The rest is a list of users who are currently online.

   Examples:
      ($ports,@people) = $foo->portusage;
      print "There are $ports total ports.\n";
      print "There are ", scalar(@people), "people online.\n";
      print "They are: @people\n";

      ($ports,@people) = $foo->portusage;
      print "Ports free: ", $ports - scalar(@people), "\n";
      print "Ports used: ", scalar(@people), "\n";
      print "Ports total: ", $ports, "\n";


=item userports

This returns a hash with the key of each item being a username. The value of each item is an array of the ports that that username is currently using. This provides some information that a simple usergrep() lacks.

   Example:
      %userports = $foo->userports;
      foreach $user (keys(%userports)) {
        foreach $port (@{$userports{$user}}) {
             print "User: $user is on $port\n";
         }
      }


=head1 EXAMPLE PROGRAMS

portusage.pl - Prints a summary of port usage on a bank of modems

use RAS::HiPerARC;
$used = $total = 0;
foreach ('arc1.example.com','arc2.example.com','arc3.example.com') {
   $foo = new RAS::HiPerARC(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   local($ports,@ports) = $foo->portusage;
   $total += $ports;
   $used += scalar(@ports);
}

print "$used out of $total ports are in use.\n";

###

usergrep.pl - Finds a user on a bank of modems

($username) = @ARGV;
die "Usage: $0 <username>\nFinds the specified user.\n" unless $username ;

use RAS::HiPerARC;
foreach ('arc1.example.com','arc2.example.com','arc3.example.com') {
   $foo = new RAS::HiPerARC(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   @ports = $foo->usergrep($username);
   (@ports) && print "Found user $username on $_ ports @ports\n";
}

###

userkill.pl - Kick a user off a bank of modems. Makes a great cron job. ;)

($username) = @ARGV;
die "Usage: $0 <username>\nDisconnects the specified user.\n" unless $username ;

use RAS::HiPerARC;
foreach ('arc1.example.com','arc2.example.com','arc3.example.com') {
   $foo = new RAS::HiPerARC(
      hostname => $_,
      login => '!root',
      password => 'mysecret'
   );

   @ports = $foo->userkill($username);
   (@ports) && print "$_ : Killed ports @ports\n";
}


=head1 CHANGES IN THIS VERSION

1.03     Added userports() method. Added better prompt support (YAY!). Made error messages more useful.

1.02     Fixed portusage() to only count Up interfaces. The ARC remembers modems even when they've been removed, and this accounts for that oddity. Cleaned up the code substantially. Fixed the prompt-matching code so that a prompt mismatch will cause run_command() to return instead of hanging in a loop.

1.01     Added a test suite. Corrected some errors in the documentation. Improved error handling a bit.


=head1 AUTHORS, MAINTAINERS, AND CONTACT INFO

RAS::HiPerARC uses the Net::Telnet module by Jay Rogers <jay@rgrs.com> - thank you, Jay!

Gregor Mosheh <stigmata@blackangel.net> wrote RAS::HiPerARC originally, but the prompt handling needed some help in case people cuztomized their prompts.

Luke Robins <luker@vicnet.net.au> and Todd Caine <todd_caine@eli.net> helped out substantially with the prompt handling with RAS::AS5200 and the changes were carried over into RAS::HiPerARC. Thank you, Luke and Todd!

The maintainer of RAS::HiPerARC is Gregor Mosheh, at the address above.


=head1 BUGS

Since we use this for port usage monitoring, new functions will be added slowly on an as-needed basis. If you need some specific functionality let me know and I'll see what I can do. If you write an addition for this, please send it in and I'll incororate it and give credit.


=head1 LICENSE AND WARRANTY

Where would we be if Larry Wall were tight-fisted with PERL itself? For God's sake, it's PERL code. It's free!

This software is hereby released into the Public Domain, where it may be freely distributed, modified, plagiarized, used, abused, and deleted without regard for the original author.

Bug reports and feature requests will be handled ASAP, but without guarantee. The warranty is the same as for most freeware:
   It Works For Me, Your Mileage May Vary.

=cut

