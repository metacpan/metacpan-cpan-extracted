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

  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d',
      '-C', '/dev/null']);

  # Verify default state.
  $ok = 0
    if defined $ftps->config ("port") && $ftps->config ("port") == 1234;

  $ok = 0
    if defined $ftps->config ("pidfile");

  $ok = 0
    if $ftps->config ("daemon mode");

  $ok = 0
    if $ftps->config ("run in background");

  $ok = 0
    unless $ftps->{version_string} =~
      m(Net::FTPServer/$Net::FTPServer::VERSION-$Net::FTPServer::RELEASE);

  $ok = 0
    unless $ftps->{_max_clients} == 255;

  $ok = 0
    unless $ftps->{_passive} == 0;

  $ok = 0
    unless $ftps->{type} eq 'A';
  $ok = 0
    unless $ftps->{form} eq 'N';
  $ok = 0
    unless $ftps->{mode} eq 'S';
  $ok = 0
    unless $ftps->{stru} eq 'F';

  $ok = 0
    unless $ftps->{_checksum_method} eq "MD5";

  $ok = 0
    unless $ftps->{_idle_timeout} == $Net::FTPServer::_default_timeout;

  $ok = 0
    unless $ftps->{maintainer_email} eq "root\@$ftps->{hostname}";
}

# Old STDIN, STDOUT now restored.
ok ($ok);

__END__
