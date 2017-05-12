#!/usr/bin/perl -w

## This program is based on an example program for Qt. It
## may be used, distributed and modified without limitation.
##
## Copyright (C) 1992-2000 Trolltech AS.  All rights reserved.


# When a new client connects, the server constructs a Qt::Socket and all
# communication with the client is done over this Socket object. Qt::Socket
# works asynchronously - this means that all the communication is done
# through the two slots readClient() and discardClient().
 
package HttpDaemon;

use Qt;
use Qt::isa qw(Qt::ServerSocket);
use Qt::signals
    newConnect    => [],
    endConnect    => [],
    wroteToClient => [];
use Qt::slots
    readClient    => [],
    discardClient => [];
use Qt::attributes qw(
    sockets
);

sub NEW
{
    shift->SUPER::NEW(8080, 1, $_[0]);
    if( !this->ok() )
    {
       die "Failed to bind to port 8080\n";
    }
    sockets = {};
}    

sub newConnection
{
    my $s = Qt::Socket( this );
    this->connect( $s, SIGNAL 'readyRead()', this, SLOT 'readClient()' );
    this->connect( $s, SIGNAL 'delayedCloseFinished()', this, SLOT 'discardClient()' );
    $s->setSocket( shift );
    sockets->{ $s } = $s;
    emit newConnect();
}   

sub readClient
{
    # This slot is called when the client sent data to the server. The
    # server looks if it was a get request and sends a very simple HTML
    # document back.
    my $s = sender();
    if ( $s->canReadLine() )
    {
        my @tokens = split( /\s\s*/, $s->readLine() );
        if ( $tokens[0] eq "GET" )
        {
             my $string = "HTTP/1.0 200 Ok\n\rContent-Type: text/html; charset=\"utf-8\"\n\r".
                 "\n\r<h1>Nothing to see here</h1>\n";
             $s->writeBlock($string, length($string));
             $s->close();
             emit wroteToClient();
        }
    }
}

sub discardClient
{
    my $s = sender();
    sockets->{$s} = 0; 
    emit endConnect();
}

1;


# HttpInfo provides a simple graphical user interface to the server and shows
# the actions of the server.

package HttpInfo;

use Qt;
use Qt::isa qw(Qt::VBox);
use Qt::slots
    newConnect    => [],
    endConnect    => [],
    wroteToClient => [];
use Qt::attributes qw(
    httpd
    infoText
);

use HttpDaemon;

sub NEW
{
    shift->SUPER::NEW(@_);
    httpd = HttpDaemon( this );
    my $port = httpd->port();
    my $itext = "This is a small httpd example.\n".
                "You can connect with your\n".
                "web browser to port $port\n";
    my $lb = Label( $itext, this );
    $lb->setAlignment( &AlignHCenter );
    infoText = TextView( this );
    my $quit = PushButton( "quit" , this );
    this->connect( httpd, SIGNAL 'newConnect()', SLOT 'newConnect()' );
    this->connect( httpd, SIGNAL 'endConnect()', SLOT 'endConnect()' );
    this->connect( httpd, SIGNAL 'wroteToClient()', SLOT 'wroteToClient()' );
    this->connect( $quit, SIGNAL 'pressed()', Qt::app(), SLOT 'quit()' );
}

sub newConnect
{
    infoText->append( "New connection" );
}

sub endConnect
{
    infoText->append( "Connection closed\n\n" );
}

sub wroteToClient
{
    infoText->append( "Wrote to client" );
}

1;

package main;
use Qt;
use HttpInfo;

my $app = Qt::Application(\@ARGV);
my $info = HttpInfo;
$app->setMainWidget($info);
$info->show;
exit $app->exec;
