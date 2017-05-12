### AS5200.pm
### PERL module for talking to a Cisco AS5200 access router
#########################################################

package RAS::AS5200;
$VERSION = "1.04";

use strict "subs"; use strict "refs";

# This uses Net::Telnet to connect to the RAS
use Net::Telnet ;

# The name $ras will be used consistently as the
# reference to the RAS::AS5200 object we're handling

# The constructor method, of course
sub new {
   my($class) = shift ;
   my($ras) = {} ;
   %$ras = @_ ;

   unless ($ras->{hostname}) { warn "ERROR: ", (ref($class) || $class), " - Hostname not specified.\n"; return(); }
   $ras->{'VERSION'} = $VERSION;
   $ras->{prompt} = '\w*[>#]' unless $ras->{prompt};

   bless($ras, ref($class) || $class);
}


# for debugging - printenv() prints to STDERR
# the entire contents of %$ras
sub printenv {
   my($ras) = shift;
   while (($key,$value) = each(%$ras)) { warn "$key = $value\n"; }
   return();
}


# run_command() is the heart of this module's functionality
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

      # If a login name is supplied, wait for the Login: prompt.
      # Otherwise, send a blank password.
      # This is a workaround for 2 changes in early versions of IOS 11
      # 1. IOS 11.3 asks for login and password, 11.2 asks only for password
      # 2. IOS 11.2 - the first password prompt fails to authenticate about
      #    1/4 of the time, so it's best to send a blank password for the
      #    first password prompt
      if ($ras->{login}) {
         $session->waitfor('/Login: $/i');
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting for login prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
         $session->print($ras->{login});
      }
      else {
         $session->waitfor('/Password: $/i');
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting for password prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
         $session->print("");
      }
      $session->waitfor('/Password: $/i');
      $session->print($ras->{password});
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras)," -  Waiting for password prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }

      # Okay, we're logged in. Get the command prompt.
      $session->waitfor($prompt);
      if ($session->errmsg) {
         warn "ERROR: ",ref($ras)," - Waiting for command prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
      my(@output);

      # If the command was prefixed with "ENABLE " then go into enable mode first.
      if ($command =~ s/^ENABLE //) {
         $session->print("enable");
         $session->waitfor('/Password: $/');
         $session->print($ras->{enablepassword});
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting for enable password prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
         $session->waitfor($prompt);
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting for post-enable command prompt on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
      }

      # Send the command and keep paging down and grab the output
      $session->print($command);
      while (1) {
         $session->print(""); my($line) = $session->getline;
         if ($session->errmsg) {
            warn "ERROR: ",ref($ras)," - Waiting on output from command \"$command\" on host $ras->{hostname} - ",$session->errmsg,"\n"; return(); }
         if ($line eq "[confirm]") { $session->print("y"); next; }
         if ($line =~ /^$ras->{prompt}$/) { $session->print("exit"); $session->close; last; }
         $line =~ s/^\s?--More--\s*\010+\s+\010+//;
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
   if ($ras->{truncateusernames}) { $username = substr($username,0,10); }
   my($output) = $ras->run_command('show users');
   my(@ports);

   foreach (@$output) {
      my($port,$user);
      next unless (/^\s+\d+ tty \d+\s/ || /^\s+Se\d+\:\d+\s/);
      $port = unpack("x0 a12", $_) ; $port =~ s/^\s*\d* //; $port =~ s/\s*$//;
      $user = unpack("x13 a10", $_); $user =~ s/^\s*//; $user =~ s/\s*$//;
      ($user eq $username) && push(@ports,$port);
   }
   return(@ports);
}


# userports() returns a hash of arrays
# keys are the usernames of all users currently connected
# values are arrays of ports that that user in connected on
sub userports {
   my($ras) = shift;
   my($output) = $ras->run_command('show users');
   my(%userports);

   foreach (@$output) {
     my($port,$user);
     next unless (/^\s+\d+ tty \d+\s/ || /^\s+Se\d+\:\d+\s/);
     $port = unpack("x0 a12", $_) ; $port =~ s/^\s*\d* //; $port =~ s/\s*$//;
     $user = unpack("x13 a10", $_); $user =~ s/^\s*//; $user =~ s/\s*$//;
     push(@{$userports{$user}},$port);
   }
   return(%userports);
}


# portusage() returns an array: 1st element is the # of ports and the
# rest of the elements are usernames of users currently logged on
sub portusage {
   my($ras) = shift;
   my($interfaces,$connections) = $ras->run_command('sho isdn status','show users');
   my(@users, $totalports);

   $totalports = 23 * scalar(grep(/^ISDN Serial\S+ interface$/, @$interfaces));

   foreach (@$connections) {
      my($port,$user);
      next unless (/^\s+\d+ tty \d+ / || /^\s+Se\d+\:\d+ /);
      $user = unpack("x13 a10", $_); $user =~ s/^\s*(\S+)\s*$/$1/;
      next if ($user =~ /^\s*$/);
      push(@users,$user);
   }

   return($totalports,@users);
}


# userkill() does a usergrep() and then disconnects the specified user
sub userkill {
   my($ras) = shift;
   my($username); $username = shift; return() unless $username;
   if ($ras->{truncateusernames}) { $username = substr($username,0,10); }
   my(@ports) = $ras->usergrep($username);
   return('') unless @ports;

   my(@killcommands);
   foreach (@ports) {
      if (/^tty/)   { push(@killcommands, "ENABLE clear line $_"); }
      elsif (/^Se/) { push(@killcommands, "ENABLE clear int $_"); }
   }

   $ras->run_command(@killcommands);
   return(@ports);
}


# killexcessoutoctets() takes a bytelimit and if a interfaces
# outoctets/bytes exceeds that limit the interface is cleared and then the
# counters for the interface are reset. Used to stop radius counters
# wrapping ie. 32 bit signed int wraps into negative at about 2 gig
sub killexcessoutoctets {
  my($ras) = shift;
  my($bytelimit) = shift;
  my %userports = $ras->userports;

  foreach $user (keys %userports) {
    foreach $arraycnt (0 .. (@{$userports{$user}} - 1)) {
      my($result) = $ras->run_command('show interface ' .  $userports{$user}[$arraycnt]);
      foreach (@$result) {
        next unless (/\s+\d+ packets output, (\d+) bytes.+/); 
        my $outoctets = $1;
        if ($outoctets > $bytelimit) {
          $ras->run_command('ENABLE clear int ' .  $userports{$user}[$arraycnt] , 'ENABLE clear counter ' .  $userports{$user}[$arraycnt]);
           next;
        }
      }
    }
  }
 return(1);
}

#############################################################

1;#So PERL knows we're cool

__END__;


=head1 NAME

RAS::AS5200.pm - PERL Interface to Cisco AS5200 Access Router

Version 1.04, June 9, 2000


=head1 SYNOPSIS

B<RAS::AS5200> is a PERL 5 module for interfacing with a Cisco AS5200 access router. Using this module, one can very easily construct programs to find a particular user in a bank of AS5200s, disconnect users, get usage statistics, or execute arbitrary commands on a AS5200.


=head1 PREREQUISITES AND INSTALLATION

This module uses Jay Rogers' B<Net::Telnet module>. If you don't have B<Net::Telnet>, get it from CPAN or this module won't do much for you.

Installation is easy, thanks to MakeMaker:

=over 4

=item 1.

"perl Makefile.PL && make"

=item 2.

"make test" to run the test suite. Check the test output. It should seem correct. If there are errors, check the hostname and passwords and try again.

=item 3.

If all is good, do a "make install"

=item 4.

Check out the examples in this documentation. Also, some programs based on the RAS:: series of modules will be made available on CPAN at the same place as this module.

=back

=head1 DESCRIPTION

At this time, the following methods are implemented:

=over 4

=item creating an object with new

Use the new() method to create a new object.

   Example:
      use RAS::AS5200;
      $foo = new RAS::AS5200(
         hostname => 'dialup1.example.com',
         login => '!root',
         password => 'mysecret',
         truncateusernames => 'true'
      );

The following variables are useful:
   hostname - The hostname of the router to connect to
   login - The login name to get a command-line on the router
   password - The password to the login name supplied
   enablepassword - The enable password to the router
   truncateusernames - See below
   prompt - See below

Since there's no point in dynamically changing the hostname, login, etc. these settings are static and must be supplied to the constructor. No error will be returned if these settings are not specified (except for the hostname, which is required), but your program will likely not get very far without at least a hostname and a correct password. Some older IOS versions such as Version 11.2(15a) only require a password and not a login name -- if a login name is supplied, it is assumed that your router is not one of these and a full login-and-password script will be used; if a login name is not supplied, it is assumed that your router only requires a password to log in.

The enablepassword is only required if you'll be using commands that require enable status on the router. This includes the userkill() and killexcessoutoctets() methods and would also include, for example, run_command('reload').

If the "truncateusernames" option is set to non-null, then usernames supplied to user-seeking functions such as userkill() and usergrep() will be internally truncated to 10 characters. This is to work around a "feature" of the AS5200 that only the first 10 characters of a login name are displayed, which would cause usergrep('johnjjschmidt') to never work, as the AS5200 displays the login name as 'johnjjschm'. See the TRUNCATING USER NAMES section for more discussion on this.

Prompt handling has been vastly improved. If a prompt is not specified, a reasonable default is assumed that should work just fine. If you want to specify a prompt, supply a regular expression without delimiters or anchors that represents your router's prompt, e.g. prompt => 'as5200[>#]' If you get errors about a bad match operator or a bad delimiter, you likely specified anchros and/or delimiters.


=item printenv

This is for debugging. It prints to STDERR a list of its configuration hash, e.g. the hostname, login, and password. The printenv method does not return a value.

   Example:
      $foo->printenv;


=item run_command

This takes a list of commands to be executed on the AS5200, executes the commands, and returns a list of references to arrays containg the text of each command's output. Repeat: It doesn't return an array, it returns an array of references to arrays. Each array contains the text output of each command. Think of it as an array-enhanced version of PERL's `backtick` operator.

Some router functions (e.g. rebooting) ask for confirmation - confirmation will be automatically supplied by the module's interface routine.

   Example:
      # Execute a command and print the output
      $command = 'show modems';
      ($x) = $foo->run_command($command);
      print "Output of command \'$command\':\n", @$x ;

   Example:
      # Execute a string of commands
      # and show the output from one of them
      (@output) = $foo->run_command('show isdn status','show modems');
      print "Modems:\n@$output[0]\n\n";;
      print "Current connections:\n@$output[1]\n\n";;

In Cisco-land, some functions are only available in enabled mode. To specify that a command should be run in enabled mode, prefix the command with "ENABLE " - that's all caps and a single space between the ENABLE and the rest of the command.

   Example:
      # Reboot the router
      $foo->run_command('ENABLE reload');


=item usergrep

Supply a username as an argument, and usergrep will return an array of ports on which that user was found (thus, an empty list if they weren't found). An undefined value is returned if no username was supplied. Internally, this does a run_command('show users') and processes the output.

   Example:
      @ports = $foo->usergrep('gregor');
      print "User gregor was found on ports @ports\n";


=item userkill

This does a usergrep, but with a twist: it disconnects the user by resetting the modem on which they're connected. Like usergrep, it returns an array of ports to which the user was connected before they were reset (or an empty list if they weren't found). The undefined value is returned if no username is supplied.

   Examples:
      @foo = $foo->userkill('gregor');
      print "Gregor was on ports @foo - HA HA!\n" if @ports ;

      @duh = $foo->userkill('-');
      print "There were ", scalar(@duh), " ports open.\n";


=item portusage

This returns an array: The 1st element is the number of ports. The rest is a list of users who are currently online.

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


=item killexcessoutoctets

Takes a bytelimit as an argument and then checks each port's out-octets count. If the out octet count is higher than the bytelimit, the interface and its counters are reset. This is useful to stop RADIUS counters from wrapping, since a 32-bit signed integer wraps into negative at about 2 gig.

   Example:
      # kills users with outoctets of over about 2 gig
      $foo->killexcessoutoctets(2100000000);



=head1 EXAMPLE PROGRAMS

These are some examples of how you could use this module. Full-fledged applications based on the RAS:: family of modules will be made available at CPAN at the same place as this module. Also, check out the test.pl file included in this distribution for some sample code.

###

   portusage.pl - Prints a summary of port usage on a bank of modems

   use RAS::AS5200;
   $used = $total = 0;
   foreach ('dialup1.example.com','dialup2.example.com') {
      $foo = new RAS::AS5200(
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

   use RAS::AS5200;
   foreach ('dialup1.example.com','dialup2.example.com') {
      $foo = new RAS::AS5200(
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

   use RAS::AS5200;
   foreach ('dialup1.example.com','dialup2.example.com') {
      $foo = new RAS::AS5200(
         hostname => $_,
         login => '!root',
         password => 'mysecret'
      );

      @ports = $foo->userkill($username);
      (@ports) && print "$_ : Killed ports @ports\n";
   }


=head1 TRUNCATING USER NAMES

A "feature" of the Cisco AS5200 is that only the first 10 characters of login names are displayed. As such, doing a usergrep('johnjjschmidt') would never find the fellow, as the AS5200 truncates the username to 'johnjjschm'.

To work around this, you may set the "truncateusernames" flag in your constructor (see above). This will cause user-matching functions such as usergrep and userkill to internally truncate usernames to 10 characters for matching purposes. This means that usergrep('johnjjschmidt') would internally be treated as usergrep('johnjjschm') so that it would match.

So, you have your choice of two evils. If you don't enable username truncation, you'll miss users with login names over 10 characters in length. If you enable it, you could accidentally userkill user 'johnjjschm' when you meant to kill 'johnjjschmidt'. Sorry - Cisco screwed up and we get to suffer for it.


=head1 BUGS

The set of functions supplied is a bit bare but is growing. If you write a useful function, or if you need a specific function added, please let me know and I'd be glad to check it out on an in-my-free-time basis.

There are no known bugs. There are likely a lot of unexpected features, though. If you find any, PLEASE let me know.

This module has been tested with an AS5300 with some degree of success. Last I heard, the userports() function didn't work properly on the AS5300.


=head1 CHANGES IN THIS VERSION

1.04     Fixed some small typos.

1.03     Added the userports() and killexcessoutoctets() methods. Added better prompt support (YAY!). Made error messages more useful. Made the module work with or without a login prompt, as older IOS (11.2 specifically) doesn't require a login name, only a password.

1.02     Cleaned up the code substantially. Fixed a "bug" that truncated usernames at 8 characters. Added the "truncateusernames" option. Tested the userkill() function on ISDN clients - works.

1.01     Improved the error handling a tad. Touched up the docs.

1.00     First released version of RAS::AS5200.


=head1 AUTHORS, MAINTAINERS, AND CONTACT INFO

RAS::AS5200 uses the Net::Telnet module by Jay Rogers <jay@rgrs.com> - thank you, Jay!

Gregor Mosheh <stigmata@blackangel.net> wrote RAS::AS5200 and left some significant problems in it, especially the prompt handling.

Luke Robins <luker@vicnet.net.au> worked on the prompt handling and apprised me that later IOSes need different login/password procedures, and he also wrote the userports() and killexcessoutoctets() methods.

Todd Caine <todd_caine@eli.net> helped out substantially with the prompt handling, as well.

Thank you very much, Luke and Robin, for fixing the most annoying bugs in RAS::AS5200!

The maintainer of RAS::AS5200 is Gregor Mosheh, at the address above.


=head1 LICENSE AND WARRANTY

Where would we be if Larry Wall were tight-fisted with PERL itself? For God's sake, it's PERL code. It's free!

This software is hereby released into the Public Domain, where it may be freely distributed, modified, plagiarized, used, abused, and deleted without regard for the original author.

Bug reports and feature requests will be handled ASAP, but without guarantee. The warranty is the same as for most freeware:
   It Works For Me, Your Mileage May Vary.

=cut

