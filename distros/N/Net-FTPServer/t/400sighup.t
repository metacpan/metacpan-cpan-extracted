use strict;
use Test::More tests => 4;
use FileHandle;
use IO::Socket;
use POSIX qw(SIGHUP SIGTERM WNOHANG);

# This test is quite involved because we are going to actually
# run a separate FTP server process, listening on some high-numbered
# local port (which we hope won't conflict). We're going to send
# it a SIGHUP, to force it to reload the configuration file, and
# then we'll query it to see if it really has done that.

# Choose a free ephemeral port to avoid possible
# conflicts with other local services.
"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
my $port = IO::Socket::INET->new(Listen => 8)->sockport;

# Where am I?  I need to unchdir "/" later.
my $here = `pwd`;
chomp $here;

my $config  = ".400sighup.t.$$.conf";
my $invoker = ".400sighup.t.$$.pl";

# Where is this perl?
my $perl = $^X;
if ($perl !~ m%^/%) {
  foreach my $path (split /:/, ($ENV{PATH} || "/usr/local/bin:/usr/bin:/bin")) {
    if (-x "$path/$^X") {
      $perl = "$path/$^X";
      last;
    }
  }
}

# Need to preserve @INC for invoker script
my $lib_pass = join(" ",@INC);

# Write $invoker script which loads $config
open CF, ">$invoker" or die "$invoker: $!";
print CF <<EOT;
#!$perl
use lib qw($lib_pass);
use Net::FTPServer::InMem::Server;
alarm(60); # Runaway servers are bad
*Net::FTPServer::InMem::Server::post_bind_hook = sub {
  chdir "$here";   # Go back to where I was
  kill "USR1", $$; # Tell daddy I'm ready
};
run Net::FTPServer::InMem::Server [qw(--test -s -C $config)];
exit;
EOT
close CF;
chmod(0755,$invoker);

# Write a configuration file. We're going to modify this later.
open CF, ">$config" or die "$config: $!";
print CF <<EOT;
port: $port
greeting type: full
<Perl>
\$self->{version_string} = "key string no. 1";
</Perl>
EOT
close CF;

my $listening = 0;

$SIG{USR1} = sub {
  $listening = 1;
};

# Start the external invoker script.
my $pid = fork ();
die unless defined $pid;
unless ($pid) {            # Child process (the server).
  exec("./$invoker") or die "exec: $!";
}

# We know the server is ready when $listening == 1
while (!$listening and kill 0, $pid) {
  # Server still starting up.
  sleep 1; #  *YAWN*  (Patience until it's ready.)
  waitpid($pid,WNOHANG);
}

my $sock;

"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
$sock = new IO::Socket::INET->new (PeerAddr => "localhost",
                                   PeerPort => $port,
                                   Proto => "tcp",
                                   Type => SOCK_STREAM,
                                   Reuse => 1)
  or die "connect: $!";

# Check the server greeting contains "key string no. 1" from the initial
# configuration file.
my $greeting = $sock->getline;

ok ($greeting =~ /key string no\. 1/);

undef $sock;

# Modify the configuration file.
open CF, ">$config" or die "$config: $!";
print CF <<EOT;
port: $port
greeting type: full
<Perl>
\$self->{version_string} = "the second key string";
</Perl>
EOT
close CF;

$listening = 0;

# Send SIGHUP to the server.
ok (kill SIGHUP, $pid);

# We know the server is ready when $listening == 1
while (!$listening and kill 0, $pid) {
  # Server still starting up.
  sleep 1; #  *YAWN*  (Patience until it's ready.)
  waitpid($pid,WNOHANG);
}

"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
$sock = new IO::Socket::INET->new (PeerAddr => "localhost",
                                   PeerPort => $port,
                                   Proto => "tcp",
                                   Type => SOCK_STREAM,
                                   Reuse => 1)
  or die "connect: $!";

# Check the server greeting contains "the second key string" from
# the new configuration file.
$greeting = $sock->getline;

ok ($greeting =~ /the second key string/);

undef $sock;

# Tell the server to shutdown gracefully.
ok (kill SIGTERM, $pid);

END {
  # Remove the temporary files.
  unlink $config, $invoker;
}

__END__
