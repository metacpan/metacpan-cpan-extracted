#!/usr/bin/perl -w


# sub POE::Kernel::TRACE_SESSIONS () { 1 }

use strict;
use Test::More tests => 47;

use FindBin;
use lib "$FindBin::Bin/..";

my $ok;
BEGIN {
    eval {
        $SIG{__DIE__} = 'DEFAULT';
        require HTTP::Status;
        require POE;
        require POE::Component::Server::SimpleHTTP;
        require POE::Component::Server::HTTP::KeepAlive::SimpleHTTP;
        require t::Client;
        $ok = 1 if $POE::Component::Server::SimpleHTTP::VERSION > 1.30;
    };
}

BEGIN {
    *RC_OK = \&HTTP::Status::RC_OK;

    *ARG0 = \&POE::Session::ARG0;
    *ARG1 = \&POE::Session::ARG1;
    *HEAP = \&POE::Session::HEAP;
}

unless( $ok ) {
    SKIP: {
        skip "Don't have necessary dependencies", 47;
    }
    exit 0;
}


use Data::Dumper;

my $PORT = 2080;

my $S = 5;
$S *= 3 if $ENV{AUTOMATED_TESTING};

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
        my $kid = waitpid( $pid, 0 );
        is( $?, 0, "Sane shutdown ($?)" );
    }
}

my $KA_MAX = 3;
my $aliases;
####################################################################
unless( $pid ) {                          # we are the child
    POE::Component::Server::SimpleHTTP->new(
        KEEPALIVE   => 1,
        ALIAS       => 'HTTPD',
        PORT        => $PORT,
        ADDRESS     => '127.0.0.1',
        HOSTNAME    => 'localhost',
        HEADERS     => { Server => 'TestServer' },
        HANDLERS    => [
                {   DIR     => '^/honk/', 
                    SESSION => 'HTTP_GET',
                    EVENT   => 'honk',
                },
                {   DIR     => '^/bonk/zip.html$', 
                    SESSION => 'HTTP_GET',
                    EVENT   => 'bonk2',
                },
                {   DIR     => '^/bonk/', 
                    SESSION => 'HTTP_GET',
                    EVENT   => 'bonk',
                },
                {   DIR     => '^/', 
                    SESSION => 'HTTP_GET',
                    EVENT   => 'top',
                },
            ]
    );

    POE::Session->create(
        inline_states => {
            '_start'    => \&_start,
            honk        => \&honk,
            bonk        => \&bonk,
            bonk2       => \&bonk2,
            bonk2_done  => \&bonk2_done,
            sig_INT     => \&sig_INT,
            top         => \&top,
            shutdown    => \&shutdown,
        },
    );

    $POE::Kernel::poe_kernel->run;
    exit 0;
}

my $ka;

#######################################
sub _start
{
    my( $heap ) = $_[ HEAP ];
    $heap->{ka} = POE::Component::Server::HTTP::KeepAlive::SimpleHTTP->new(
                    max       => $KA_MAX,
                    total_max => 2*$KA_MAX,
                    timeout   => $S,
                    http_alias => 'HTTPD',
                );
    $POE::Kernel::poe_kernel->alias_set( 'HTTP_GET' );
    $POE::Kernel::poe_kernel->sig( INT => 'sig_INT' );
}

#######################################
sub sig_INT
{
    diag "sig_INT";
    $POE::Kernel::poe_kernel->yield( 'shutdown' );
    $POE::Kernel::poe_kernel->sig_handled();
}

#######################################
sub shutdown
{
    $POE::Kernel::poe_kernel->alias_remove( 'HTTP_GET' );
    $POE::Kernel::poe_kernel->call( HTTPD => 'SHUTDOWN' );
}

#######################################
sub top
{
    my ($heap, $request, $response) = @_[ HEAP, ARG0, ARG1 ];
    $heap->{ka}->start( $request, $response );
    $response->header( 'X-CID' => $response->connection->ID );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is top");
    $response->content_length( length $response->content );
    $heap->{ka}->finish( $request, $response );
    $POE::Kernel::poe_kernel->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub honk
{
    my ($heap, $request, $response) = @_[ HEAP, ARG0, ARG1 ];
    $heap->{ka}->start( $request, $response );
    $response->header( 'X-CID' => $response->connection->ID );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is honk");
    $response->content_length( length $response->content );
    $heap->{ka}->finish( $request, $response );
    $POE::Kernel::poe_kernel->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub bonk
{
    my ($heap, $request, $response) = @_[ HEAP, ARG0, ARG1 ];
    $heap->{ka}->start( $request, $response );
    $response->header( 'X-CID' => $response->connection->ID );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is bonk");
    $heap->{ka}->finish( $request, $response );
    $POE::Kernel::poe_kernel->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub bonk2
{
    my ($heap, $request, $response) = @_[ HEAP, ARG0, ARG1 ];
    $heap->{ka}->start( $request, $response );
    $POE::Kernel::poe_kernel->delay( 'bonk2_done', 1, $request, $response );
}

sub bonk2_done
{
    my ($heap, $request, $response) = @_[ HEAP, ARG0, ARG1 ];
    $response->header( 'X-CID' => $response->connection->ID );
    $response->code(RC_OK);
    $response->content_type('text/html');
    $response->content(<<'    HTML');
<html>
<head><title>YEAH!</title></head>
<body><p>This, my friend, is the page you've been looking for.</p></body>
</html>
    HTML
    $heap->{ka}->finish( $request, $response );
    $POE::Kernel::poe_kernel->post( 'HTTPD', 'DONE', $response );
}

####################################################################
## we are parent

# stop kernel from griping
${$POE::Kernel::poe_kernel->[POE::Kernel::KR_RUN()]} |=
      POE::Kernel::KR_RUN_CALLED();

# use t::Client;

t::Client::tests( $PORT, $KA_MAX, $S );

