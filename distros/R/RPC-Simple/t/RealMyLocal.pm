# -*- cperl -*-
package t::RealMyLocal ;

# This class is used on the remote RPC server and inherits from
# RPC::Simple::AnyRemote

use strict ;
use warnings ;

use vars qw($VERSION @ISA @RPC_SUB) ;
@ISA = qw(RPC::Simple::AnyRemote);
# Define a list of our callbacks.
@RPC_SUB = qw(implicitAnswer answer) ;

# Class implementation follows, notice we don't define a new
# method.  The new method is implemented in RPC::Simple::AnyRemote.

sub close 
  {
    my $self = shift ;
    print "close called on ",ref($self),"\n";
  }

sub remoteHello
  {
    my $self=shift ;
    print "Remote said 'Hello world'\n";
  }

sub remoteAsk
  {
    my $self=shift ;
    #my $param = shift ;
    my %args = @_;
    my $callback = $args{callback} || undef;

    print "Local asked me to say hello\n";

    unless (defined $callback)
      {
        # direct call to a local method
        $self->implicitAnswer("Hello local object");
        return ;
      }

    # Rather than a code ref, we are expecting our callback
    # to be a string containing the callback method name.
    # This will get dispatched back to the local object, that
    # made the call to remoteAsk().
    $self->$callback("Hello local object");
  }

sub DESTROY
  {
    my $self = shift ;
    print "Remote object is destroyed\n";
  }
1;
