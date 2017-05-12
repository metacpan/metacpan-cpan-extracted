#!/usr/bin/perl

use strict;
#sub POE::Kernel::TRACE_DEFAULT  () { 1 }
#sub POE::Kernel::TRACE_EVENTS   () { 1 }
#sub POE::Kernel::TRACE_GARBAGE  () { 1 }
#sub POE::Kernel::TRACE_PROFILE  () { 1 }
#sub POE::Kernel::TRACE_QUEUE    () { 1 }
#sub POE::Kernel::TRACE_REFCOUNT () { 1 }
#sub POE::Kernel::TRACE_RETURNS  () { 1 }
#sub POE::Kernel::TRACE_SELECT   () { 1 }
#sub POE::Kernel::TRACE_SIGNALS  () { 1 }
#sub POE::Component::Client::POP3::DEBUG () { 1 }
use Symbol qw(gensym);
use POE qw/Component::Client::POP3/;
use Data::Dumper;



sub handler_start {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];

    POE::Component::Client::POP3->spawn(
        Alias      => 'test',
        Username   => $ARGV[0],
        Password   => $ARGV[1],
        RemoteAddr => 'localhost',
        AuthMethod => 'PASS',
        Events => [{
            list          => 'pop_list',
            retr          => 'pop_message',
            authenticated => 'pop_auth',
            error         => 'pop_error',
            disconnected  => 'pop_disconnect'
        }]
    );
    $kernel->alias_set( 'me' );
}

sub handler_auth {
    my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];
    print "Got connected: $input\n";
    $kernel->post( 'test', 'list' );
}

sub handler_list {
    my ( $kernel, $list ) = @_[KERNEL, ARG0];

    print Dumper( $list ), "\n";
    for ( sort keys %$list ) {
        $kernel->post( 'test', 'retr', $_ );
    }
    for ( sort keys %$list ) {
        my $fh = gensym;
        open $fh, ">msg$_.eml" or die "Could not open test1.eml; Reason: $!";
        $kernel->post( 'test', 'retr', $_, $fh );
    }
    $kernel->post( 'test', 'quit' );
}

sub handler_message {
    my ( $kernel, $message, $num ) = @_[KERNEL, ARG0, ARG1];

    print "Got message number $num\n";
    print Dumper( $message ), "\n";
}

sub handler_error {
    my ( $kernel, @args ) = @_[KERNEL, ARG0 .. $#_];
    print "Error with: ", Dumper( \@args ), "\n";
}

sub handler_disconnect {
    my $kernel = $_[KERNEL];

    warn "Got disconnected";
}

sub handler_stop {
    my $kernel = $_[KERNEL];

    warn "In stop";
    $kernel->alias_remove( 'me' );
}

POE::Session->create(
    inline_states => {
        _start         => \&handler_start,
        _stop          => \&handler_stop,
        pop_list       => \&handler_list,
        pop_message    => \&handler_message,
        pop_error      => \&handler_error,
        pop_auth       => \&handler_auth,
        pop_disconnect => \&handler_disconnect
    }
);

$poe_kernel->run;


