# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { 
      $| = 1; 
      print "1..6\n";                    # 5 tests in total
      }
END {
       print "not ok 1\n" unless $loaded; # we couldn't create an object
    }
use NetServer::Generic;
use IO::Handle;

# first test; can we create a new NetServer::Generic?

my $dummy = new NetServer::Generic();
if (ref($dummy) =~ /NetServer::Generic/i) { 
    $loaded = 1; 
    print "ok 1\n";
}

# next tests: first, we fork.
# The parent spawns a new NetServer::Generic server. It prints whatever
# comes to it on $out (which is aliased to the original STDOUT).
# The child spawns a NetServer::Generic client() server, with a trigger
# that fires three times. It prints "ok .. $n" each time, and this is picked
# up by the parent (if successful).
#
# The parent prints ok .. 5 when it exits.
#
# Test meanings are:
#
# 1     we could create a NetServer::Generic
# 2 - 5 inclusive: the client repeatedly forked and sent these strings
#       to the server, which echoed them to STDOUT
#
# NOTE: as yet, no testing for the non-forking server is available.
#

my $port = 10101;
my $host = localhost;

no strict "vars";

$j = 1;

$out = *STDOUT;
select STDERR; $| = 1;
select STDOUT; $| = 1;
#select STDIN;

eval {
{
    if ($pid = fork) {
       # parent
       my ($foo) = new NetServer::Generic();
       $foo->port($port);
       $foo->hostname($host);
       #$foo->allowed([ "localhost"]);
       my $server = sub {
           my $self = shift;
           while (defined($tmp = <STDIN>)) {
               if ($tmp !~ /exit/) {
                   print $out "ok $tmp";
		   $val = $tmp; chomp $val;
               } else {
		   if ($val !~ /5/) {
                       exit;
		   } else {
                       $self->quit();
		   }
               }
           }
       };
       $foo->callback($server);
       $foo->mode(forking);
       $foo->run();
       exit;
    } elsif (defined $pid) {
       # child
       my ($foo) = new NetServer::Generic();
       $foo->port($port);
       $foo->hostname($host);
       my $client = sub {
           my $self = shift;
           print STDOUT "$j\nexit\n";
           exit 0;
       };
       $foo->callback($client);
       my $trigger = sub {
           $j++;
           return(($j > 5) ? 0 : 1 ); #make three connections
       };
       $foo->trigger($trigger);
       $foo->mode(client);
       $foo->run();
       exit;
    } elsif ($! =~ /no more processes/i) {
       print $out "not ok 1\n";
       print STDERR "Are you running a Win32 system? If so, this \n",
                    "test script will not and cannot work\n";
       exit 0;
    } else {
       die "Can't fork: $!\n";
       exit 0;
    }
}
}; # end eval

if ($@ ne '') {
   print "eval(): $@\n";
}

exit 0;
