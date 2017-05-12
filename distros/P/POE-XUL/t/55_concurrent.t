#!/usr/bin/perl
# $Id: 55_concurrent.t 1023 2008-05-24 03:10:20Z fil $

use strict;
use warnings;

use JSON::XS;
use POE;
use Test::More 'no_plan';
use t::Client;
use t::PreReq;

use constant DEBUG=>0;

my $Q = 5;
$Q *= 3 if $ENV{AUTOMATED_TESTING};
my $N = 10;

t::PreReq::load( $N, qw( POE::Component::Client::HTTP 
                          HTTP::Request POE::Wheel::Run ) );

if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $Q *= 3;
}

###############################################################
POE::Component::Client::HTTP->spawn(
           Agent     => $0,
           Alias     => 'ua',                  # defaults to 'weeble'
           Timeout   => 60,                    # defaults to 180 seconds
           MaxSize   => 16384,                 # defaults to entire response
           FollowRedirects => 2                # defaults to 0 (off)
    );

my @UA;
foreach my $n ( 1..$N ) {
    push @UA, My::Client->spawn( $n );
}

My::Server->spawn( $UA[0]{browser}{PORT} );

diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;

$poe_kernel->run;

DEBUG and diag( 'exit' );

##############################################################################
package My::Client;

use POE;
use strict;
use warnings;

my $ALIVE;
BEGIN {
    *is = \&main::is;
    *ok = \&main::ok;
    *diag = \&main::diag;
    *is_deeply = \&main::is_deeply;
    *DEBUG = \&main::DEBUG;
    $ALIVE = 0;
}


###########################################################
sub spawn
{
    my( $package, $n ) = @_;

    my $self = bless { N=>$n }, $package;
    $self->{browser} = t::Client->new();

    $self->{todo} = [ qw( boot B1 B2 done ) ];

    POE::Session->create(
            object_states => [
                $self => [ qw( _start do_next response done
                                boot boot_back B1 B1_back B2 B2_back ) ]
            ]
        );
    return $self;
}

###########################################################
sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $ALIVE++;
    $self->{alias} = "Client $self->{N}";

    $kernel->alias_set( $self->{alias} );
    $kernel->yield( 'do_next' );
}

###########################################################
sub do_next
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    my $todo = shift @{ $self->{todo} };
    if( $todo ) {
        DEBUG and diag( "$self->{alias} $todo" );
        $self->{doing} = $todo;
        $kernel->yield( $todo );
    }
}

###########################################################
sub boot
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    my $URI = $self->{browser}->boot_uri;
    my $req = HTTP::Request->new( GET => $URI );
    $kernel->post( ua=>'request', 'response', $req );
}

###########################################################
sub boot_back
{
    my( $self, $kernel, $data ) = @_[ OBJECT, KERNEL, ARG0 ];

    $self->{browser}->check_boot( $data );    
    $self->{browser}->handle_resp( $data, $self->{doing} );

    ok( $self->{browser}->{W}, "Got a window" );
    is( $self->{browser}->{W}->{tag}, 'window', " ... yep" );
    ok( $self->{browser}->{W}->{id}, " ... yep" );

    my $D = $self->{browser}->{W}->{zC}[0]{zC}[0]{zC}[0];
    is( $D->{tag}, 'textnode', "Found a textnode" );
    is( $D->{nodeValue}, 'do the following', " ... that's telling me what to do" );
    $self->{D} = $D;

    $kernel->yield( 'do_next' );
}


############################################################
sub B1
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    my $B1 = $self->{browser}->{W}->{zC}[0]{zC}[1];
    is( $B1->{tag}, 'button', "Found a button" );
    $self->{B1} = $B1;

    my $URI = $self->{browser}->Click_uri( $self->{B1} );
    my $req = HTTP::Request->new( GET => $URI );
    $kernel->post( ua=>'request', 'response', $req );
}

sub B1_back
{
    my( $self, $kernel, $data ) = @_[ OBJECT, KERNEL, ARG0 ];

    $self->{browser}->handle_resp( $data, $self->{doing} );

    my $D = $self->{browser}->{W}->{zC}[0]{zC}[0]{zC}[0];
    is( $self->{D}->{nodeValue}, 'You did it!', "$self->{alias} B1 worked!" );
    is( $D->{nodeValue}, 'You did it!', "$self->{alias} B1 worked!" );
    $kernel->yield( 'do_next' );
}

