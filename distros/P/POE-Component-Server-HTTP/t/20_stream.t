#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

use LWP::UserAgent;
use HTTP::Request;
use POE::Kernel;
use POE::Component::Server::HTTP;
use YAML;

my $PORT = 2081;

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
    }
}

$|++;

####################################################################
if ($pid) {                      # we are parent

    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

    print STDERR "$$: Sleep 2...";
    sleep 2;
    print STDERR "continue\n";

    if(@ARGV) {
        print STDERR "Please connect to http://localhost:$PORT/ with your browser and make sure everything works\n";
        local @ARGV=();
        {} while <>;
    }

    my $UA = LWP::UserAgent->new;

    ##################################### welcome
    my $req=HTTP::Request->new(GET => "http://localhost:$PORT/");
    my $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type eq 'text/html'), 
                "got index") or die "resp=", Dump $resp;
    my $content = $resp->content;
    ok(($content =~ /multipart.txt/), "proper index") 
                            or die "resp=", Dump $content;
                
    ##################################### last.txt
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/last.txt");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type eq 'text/plain'), 
                "got last.txt") or die "resp=", Dump $resp;
    $content = $resp->content;
    ok(($content =~ /everything worked/), "everything worked") 
                            or die "resp=", Dump $content;
                
    ##################################### multipart.txt
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/multipart.txt");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type =~ m(^multipart/mixed)), 
                "got multipart.txt") or die "resp=", Dump $resp;
    $content = $resp->content;
    ok(($content =~ /everything worked/), "everything worked") 
                            or die "resp=", Dump $content;
                

    ##################################### last.gif
    my $last = File::Basename::dirname($0).'/last.gif';
    open LAST, $last or die "Unable to open $last: $!";
    {
        local $/;
        $last = <LAST>;
    }
    close LAST;

    ##################################### last.gif
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/last.gif");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type eq 'image/gif'), 
                "got last.gif") or die "resp=", Dump $resp;
    $content = $resp->content;
    ok(($content eq $last), "everything worked");
                
    ##################################### multipart.gif
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/multipart.gif");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type =~ m(^multipart/mixed)),
                "got multipart.txt") or die "resp=", Dump $resp;
    $content = $resp->content;
    $last = quotemeta $last;
    ok(($content =~ /$last/), "everything worked");
                
    ##################################### multipart.mixed
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/multipart.mixed");
    $resp=$UA->request($req);

    ok(($resp->is_success and $resp->content_type =~ m(^multipart/mixed)),
                "got multipart.mixed") or die "resp=", Dump $resp;
    $content = $resp->content;
    ok(($content =~ /Please wait/), "first part worked");
    ok(($content =~ /$last/), "last part worked");
}
####################################################################
else {                          # we are the child

    Worker->spawn(port => $PORT);
    $poe_kernel->run();
}

###########################################################
package Worker;

use HTTP::Status;
use POE::Kernel;
use POE::Component::Server::HTTP;
use POE;
use File::Basename;

sub DEBUG () { 0 }

