#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

package POE::Component::Example;

use lib '../lib';

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( get_time => '_wheel_entry' );
}

sub get_time {
    $poe_kernel->post( shift->{session_id} => get_time => @_ );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    # of course, here you'd normally do your blocking stuff
    $in_ref->{time} = localtime() . $self->{some_arg};
}


package main;

use POE;
my $poco = POE::Component::Example->spawn( some_arg => ' RIGHT NOW!' );

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->get_time({ event => 'results' });
}

sub results {
    print "Current time is: $_[ARG0]->{time}\n";
    $poco->shutdown;
}

