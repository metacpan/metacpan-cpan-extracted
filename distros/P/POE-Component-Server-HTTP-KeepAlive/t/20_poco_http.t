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
        require POE;
        require POE::Component::Server::HTTP;
        require POE::Component::Server::HTTP::KeepAlive;
        require t::Client;
        $ok = 1;
    };
}

BEGIN {

    *RC_OK = \&POE::Component::Server::HTTP::RC_OK;
    *RC_WAIT = \&POE::Component::Server::HTTP::RC_WAIT;

    *ARG0 = \&POE::Session::ARG0;
    *ARG1 = \&POE::Session::ARG1;
}

unless( $ok ) {
    SKIP: {
        skip "Don't have necessary dependencies", 47;
    }
    exit 0;
}


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
    $POE::Kernel::poe_kernel->has_forked if $POE::Kernel::poe_kernel->can( 'has_forked' );
    $aliases = POE::Component::Server::HTTP->new(
        Port => $PORT,
        Address=>'localhost',
        MapOrder=>'bottom-first',
        ContentHandler => { '/' => \&top,
                             '/honk/' => \&honk,
                             '/bonk/' => \&bonk,
                             '/bonk/zip.html' => \&bonk2,
#                             '/shutdown.html' => \&shutdown
                          },
#        ErrorHandler => { '/' => \&error },
        Headers => { Server => 'TestServer' },
    );

    $POE::Kernel::poe_kernel->run;
    exit 0;
}

my $ka;

#######################################
sub new_conn
{
    my( $req, $resp ) = @_;
    unless( $ka ) {         # insert some things into the session
        $ka = POE::Component::Server::HTTP::KeepAlive->new(
                    max       => $KA_MAX,
                    total_max => 2*$KA_MAX,
                    timeout   => $S,
                );
        die "Can't create keep-alive object" unless $ka;
        $POE::Kernel::poe_kernel->state( bonk2_done => \&bonk2_done );
        $POE::Kernel::poe_kernel->state( sig_INT => \&sig_INT );
#        $POE::Kernel::poe_kernel->state( shutdown => \&shutdown );
        $POE::Kernel::poe_kernel->sig( INT => 'sig_INT' );
    }

    $resp->header( 'X-CID' => $req->connection->ID );

    $ka->start( $req, $resp );
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
    POE::Component::Server::HTTP::shutdown( @_ );
}

#######################################
sub top
{
    my ($request, $response) = @_;
    new_conn( $request, $response );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is top");
    $response->content_length( length $response->content );
    $ka->finish( $request, $response );
    return RC_OK;
}

#######################################
sub honk
{
    my ($request, $response) = @_;
    new_conn( $request, $response );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is honk");
    $response->content_length( length $response->content );
    $ka->finish( $request, $response );
    return RC_OK;
}

#######################################
sub bonk
{
    my ($request, $response) = @_;
    new_conn( $request, $response );
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is bonk");
    $ka->finish( $request, $response );
    return RC_OK;
}

#######################################
sub bonk2
{
    my ($request, $response) = @_;
    new_conn( $request, $response );
    $POE::Kernel::poe_kernel->delay( 'bonk2_done', 1, $request, $response );
    return RC_WAIT;
}

sub bonk2_done
{
    my ($request, $response) = @_[ ARG0, ARG1 ];
    $response->code(RC_OK);
    $response->content_type('text/html');
    $response->content(<<'    HTML');
<html>
<head><title>YEAH!</title></head>
<body><p>This, my friend, is the page you've been looking for.</p></body>
</html>
    HTML
    $ka->finish( $request, $response );
    $response->continue;
    return RC_OK;
}

####################################################################
# we are parent

# stop kernel from griping
${$POE::Kernel::poe_kernel->[POE::Kernel::KR_RUN()]} |=
      POE::Kernel::KR_RUN_CALLED();

use t::Client;

t::Client::tests( $PORT, $KA_MAX, $S );

