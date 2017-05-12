#!/usr/bin/perl -w

use strict;
use Net::HTTPServer;

my $server = new Net::HTTPServer();

$server->RegisterURL("/test/env",\&test_env);
$server->RegisterURL("/test/auth",\&test_auth);
$server->RegisterAuth("basic","/test/auth","Test Auth",\&auth);

if ( $server->Start() )
{
    $server->Process();
}
else
{
    print "Could not start the server.\n";
}


sub test_env
{
    my $req = shift;             # Net::HTTPServer::Request object
    my $res = $req->Response();  # Net::HTTPServer::Response object
    
    $res->Print("<html>\n");
    $res->Print("  <head>\n");
    $res->Print("    <title>This is a test</title>\n");
    $res->Print("  </head>\n");
    $res->Print("  <body>\n");
    $res->Print("    <pre>\n");
    
    foreach my $var (keys(%{$req->Env()}))
    {
        $res->Print("$var -> ".$req->Env($var)."\n");
    }
    
    $res->Print("    </pre>\n");
    $res->Print("  </body>\n");
    $res->Print("</html>\n");
    
    return $res;
}


sub auth
{
    my $url = shift;
    my $user = shift;

    if ($user eq "test")
    {
        return ("200","pass");
    }

    return ("401");
}


sub test_auth
{
    my $req = shift;             # Net::HTTPServer::Request object
    my $res = $req->Response();  # Net::HTTPServer::Response object
    
    $res->Print("<html>\n");
    $res->Print("  <head>\n");
    $res->Print("    <title>This is a test</title>\n");
    $res->Print("  </head>\n");
    $res->Print("  <body>\n");
    $res->Print("    This page required authentication.\n");
    $res->Print("  </body>\n");
    $res->Print("</html>\n");
    
    return $res;
}

