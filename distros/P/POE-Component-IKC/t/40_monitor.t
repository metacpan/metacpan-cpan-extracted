#!/usr/bin/perl

use strict;
use warnings;

use Symbol;

use Test::More;
plan skip_all => 'This test fails on Win32' if $^O eq 'MSWin32';


plan tests => 22;

sub DEBUG () { 0 }

use POE;

use POE::Component::IKC::Server;
use POE::Component::IKC::Client;
use POE::Component::IKC::Responder;

###########
# Get a "random" port number
use IO::Socket::INET;
my $sock = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1 );
our $PORT = $sock->sockport;
undef( $sock );

##########################################################################
POE::Component::IKC::Responder->spawn;

my %tests = (
    '_start' => 0,
    'Client started' => 0,
    'Registered Child' => 0,
    'Client registered server' => 0,
    'Client tried to talk to unknown kernel' => 0,
    'Client attempted bad subscription' => 0,
    'Client registered server' => 0,
    'Got a request' => 0,
    'Client posted an unpublished event' => 0,
    'Server refused subscription' => 0,
    'Client got remote-check error' => 0,
    'Client got our answer' => 0,
    'Client disconnect' => 0,
    'Unregistered Child' => 0,
    'Client is done' => 0,
    'Child exited' => 0,
    '_stop' => 0,
    'Client subscribed to server' => 0,
    'Channel close' => 0,
    'Channel ready' => 0
);


my $child = gensym;
my $pid = open( $child, "-|" );
die "Unable to fork: $pid" unless defined $pid;

if( $pid ) {    # parent
    Test::Parent->spawn( $child, $pid, \%tests );
}
else {
    sleep 1;
    Test::Child->spawn;
}


pass( "Running" ) if $pid;
$poe_kernel->run;
exit 0 unless $pid;


pass( "Sane exit" );

foreach my $test ( keys %tests ) {
    next if $tests{ $test } == 1;
    next if $tests{ $test } == 2;
    fail( "Never saw $test ($tests{$test})" );
}


##########################################################################
package Test::Parent;

use strict;
use warnings;

use POE;
use POE::Wheel::ReadWrite;

use Data::Dump qw( pp );

sub DEBUG () { ::DEBUG }


sub pass
{
    my( $self, $test ) = @_;
    die "Unknown test '$test'" unless exists $self->{tests}{ $test };
    $self->{tests}{ $test } ++;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::pass( $test );
    return 1;
}

sub fail
{
    my( $self, $test ) = @_;
    die "Unknown test '$test'" unless exists $self->{tests}{ $test };
    $self->{tests}{ $test } ++;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::fail( $test );
    return 0;
}

sub is
{
    my( $self, $is, $want, $test ) = @_;
    $self->ok( $is eq $want, $test )
        or Test::More::diag( "  want: '$want'\n   got: '$is'" );
}

sub like
{
    my( $self, $is, $re, $test ) = @_;
    $self->ok( scalar ($is =~ /$re/), $test )
        or Test::More::diag( "  want: $re\n   got: '$is'" );
}

sub ok
{
    my( $self, $ok, $test ) = @_;
    if( $ok ) {
        $self->pass( $test );
        return 1;
    }
    else {
        $self->fail( $test );
        return 0;
    }
}

sub spawn
{
    my( $package, $child, $pid, $tests ) = @_;
    my $self = bless { child => $child,
                       pid => $pid,
                       tests => $tests }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start _stop register unregister 
                                child_error parent_error channel
                                req child
                                sig_CHLD
                             ) ]
            ] );


    POE::Component::IKC::Server->spawn( ip => '127.0.0.1',
                                        port => $::PORT,
                                        name => 'Parent',
                                        on_error => sub { $self->on_error( @_ ) }
                                      );
                            
}

######################################
sub _start
{
    my( $self ) = @_;
    
    $self->pass( "_start" );
    $poe_kernel->alias_set( 'parent' );
    $poe_kernel->post( IKC => monitor => Child => 
                                {   register => 'register',
                                    unregister => 'unregister',
                                    error => 'child_error',
                                } );
    $self->{wheel} = POE::Wheel::ReadWrite->new(
                                        Handle => $self->{child},
                                        InputEvent  => 'child'
                                    );
    $poe_kernel->post( IKC => publish => parent => [ qw( req ) ] );
    $poe_kernel->post( IKC => monitor => '*' => 
                                {   channel => 'channel',
                                } );

    $poe_kernel->post( IKC => monitor => Parent => 
                                {   error => 'parent_error',
                                } );
    $poe_kernel->sig_child( $self->{pid}, 'sig_CHLD' );
}

######################################
sub _stop
{
    my( $self ) = @_;
    $self->pass( "_stop" );
}

