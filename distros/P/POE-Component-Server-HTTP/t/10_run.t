#!/usr/bin/perl -w

use strict;
use Test::More tests => 6 * 2;

use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;
use POE::Kernel;
use POE::Component::Server::HTTP;
use YAML;

my $PORT = 2080;

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
    }
}

####################################################################
if ($pid) {                      # we are parent
    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

    print STDERR "$$: Sleep 2...";
    sleep 2;
    print STDERR "continue\n";

    my $UA = LWP::UserAgent->new;
  again:
    my $req=HTTP::Request->new(GET => "http://localhost:$PORT/");
    my $resp=$UA->request($req);

    ok($resp->is_success, "got index") or die "resp=", Dump $resp;
    my $content=$resp->content;
    ok($content =~ /this is top/, "got top index");

    $req=HTTP::Request->new(GET => "http://localhost:$PORT/honk/something.html");
    $resp=$UA->request($req);

    ok($resp->is_success, "got something");
    $content=$resp->content;
    ok($content =~ /this is honk/, "something honked");

    $req=HTTP::Request->new(GET => "http://localhost:$PORT/bonk/zip.html");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type eq 'text/html'),
       "get text/html");
    $content=$resp->content;
    ok($content =~ /my friend/, 'my friend');

    unless ($UA->conn_cache) {
        diag( "Enabling Keep-Alive and going again" );
        $UA->conn_cache( LWP::ConnCache->new() );
        goto again;
    }
}

####################################################################
else {                          # we are the child
  my $aliases = POE::Component::Server::HTTP->new(
     Port => $PORT,
     Address=>'localhost',
     MapOrder=>'bottom-first',
     ContentHandler => { '/' => \&top,
                         '/honk/' => \&honk,
                         '/bonk/' => \&bonk,
                         '/bonk/zip.html' => \&bonk2,
#                         '/shutdown.html' => \&shutdown
                       },
#     ErrorHandler => { '/' => \&error },
     Headers => { Server => 'TestServer' },
  );
  $poe_kernel->run;
}


#######################################
sub top
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is top");
    return RC_OK;
}

#######################################
sub honk
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is honk");
    return RC_OK;
}

#######################################
sub bonk
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is bonk");
    return RC_OK;
}

#######################################
sub bonk2
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/html');
    $response->content(<<'    HTML');
<html>
<head><title>YEAH!</title></head>
<body><p>This, my friend, is the page you've been looking for.</p></body>
</html>
    HTML
    return RC_OK;
}

