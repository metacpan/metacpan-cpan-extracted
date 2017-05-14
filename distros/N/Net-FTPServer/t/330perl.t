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

  my $config = ".320config.t.$$";
  open CF, ">$config" or die "$config: $!";
  print CF <<'EOT';
before: before value
multivalued: a
override: outer value
<Perl>
$self->{version_string} = "new version string";
$config{single} = "single value";
$config{multivalued} = [ "b", "c" ];
$host_config{dummyhost}{override} = "inner value";
</Perl>
after: after value
EOT
  close CF;

  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', $config]);

  unlink $config;

  $ok = 0
    unless $ftps->{_config_file} eq $config;

  $ok = 0
    unless $ftps->config ("before") eq "before value";

  $ok = 0
    unless $ftps->config ("after") eq "after value";

  $ok = 0
    unless $ftps->{version_string} =~ m/new version string/;

  $ok = 0
    unless $ftps->config ("single") eq "single value";

  my @multi = sort $ftps->config ("multivalued");

  $ok = 0 unless @multi == 3;
  $ok = 0 unless $multi[0] eq "a";
  $ok = 0 unless $multi[1] eq "b";
  $ok = 0 unless $multi[2] eq "c";

  $ok = 0
    unless $ftps->config ("override") eq "outer value";

  {
    local ($ftps->{sitename}) = ("dummyhost");

    $ok = 0
      unless $ftps->config ("override") eq "inner value";
  }

  {
    local ($ftps->{sitename}) = ("anotherhost");

    $ok = 0
      unless $ftps->config ("override") eq "outer value";
  }
}

# Old STDIN, STDOUT now restored.
ok ($ok);

__END__