######################################
sub register
{
    my( $self, $rid, $kernel, $real ) = @_[ OBJECT, ARG0..$#_ ];
    
    $self->is( $kernel, 'Child', "Registered Child" );
}

######################################
sub unregister
{
    my( $self, $rid, $kernel, $real ) = @_[ OBJECT, ARG0..$#_ ];
    $self->is( $kernel, 'Child', "Unregistered Child" );
    $poe_kernel->post( IKC => 'shutdown' );
}

######################################
sub child_error
{
    my( $self, $rid, $kernel, $real, $data, $op, $msg ) = @_[ OBJECT, ARG0..$#_ ];
    if( $op eq 'channel-read' ) {
        $self->like( $msg, qr/\[(0|104)\] /, "Client disconnect" );
    }
    else {
        die "$op $msg";
    }
}

######################################
sub parent_error
{
    my( $self, $rid, $kernel, $real, $data, $op, $msg ) = @_[ OBJECT, ARG0..$#_ ];
    if( $op eq 'local-check' ) {
        $self->like( $msg, qr"poe://Parent/not/there", "Client posted an unpublished event" );
    }
    else {
        die "$op $msg";
    }
}

######################################
sub child
{
    my( $self, $line, $wid ) = @_[ OBJECT, ARG0..$#_ ];

    if( $line =~ /child: _start/ ) {
        $self->pass( "Client started" );
    }
    elsif( $line =~ /child: register/ ) {
        $self->like( $line, qr/Parent/, "Client registered server" );
    }
    elsif( $line =~ /child: resolve/ ) {
        $self->like( $line, qr/Unknown kernel 'Unknown'/, "Client tried to talk to unknown kernel" );
    }
    elsif( $line =~ /child: subscribe/ ) {
        if( $line =~ /Unknown/ ) {
            $self->like( $line, qr/Unknown kernel Unknown/, "Client attempted bad subscription" );
        }
        elsif( $line =~ /Refused/ ) {
            $self->like( $line, qr/Refused subscription/, "Server refused subscription" );
        }
        else {
            $self->like( $line, qr/kernel => .Parent./, "Client subscribed to server" );
        }
    }
    elsif( $line =~ /child: remote-check Session 'not'/ ) {
        $self->pass( "Client got remote-check error" );
    }
    elsif( $line =~ /child: answer 17/ ) {
        $self->pass( "Client got our answer" );
    }
    elsif( $line =~ /child: _stop/ ) {
        $self->pass( "Client is done" );
    }
    else {
        Test::More::diag( $line );
    }
}

######################################
sub sig_CHLD
{
    my( $self ) = @_;
    $self->pass( "Child exited" );
    delete $self->{wheel};
}

######################################
sub req
{
    my( $self, $args ) = @_[ OBJECT, ARG0..$#_ ];
    $self->ok( $args->{resp}, "Got a request" );
    DEBUG and Test::More::diag( pp $args );
    $poe_kernel->post( IKC => post => $args->{resp}, 17 );
}

######################################
sub on_error
{
    my( $self, $op, $errnum, $errstr ) = @_;
    die "$op: $errnum $errstr";
}


######################################
sub channel
{
    my( $self, $rid, $kernel, $real, $data, $op, $channel ) = @_[ OBJECT, ARG0..$#_ ];
    return unless $real;
    # $channel is a session ID
    $self->like( $channel, qr/^\d+/, "Channel $op" );
}

##########################################################################
package Test::Child;

use strict;
use warnings;

use POE;
use POE::Wheel::ReadWrite;

sub DEBUG () { ::DEBUG }

use Data::Dump qw( pp );

sub spawn
{
    my( $package ) = @_;
    $|++;
    my $self = bless { }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start _stop register unregister error subscribe
                                resp
                             ) ]
            ] );

    POE::Component::IKC::Client->spawn( ip => '127.0.0.1',
                                        port => $::PORT,
                                        name => 'Child',
                                        on_error => sub { $self->on_error( @_ ) }
                                      );
                            
}

######################################
sub _start
{
    my( $self ) = @_;
    print "child: _start $$\n";
    $poe_kernel->alias_set( 'child' );
    $poe_kernel->post( IKC => monitor => Parent => 
                                {   register => 'register',
                                    unregister => 'unregister',
                                    subscribe => 'subscribe',
                                    error => 'error',
                                } );
    $poe_kernel->post( IKC => monitor => '*' => 
                                {
                                    error => 'error',
                                } );
    $poe_kernel->post( IKC => publish => child => [ qw( resp ) ] );
}

######################################
sub _stop
{
    my( $self ) = @_;
    print "child: _stop\n";
}

######################################
sub register
{
    my( $self, $rid, $kernel, $real ) = @_[ OBJECT, ARG0..$#_ ];
    print "child: register $kernel\n";
    $poe_kernel->call( IKC => subscribe => [ "poe://Parent/parent",
                                             "poe://Parent/unknown",
                                             "poe://Unknown/unknown"
                                         ] );
}

######################################
sub unregister
{
    my( $self, $rid, $kernel, $real ) = @_;
    print "child: unregister $kernel\n";
    $poe_kernel->alias_remove( 'child' );
}

######################################
sub error
{
    my( $self, $rid, $kernel, $real, $data, $op, $msg ) = @_[ OBJECT, ARG0..$#_ ];
    die "$op has newline" if $msg =~ /\n$/;
    # warn "$$: $op $msg for rid=$rid kernel=$kernel";
    print "child: $op $msg\n";
}


######################################
sub subscribe
{
    my( $self, $rid, $kernel, $real, $data, $what ) = @_[ OBJECT, ARG0 .. $#_ ];
    print "child: subscribe ", pp( $what ), "\n";
    # send a bad request
    $poe_kernel->post( IKC => 'post', 
                        'poe://Parent/not/there', 
                        { resp => 'poe://Child/child/resp' } );
    # send a good request
    $poe_kernel->post( 'poe://Parent/parent', req => 
                       { resp => 'poe://Child/child/resp' } );
}

######################################
sub resp
{
    my( $self, $answer ) = @_[ OBJECT, ARG0 .. $#_ ];
    print "child: answer $answer\n";
    $poe_kernel->post( IKC => 'shutdown' );
}

######################################
sub on_error
{
    my( $self, $op, $errnum, $errstr ) = @_;
    die "$op: $errnum $errstr";
}
