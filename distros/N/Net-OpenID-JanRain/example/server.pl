#!/usr/bin/perl

use warnings;
use strict;

use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;

use URI;
use URI::QueryParam;
use CGI;


our $debug = 0;

my $d;

while(1) {
    $d = HTTP::Daemon->new(
            LocalPort => 8008,
            ReuseAddr => 1,
            );
    unless($d) {
        warn;
        sleep(1);
    }
    else {
        $d and last;
    }
}

my $conn;
$SIG{INT} = $SIG{HUP} = sub {
    my ($sig) = @_;
    print "signal $sig caught\n";
    if($conn) {
        $conn->close;
        undef($conn);
    }
    else {
        warn "no connection!\n";
    }
    undef($d);
    exit;
};
print "Example OpenID server running at: <URL:  ", $d->url, ">\n";

use Net::OpenID::JanRain::Server;
use Net::OpenID::JanRain::Stores::FileStore;
use Net::OpenID::JanRain::Util;

use Net::OpenID::JanRain::CryptUtil qw( randomString );

my $alphanums = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890";

# We'll need a store.
my $store = Net::OpenID::JanRain::Stores::FileStore->new('sstore');

die "Store creation failed" unless $store;

# The server needs to know the URL handled by getOpenIDResponse
my $serverurl = $d->url."openidserver";

# And a server.
my $server = Net::OpenID::JanRain::Server->new($store);

# keep record of what's permitted
my %allowed;

# In a real app I'd use a proper session object
# but here I'll just store requests in a hash, keyed by a nonce
my %requests;

########################################################################
while($conn = $d->accept) {
    while(my $r = $conn->get_request) {
        $conn->force_last_request;
        warn $r->method, " ", $r->url, "\n";
      
        my $uri = URI->new($r->url);
        my ($res, $request, $response, $webresp);

        if ($r->method eq 'POST') {
            print $r->content."\n";
        }

        if ($uri->path eq '/openidserver') {
            my $query;
            if($r->method eq 'GET') {
                $query = $uri->query_form_hash;
            }
            else { # assume POST
                my $cgi = CGI->new($r->content);
                $query = $cgi->Vars;
            }
            $request = $server->decodeRequest($query);
            unless(defined($request)) {
                # undefined request means that the query was not
                # recognizable as an openid query, so display a page
                # with a couple links to sites about openid
                $res = aboutPage();
            }
            elsif($request->isa('Net::OpenID::JanRain::Server::ProtocolError')) {
                $webresp = $server->encodeResponse($request);
                $res = wrToHTTPResp($webresp);
            }
            elsif(UNIVERSAL::isa($request,
               'Net::OpenID::JanRain::Server::CheckIDRequest')) {
               # CheckID requests need app interaction to verify
               # that the id in question in fact belongs to the user
                my $trust_root = $request->trust_root;
                my $id = $request->identity;
                
                # This requires that the trust roots are an exact match
                # You will want to also check for allowed trust_roots that
                # are parents (i.e. prefixes ending in /) of $trust_root.
                my $allow = $allowed{"$id $trust_root"};
             
                if($allow) {
                    $response = $request->answer(1);
                    $webresp = $server->encodeResponse($response);
                    $res = wrToHTTPResp($webresp);
                }
                elsif($request->immediate) {
                    # you must pass the server url when rejecting
                    # a checkid_immediate request, so that the library
                    # can build a setup_url, which is essentially the
                    # same except with checkid_setup instead of immediate
                    $response = $request->answer(0, $serverurl);
                    $webresp = $server->encodeResponse($response);
                    $res = wrToHTTPResp($webresp);
                }
                else {
                    # Request is not pre-approved and is not immediate mode
                    # it's time for authentication.
                    $res = authenticationPage($request);
                }
            }
            else {
                # The server knows how to deal with check_authentication
                # and associate modes.
                $response = $server->handleRequest($request);
                $webresp = $server->encodeResponse($response);
                $res = wrToHTTPResp($webresp);                
            }
        }
        elsif ($uri->path =~ m:^/id/(\w+): ) {
            $res = identityPage($1);
        }
        elsif ($uri->path eq '/auth' and $r->method eq 'POST') {
            my $cgi = CGI->new($r->content);
            my $query = $cgi->Vars;
            $res = handleAuth($query);
        }
        else {
            $res = HTTP::Response->new;
            $res->code(404);
            $res->content(errorPage("Not Found."));
        }
        print "Response: ".$res->code."\n".$res->content."\n";
        $conn->send_response($res);
    }
    $conn->close;
    undef($conn);
}