############################################################
sub B2
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    my $B2 = $self->{browser}->{W}->{zC}[0]{zC}[2];
    is( $B2->{tag}, 'button', "$self->{alias} found another button" ) or die "Can't find button B2";
    $self->{B2} = $B2;

    my $URI = $self->{browser}->Click_uri( $self->{B2} );
    my $req = HTTP::Request->new( GET => $URI );
    $kernel->post( ua=>'request', 'response', $req );
}

sub B2_back
{
    my( $self, $kernel, $data ) = @_[ OBJECT, KERNEL, ARG0 ];

    $self->{browser}->handle_resp( $data, $self->{doing} );

    is( $self->{D}->{nodeValue}, 'Thank you', "The button is polite" );
    $kernel->yield( 'do_next' );
}


############################################################
sub done
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_remove( $self->{alias} );
    $ALIVE--;
    unless( $ALIVE ) {
        DEBUG and diag( "All done" );
        $kernel->post( server => 'shutdown' );
    }
}

############################################################
sub response
{
    my( $self, $kernel, $request_packet, $response_packet) = 
                @_[ OBJECT, KERNEL, ARG0, ARG1];

    my $req  = $request_packet->[0];
    my $resp = $response_packet->[0];

    DEBUG and diag( "$self->{alias} $self->{doing} response" );
    my $data = $self->{browser}->decode_resp( $resp, $self->{doing} );
    $kernel->yield( "$self->{doing}_back", $data );
}


##########################################################################
package My::Server;

use strict;
use Config;
use POE;

our $perl;

BEGIN {
    *DEBUG = \&main::DEBUG;
    *diag  = \&main::diag;
    $perl = $^X || $Config{perl5} || $Config{perlpath};

    if( $ENV{HARNESS_PERL_SWITCHES} ) {
        $perl .= " $ENV{HARNESS_PERL_SWITCHES}";
    }
}

sub spawn
{
    my( $package, $port ) = @_;

    die "I need a port" unless $port;
    my $self = bless { port=>$port }, $package;

    POE::Session->create(
            object_states => [
                $self => [ qw( _start stdout stderr shutdown error close 
                                child ) ]
            ]
        );
}

sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];    

    $self->{alias} = 'server';
    $kernel->alias_set( $self->{alias} );

    $ENV{PERL5LIB} = join ':', qw( blib/lib
                                   ../widgets/blib/lib
                                   ../httpd/blib/lib
                                   ../PRO5/blib/lib
                                 ), @INC;
    my $prog = "$perl t/test-app.pl $self->{port} t-tmp";
    # diag "POE=$INC{'POE.pm'}";
    # diag "prog=$prog";
    $self->{wheel} = POE::Wheel::Run->new( 
            Program    => $prog,
            ErrorEvent => 'error',
#            CloseEvent => 'close'
            StdoutEvent => 'stdout',
            StderrEvent => 'stderr',
        );
    $self->{wheel}->shutdown_stdin;
    $poe_kernel->sig_child( $self->{wheel}->PID, 'child' );

}

sub shutdown 
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    DEBUG and diag( "$self->{alias} shutdown" );
    $kernel->alias_remove( $self->{alias} );

    $self->{wheel}->kill;
}

sub stdout
{
    my( $self, $kernel, $text ) = @_[ OBJECT, KERNEL, ARG0 ];
    DEBUG and diag( "STDOUT $text" );
}

sub stderr
{
    my( $self, $kernel, $text ) = @_[ OBJECT, KERNEL, ARG0 ];
    # we need this to see if the prog didn't start
    # DEBUG and 
        diag( "STDERR $text" ); 
}

sub error
{
    my( $self, $kernel, $errret, $errno, $errstr, $wid, $handle ) 
            = @_[ OBJECT, KERNEL, ARG0..ARG4 ];
    return unless $errno;
    DEBUG and warn "Error $errno ($errstr) on $handle";
}

sub close
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    DEBUG and warn "Close";
}

sub child 
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    DEBUG and warn "Child exited";
}
