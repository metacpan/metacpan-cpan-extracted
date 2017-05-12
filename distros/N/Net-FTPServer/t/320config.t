#!/usr/bin/perl -w

# $Id: 320config.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 1;
}

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
key: config file value
 key 1: value 1
key  2 : value 2
 key   3 : value 3
multikey : a
 multikey: b
  multikey  : c
# comments: ignored
multiline: line 1 \
	line 2 \
	line 3
override: outer value
<Host dummyhost>
override: inner value
</Host>
EOT
  close CF;

  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', $config]);

  unlink $config;

  $ok = 0
    unless $ftps->{_config_file} eq $config;

  $ok = 0
    unless $ftps->config ("key") eq "config file value";

  $ok = 0
    unless $ftps->config ("key 1") eq "value 1";

  $ok = 0
    unless $ftps->config ("key  1") eq "value 1";

  $ok = 0
    unless $ftps->config ("key   1") eq "value 1";

  $ok = 0
    unless $ftps->config ("key 2") eq "value 2";

  $ok = 0
    unless $ftps->config ("key  2") eq "value 2";

  $ok = 0
    unless $ftps->config ("key   2") eq "value 2";

  $ok = 0
    unless $ftps->config ("key 3") eq "value 3";

  $ok = 0
    unless $ftps->config ("key  3") eq "value 3";

  $ok = 0
    unless $ftps->config ("key   3") eq "value 3";

  my @multi = sort $ftps->config ("multikey");

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

  $ok = 0
    if defined $ftps->config ("# comments");

  $ok = 0
    unless $ftps->config ("multiline") eq "line 1 line 2 line 3";
}

# Old STDIN, STDOUT now restored.
ok ($ok);
