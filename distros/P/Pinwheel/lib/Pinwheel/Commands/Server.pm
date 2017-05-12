package Pinwheel::Commands::Server;

use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Request;
use HTTP::Status;
use HTML::Entities;
use URI::Escape;
use Getopt::Std;

use Pinwheel;
use Pinwheel::Controller;

# Force Hot output
$|=1;

# Get the command-line options
my %opts = ();
getopt('p:b:', \%opts);
my $HTTP_Host = $opts{'b'} || '0.0.0.0';
my $HTTP_Port = $opts{'p'} || 7000;
my $HTTP_Queue = 5;

print "=> Booting HTTP::Daemon $HTTP::Daemon::VERSION\n";
print "=> Pinwheel $Pinwheel::VERSION application starting on http://$HTTP_Host:$HTTP_Port\n";
print "=> Application root: $Config::Pinwheel::Root\n";
print "=> Template directory: $Pinwheel::Controller::templates_root\n";
print "=> Static root directory: $Pinwheel::Controller::static_root\n";
print "=> Ctrl-C to shutdown server\n";


# Create the HTTP Daemon
my $d = HTTP::Daemon->new(
    LocalAddr=>$HTTP_Host,  # Address to listen on
    LocalPort=>$HTTP_Port,  # Port to listen on
    Listen=>$HTTP_Queue,    # Queue size
    Reuse=>1 ) || die;

while (my $c = $d->accept) {
    my $r = $c->get_request;

    print localtime().": Handling request from ".$c->peerhost." for ".$r->url."\n";

    # Check for a static file first
    my $static_filepath = $Pinwheel::Controller::static_root . $r->url->path;
    if (-f $static_filepath) {
      
        # Static file exists - send them that
        $c->send_file_response( $static_filepath );
        
    } else {
      
        # Dispatch the request to Pinwheel
        my ($headers, $content) = Pinwheel::Controller::dispatch({
            method => $r->method,
            host => $r->header('host'),
            path => $r->url->path,
            base => '',   # FIXME: what belongs here?
            query => $r->url->query,
            accepts => $r->header('accept'),
            time => time(),
        });
  
        # Create HTTP response object
        my $response = HTTP::Response->new( $headers->{'status'}->[1] );
        $response->content( $content );
        for my $header (values %$headers) {
            my ($key, $value) = @$header;
            $response->header( $key => $value );
        }
        $c->send_response( $response );
         
        # Finish any prepared database requests
        Pinwheel::Database::finish_all();
   }

    # Close the client connection
    $c->close;
    undef($c);
}

$d->close();

1;
