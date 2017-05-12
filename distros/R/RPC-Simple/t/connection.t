# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 5 ;
use ExtUtils::testlib ;
BEGIN { use_ok ('RPC::Simple')} ;
use ExtUtils::testlib ;

use strict;
use warnings;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MyLocal ;

# MyLocal inherits from RPC::Simple::AnyLocal and is used
# to dispatch all calls in the @RPC_SUB array to the remote
# object created with a call to createRemote().

use vars qw($VERSION @ISA @RPC_SUB $tempObj) ;
@ISA = qw(RPC::Simple::AnyLocal);

# We must define our remote methods here, if we do not then
# AnyLocall will not dispatch the method call to the remote
# RPC server.
@RPC_SUB = qw(close remoteHello remoteAsk);

sub new 
  {
    my $type = shift ;

    my $self = {} ;
    print "creating $type\n";
    my $remote =  shift ; 
    bless $self,$type ;

    # Essentially call MyRemote->new() on the remote RPC server
    $self->createRemote($remote,'t::RealMyLocal.pm') ;
    return $self ;
  }

# this routine is known by the remote class and is actually called by it
sub implicitAnswer
  {
    my $self = shift ;
    my $result = shift ;

    print "implicit answer is $result\n" ;
  }
  
# this routine is not knwon from the remote class and will be called only
# by the call-back mechanism.
sub answer
  {
    my $self = shift ;
    my $result = shift ;

    print "answer is $result\n" ;
  }


package main ;

use RPC::Simple::Server ;
use RPC::Simple::Factory ;

use IO::Socket ;
use IO::Select ;

my $arg = shift ;
my $clientPid ;

my $verbose = 0 ; # you may change this value to see RPC traffic

# Either spawn/fork and enter the mainLoop or go directly
# into the mainLoop
if (not defined $arg or $arg eq '-i')
  {
    my $pid = &spawn(undef,$verbose) ; # spawn server
  }
elsif ($arg eq '-s')
  {
    RPC::Simple::Server::mainLoop (undef,$verbose) ;
  }

ok(1,"server spawned") ;

# client part

# Create a connection to the RPC Server on localhost, use the
# remote_host argument for Factory->new() when connecting to
# a remote server.
my $factory = new RPC::Simple::Factory(verbose_ref => \$verbose) ;
ok($factory, "Factory created") ;

# Create the MyLocal object, which will connect to the RPC server
# and call new on the remote object.
my $local = new MyLocal($factory) ;
ok($local,"Local object created" ) ;

# Very simple, now we just execute the remoteAsk method on the
# remote object.
$local->remoteAsk(callback => 'answer');

my $selector = IO::Select->new();
$selector->add($factory->getSocket());

# Wait for a response from the remote call, and use readSock
# to execute the callback.
my ($toRead, undef, undef) = IO::Select->select($selector, undef, $selector, 10);

foreach my $fh (@$toRead)
{
    if($fh == $factory->getSocket())
    {
        $factory->readSock();
    }
}

ok(1);
exit;
