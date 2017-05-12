# Before `make install' is performed this script should be runnable with 
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use strict;
use Net::PDSH;
use Data::Dumper;
my $loaded = 1;
my $val;
my $pdsh = Net::PDSH->new;
use vars qw( @pdsh_options ) ;
@pdsh_options = ("-R", "exec");
$pdsh->pdsh("localhost", "/bin/ls");
my @cat = ("/bin/cat", "/tmp/lfsck.log", "/etc/hosts", );
my @cmd_arr = (
  { "hostname" => "127.0.0.1,127.0.0.1",
    "command" =>  ["/bin/cat", "/tmp/lfsck.log", "/etc/hosts", ],
  },
  { "hostname" => "127.0.0.1",
    "command" =>  ["/bin/cat", "/etc/sysconfig/network",],
  },
);
# $pdsh->set_remote_command("ssh");
$pdsh->set_credentials("build");
# $pdsh->set_connect_timeout(5);
$pdsh->set_command_timeout(5);
# optional pdsh_options that can be given manually.
my %pids = $pdsh->cmd(@cmd_arr);
foreach ($val, keys %pids) {
  print "Output:".$pids{$_}."\n";
}
my %options = $pdsh->list_options("localhost");
print Dumper(\%options);
my %options = $pdsh->list_modules("localhost");
print Dumper(\%options);


print "ok 1\n";

