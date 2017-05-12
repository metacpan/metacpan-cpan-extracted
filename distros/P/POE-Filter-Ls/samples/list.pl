#!/usr/bin/perl -w 

# Usage:
# list.pl host:user:pass
#

# sub POE::Component::Client::FTP::DEBUG         () { 1 };
# sub POE::Kernel::TRACE_EVENTS () { 1 }

use strict;
use POE;
use POE::Component::Client::FTP;
use POE::Filter::Ls;
use Data::Dumper;

$|++;

my ($conn, $file) = @ARGV;
my ($host,$user,$pass) = split /:/, $conn;

POE::Session->create
  (
   inline_states => {
		     _start        => \&start,
		     authenticated => \&authenticated,
		     login_error   => \&login_error,
		     ls_data       => \&ls_data,
		     ls_done       => \&ls_done
		    }
  );

sub start {
  my $ftp = POE::Component::Client::FTP->spawn
    (
     Alias      => 'ftp',
     RemoteAddr => $host,
     Username   => "wrong",
     Password   => "wrong",

     ConnectionMode => FTP_PASSIVE,
     Filters => { ls => new POE::Filter::Ls },
     Events => [qw(all)]
    );
}

sub authenticated {
  $poe_kernel->post('ftp', 'type', 'I');
  $poe_kernel->post('ftp', 'ls');
}

sub login_error {
  print "Error logging in: '$_[ARG0]' '$_[ARG1]'\n";
  $poe_kernel->post('ftp', 'login', $user, $pass);
}

sub ls_data {
  print Dumper $_[ARG0];
}

sub ls_done {
  $poe_kernel->post('ftp', 'quit');
}

$poe_kernel->run();