sub wrToHTTPResp {
    my ($webresp) = @_;
    my $res;
    $res = HTTP::Response->new($webresp->code);
    my %headers = %{$webresp->headers};
    while (my ($k, $v) = each %headers) {
        $res->header($k => $v);
    }
    $res->content($webresp->body);
    return $res;
}

sub handleAuth {
    my ($form) = @_;
    
    # Clearly in a real app you'll want something more sophisticated here
    # y'know, some form of actual authentication
    my $permit = $form->{yes};
    
    my $request_key = $form->{request_key};
    my $request = $requests{$request_key};
    delete $requests{$request_key};
    
    return errorPage("REQUEST NOT FOUND ERROR. REDO FROM START.")
        unless defined($request);

    my $id_url = $request->identity;
    my $trust_root = $request->trust_root;

    my $response;
    
    if($permit) {
        $response = $request->answer(1);
        if($form->{remember}) {
            # I reiterate that this allowed hash has the problem
            # that descending trust roots are not automatically
            # permitted, only exactly matching trust roots.
            my $k = "$id_url $trust_root";
            $allowed{$k} = 1;
        }
    }
    else {
        $response = $request->answer(0);
    }
    my $webresp = $server->encodeResponse($response);
    return wrToHTTPResp($webresp);
}

sub identityPage {
    my ($user) = @_;
    my $page = join("\n", "<html><head><title>Example Identity page for $user</title>",
        "<link rel='openid.server' href='$serverurl' > </head>",
        "<body><h1>OpenID Server Example<h1>",
        "<h2>Identity page for $user</h2>",
        "This page contains a link tag that shows that the owner of this",
        "URL uses this OpenID server. </body></html>");
    my $res = HTTP::Response->new(200);
    $res->content($page);
    return $res;
}

sub authenticationPage {
    my ($request) = @_;
    my $trust_root = $request->trust_root;
    my $identity = $request->identity;
    my $nonce = randomString(8, $alphanums);

    $requests{$nonce} = $request;
    my $res = HTTP::Response->new(200);
    $res->content(join("\n",
        "<html><head><title>OpenID Example Auth Page</title><head>",
        "<body><h1>OpenID Example Auth Page</h1>",
        "<p>A site has asked for your identity.  If you",
        "approve, the site represented by the trust root below will",
        "be told that you control identity URL listed below. (If",
        "you are using a delegated identity, the site will take",
        "care of reversing the delegation on its own.)</p>",
        "<p>This being a simple example, we don't do logins.",
        "In a real application, this page would verify that",
        "the user is who they are claiming to be.</p>",
        "<h2>Permit this authentication?</h2>",
        "<table>",
        "<tr><td>Identity:</td><td>$identity</td></tr>",
        "<tr><td>Trust Root:</td><td>$trust_root</td></tr>",
        "</table>",
        "<form method='POST' action='/auth'>",
        "<input type='hidden' name='request_key' value='$nonce' />",
        "<input type='checkbox' id='remember' name='remember' value='yes'",
        'checked="checked" /><label for="remember">Remember this decision',
        "</label><br>",
        '<input type="submit" name="yes" value="yes" />',
        '<input type="submit" name="no" value="no" /></form>',
        "</body></html>"
        ));
    return $res;
}

sub aboutPage {
    my $res = HTTP::Response->new(200);
    $res->content(join("\n", 
        "<html><head><title>Example OpenID Server Endpoint</title></head>",
        "<body><h1>Example OpenID About Page</h1>",
        "<p>This page is for when the Server endpoint is visited with no",
        "query arguments, suggesting that someone entered in the URL by",
        "hand.  Render a short description such as the following:</p>",
        "<p>This is an OpenID server endpoint, not a human readable",
        "resource.  For more information about openid, try ",
        "<a href='http://www.openidenabled.com/'>this page</a>.</p>",
        "</body></html>"));
    return $res;
}

sub errorPage {
    my ($msg) = @_;
    my $res = HTTP::Response->new(400);
    $res->content(join("\n", 
        "<html><head><title>Example OpenID Server Error Page</title></head>",
        "<body><h1>OpenID Example Server Error</h1>",
        "<p>$msg</p>",
        "</body></html>"));

    return $res;
}