sub spawn
{
    my($package, %parms)=@_;
    my $self = bless { dir => dirname($0), 
                       delay => 2,
                       stream_todo => []}, $package;

    POE::Component::Server::HTTP->new(
        Port => $parms{port},
        ContentHandler => {
            '/' => sub { $self->welcome(@_) },
            '/favicon.ico' => sub { $self->favicon(@_) },
            '/multipart.gif' => sub { $self->multipart(@_) },
            '/multipart.mixed' => sub { $self->multipart_mixed(@_) },
            '/last.gif' => sub { $self->last(@_) },
            '/multipart.txt' => sub { $self->multipart_txt(@_) },
            '/last.txt' => sub { $self->last_txt(@_) },
        },
        StreamHandler => sub { $self->stream_start(@_) }
    );

    POE::Session->create(
        inline_states => {
            _start     => sub {  $self->_start() },
            _stop      => sub {  DEBUG and warn "_stop\n" },
            wait_start => sub { $self->wait_start(@_[ARG0..$#_])},
            wait_done  => sub { $self->wait_done(@_[ARG0..$#_])}
        }
    );

    DEBUG and warn "Listening on port $parms{port}\n";
}

#######################################
# POE event
sub _start
{
    my($self)=@_;
    $self->{session} = $poe_kernel->get_active_session->ID;

    $poe_kernel->alias_set(ref $self);
    return;
}

#######################################
# Called as ContentHandler
sub welcome
{
    my($self, $request, $response)=@_;

    DEBUG and warn "Welcome\n";

    $response->code(RC_OK);
    $response->content_type('text/html; charset=iso-8859-1');

    $response->content(<<HTML);
<html>
<head>
<title>Hello world</title>
</head>
<body>
<h1>Hello world from POE::Component::Server::HTTP</h1>

<ul>
    <li><a href="/last.txt">Text</a></li>
    <li><a href="/multipart.txt">Multipart text</a></li>
    <li><a href="/last.gif">Image</a></li>
    <li><a href="/multipart.gif">Multipart image</a></li>
    <li><a href="/multipart.mixed">Text, then image</a></li>
</ul>
    

</body>
</html>
HTML
    return RC_OK;
}

#######################################
# Called as ContentHandler
sub favicon
{
    my($self, $request, $response)=@_;

    DEBUG and warn "favicon\n";

    $response->code(RC_NOT_FOUND);
    $response->content_type('text/html; charset=iso-8859-1');

    $response->content(<<HTML);
<html>
<head>
<title>Go away</title>
</head>
<body>
<h1>Go away</h1>
</body>
</html>
HTML
    return RC_NOT_FOUND;
}


#######################################
# Called as ContentHandler
sub multipart
{
    my($self, $request, $response)=@_;

    DEBUG and warn "multipart\n";
    
    # Send an HTTP header and turn streaming on
    $self->multipart_start($request, $response);
    # After the HTTP header is sent, our StreamHandler will be called
    # Save the values that stream_start needs to do its work
    push @{$self->{stream_todo}}, [$request, $response, 
                                        'first.gif', 'last.gif'];

    return RC_OK;
}

#######################################
# Called as ContentHandler
sub multipart_mixed
{
    my($self, $request, $response)=@_;

    DEBUG and warn "multipart\n";

    $self->multipart_start($request, $response);
    push @{$self->{stream_todo}}, [$request, $response, 
                                        'first.txt', 'last.gif'];

    return RC_OK;
}

#######################################
# Called as ContentHandler
sub last
{
    my($self, $request, $response)=@_;

    DEBUG and warn "last\n";
    $response->code(RC_OK);
    $response->content_type('image/gif');
    $response->content($self->data('last.gif'));
    return RC_OK;
}

#######################################
# Called as ContentHandler
sub multipart_txt
{
    my($self, $request, $response)=@_;

    DEBUG and warn "multipart_txt\n";

    $self->multipart_start($request, $response);
    push @{$self->{stream_todo}}, [$request, $response, 
                                        'first.txt', 'last.txt'];

    return RC_OK;
}

#######################################
# Called as ContentHandler
sub last_txt
{
    my($self, $request, $response)=@_;

    DEBUG and warn "last_txt\n";
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content($self->data('last.txt'));
    return RC_OK;
}

#######################################
# Called as StreamHandler
sub stream_start
{
    my($self, $request, $response)=@_;

    DEBUG and warn "stream_start\n";

    foreach my $todo (@{$self->{stream_todo}}) {
        my($request, $response, $first, $last)=@$todo;

        DEBUG and warn("post to wait_start for $first, $last\n");
        $self->multipart_send($response, $first);

        # get into our POE session
        $poe_kernel->post($self->{session} => 'wait_start', 
                                $request, $response, $last);
    }

    

    $self->{stream_todo}=[];
    return;
}


#######################################
# POE event
sub wait_start
{
    my($self, $request, $response, $next)=@_;
    DEBUG and warn "Going to wait for $self->{delay} seconds\n";
    $poe_kernel->delay_set(wait_done => $self->{delay}, $request, $response, $next);
    return;
}

#######################################
# POE event
sub wait_done
{
    my($self, $request, $response, $next)=@_;
    DEBUG and warn "Waiting done, sending $next\n";

    $self->multipart_send($response, $next);
    $self->multipart_end($request, $response);

    return;
}

#######################################
# Healper
sub data
{
    my($self, $name)=@_;
    my $file = "$self->{dir}/$name";
    open FILE, $file or die "Can't open $file: $!";
    {
        local $/; 
        $file = <FILE>;
    }
    close FILE;
    return $file;
}


####################################################################

#######################################
# This function sends a file over the connection
# We create a new HTTP response, with content and content_length
# Because HTTP response->as_string sends HTTP status line, we hide it
#   behind a X-HTTP-Status header, just after the boundary.
# This means that this part of the response looks like:
#
# --BoundaryString
# X-HTTP-Status: HTTP/1.0 200 (OK)
# Content-Type: text/plain
# Content-Length: 13
#
# Content here
#
# Setting Content-Length is important for images
sub multipart_send
{
    my($self, $response, $file)=@_;

    DEBUG and warn "multipart_send $file\n";

    my $ct = 'image/gif';
    $ct = 'text/plain' if $file =~ /txt$/;

    my $resp =  $self->multipart_response($ct);

    my $data=$self->data($file);
    $resp->content($data);
    $resp->content_length(length($data));

    $response->send("--$self->{boundary}\cM\cJX-HTTP-Status: ");
    $response->send($resp->as_string);
    return;
}

#######################################
# Create a HTTP::Response object to be sent as a part of the response
sub multipart_response
{
    my($self, $ct, $resp)=@_;
    $resp ||= HTTP::Response->new;
    $resp->content_type($ct||'text/plain');
    $resp->code(200);
    return $resp;
}

#######################################
# Send an HTTP header that sets up multipart/mixed response
# Also turns on streaming.
#
# PoCo::Server::HTTP will send the $response object, then run PostHandler
# then switch to Streaming mode.
sub multipart_start
{
    my($self, $request, $response)=@_;

    $response->code(RC_OK);
    $self->{boundary} ||= 'ThisRandomString';
    $response->content_type("multipart/mixed;boundary=$self->{boundary}");

    $response->streaming(1);
}

#######################################
# The request is done.  Turn off streaming and end the multipart response
# Setting the header Connection to 'close' forces PoCo::Server::HTTP to
# close the socket.  This is needed so that the browsers stop "twirling".
sub multipart_end
{
    my($self, $request, $response)=@_;
    DEBUG and warn "Closing connection\n";
    $response->close;
    $request->header(Connection => 'close');
    $response->send("--$self->{boundary}--\cM\cJ");
}

