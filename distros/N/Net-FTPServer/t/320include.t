use strict;
use Test::More tests => 1;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

use Net::FTPServer::InMem::Server;

my $ok = 1;

{
  # Save old STDIN, STDOUT.
  local (*STDIN, *STDOUT);

  # By closing STDIN and STDOUT, we force the server to start up,
  # try to read a command, and then immediately exit. The run()
  # function returns, allowing us to examine the internal state of
  # the FTP server.
  open STDIN, "</dev/null";
  open STDOUT, ">>/dev/null";

  my $include1 = ".320include.t.1.$$";
  my $include2 = ".320include.t.2.$$";
  my $include3 = ".320include.t.3.$$";

  open CF, ">$include1" or die "$include1: $!";
  print CF <<EOT;
key: 1
EOT
  close CF;

  open CF, ">$include2" or die "$include2: $!";
  print CF <<EOT;
key: 2
<Include $include3>
EOT
  close CF;

  open CF, ">$include3" or die "$include3: $!";
  print CF <<EOT;
key: 3
inner key: inner value
EOT
  close CF;

  my $config = ".320include.t.$$";
  open CF, ">$config" or die "$config: $!";
  print CF <<EOT;
key: 0
outer key: outer value
<Include $include1>
<Include $include2>
EOT
  close CF;

  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', $config]);

  unlink $config;
  unlink $include1;
  unlink $include2;
  unlink $include3;

  $ok = 0
    unless $ftps->{_config_file} eq $config;

  my @multi = $ftps->config ("key");

  $ok = 0 unless @multi == 4;
  $ok = 0 unless $multi[0] eq "0";
  $ok = 0 unless $multi[1] eq "1";
  $ok = 0 unless $multi[2] eq "2";
  $ok = 0 unless $multi[3] eq "3";

  $ok = 0
    unless $ftps->config ("outer key") eq "outer value";

  $ok = 0
    unless $ftps->config ("inner key") eq "inner value";
}

# Old STDIN, STDOUT now restored.
ok ($ok);

__END__
