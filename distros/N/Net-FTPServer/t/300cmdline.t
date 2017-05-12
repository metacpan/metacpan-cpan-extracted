#!/usr/bin/perl -w

# $Id: 300cmdline.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

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

  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d',
      '-p', '1234',
      '-C', '/dev/null']);

  # Verify some basic internal state derived from the command line.
  $ok = 0
    unless defined $ftps->config ("port") && $ftps->config ("port") == 1234;

  $ok = 0
    if defined $ftps->config ("pidfile");

  $ok = 0
    if $ftps->config ("daemon mode");

  $ok = 0
    if $ftps->config ("run in background");

  $ok = 0
    unless $ftps->{_config_file} eq "/dev/null";

  # Command line overrides settings in the configuration file.
  my $config = ".300cmdline.t.$$";
  open CF, ">$config" or die "$config: $!";
  print CF <<EOT;
port: 4321
key: config file value
EOT
  close CF;

  $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d',
      '-p', '1234',
      '-o', 'key=command line value',
      '-C', $config]);

  $ok = 0
    unless $ftps->{_config_file} eq $config;

  $ok = 0
    unless defined $ftps->config ("port") && $ftps->config ("port") == 1234;

  $ok = 0
    unless defined $ftps->config ("key") &&
           $ftps->config ("key") eq "command line value";

  unlink $config;

  # Command line "-o" allows you to simulate new configuration file values.
  $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d',
      '-o', 'new key=command line value',
      '-C', "/dev/null"]);

  $ok = 0
    unless defined $ftps->config ("new key") &&
           $ftps->config ("new key") eq "command line value";
}

# Old STDIN, STDOUT now restored.
ok ($ok);
