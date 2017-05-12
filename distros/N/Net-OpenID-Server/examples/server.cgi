#!/usr/bin/env perl

# Simple OpenID server/provider
# Robert Norris, November 2010
# Public domain

# This program demonstrates the use of Net::OpenID::Server to build an OpenID
# server/provider (OP). It is not intended to be production quality, but just
# show the basics needed to get an OP up and running. It uses CGI.pm since
# everyone understands that :)

use warnings;
use strict;

use CGI ();
use CGI::Carp qw(fatalsToBrowser);
use Net::OpenID::Server 1.030099;
use URI::Escape;

my $cgi = CGI->new;

# determine our location based on the enviroment
my $base = 'http://'.$ENV{HTTP_HOST}.$ENV{SCRIPT_NAME};

# get the parameters from the browser into something useable
my $params = {$cgi->Vars};

# figure out what the caller is trying to do. there are four options:
# endpoint: provide the endpoint interface to the RP. this is the main entry
#           point and is not normally accessed directly by the user
# setup: handles setup, which is the openid term for interacting with the user
#        to determine if the user trusts the RP. here it presents a simple
#        login form
# login: the target for the login form. this is not actually part of the
#        openid flow but it makes a useful and not-uncommon example
# user: handles the actual identity urls, serving either HTML or XRDS pointing
#       to the endpoint. you need to implement this somewhere but its not
#       strictly part of the openid flow, and could just be one or more static
#       pages depending on your application
my $action = delete $params->{action} || 'endpoint';
if ($action !~ m{\A endpoint | setup | login | user \z}x) {
    print $cgi->header(-status => 404);
    exit;
}

# arrange for the handler method to be called
my $method = "handle_$action";
my $ret = do { no strict 'refs'; $method->($base, $params) };

# handle the return. these handlers return PSGI three-part arrays, so you
# could easily port them to your PSGI-based application. here we convert that
# into something to send back through CGI.pm
my ($status, $headers, $content) = @$ret;
push @$headers, ( Pragma => 'no-cache' );

my %headers;
while (my ($k, $v) = splice @$headers, 0, 2) {
    $headers{"-$k"} = $v;
}

print $cgi->header(-status => $status, %headers);
print join '', @$content;

exit;


# endpoint action handler. all interactions between the RP and the OP, either
# directly or via browser redirects
sub handle_endpoint {
    my ($base, $params) = @_;

    # get an Net::OpenID::Server object configured the way we want it
    my $openid = _get_openid_context($base, $params);

    # call the handler to figure out what the appropriate response it for the
    # given parameters
    my ($type, $data) = $openid->handle_page;

    # the server wants to redirect the browser somewhere, perhaps back to the
    # RP. the url is in $data. all we have to do is redirect them using
    # whatever redirect mechanism is provded by the web framework
    if ($type eq 'redirect') {
        return [ 302, [ 'Location' => $data, ], [] ];
    }

    # the server has decided that it doesn't know if the user explicitly
    # trusts or distrusts the RP, and needs you to ask them somehow. this is
    # known as "setup", and is triggered when the is_identity or is_trusted
    # callbacks return false (see _get_openid_context below).
    #
    # $data is a hashref of parameters that should be passed to
    # signed_return_url (trust) or cancel_return_url (doesn't trust) to build
    # the appropriate response for the RP.
    if ($type eq 'setup') {
        # build the setup redirect url, passing along the parameters so they
        # can be given back to the server later to build the redirect url
        # later
        my $location =
            $openid->setup_url . '&' .
            join ('&', map { $_ . '=' . uri_escape(defined $data->{$_} ? $data->{$_} : '') } keys %$data);

        return [ 302, [ 'Location' => $location, ], [] ];
    }

    # the server has a response to send back directly. this is either some
    # sort of error page for the browser, or a direct response to the RP.
    # $type contains the mime type and $data has the content
    return [ 200, [ 'Content-Type' => $type, ], [ $data ] ];
}

# setup action handler. this is the entry point for determining if the user
# trusts the RP. here we begin a login-type flow, but you can do whatever
# makes most sense for your site. $params contains the parameters that came
# from the setup response to handle_page above, and need to be passed back to
# the server so it can construct the RP redirect url
#
# the most common flow for setup is to login the user if they're not already
# logged in, then ask them if they trust the RP. that's usually a question
# like "You are logging into <realm> as <identity>. Is this ok?".  based on
# that response you'll call signed_return_url or cancel_return_url. the realm
# is available in $data->{trust_root}.  most OPs also store this decision
# somewhere so the user doesn't have to be asked next time.
sub handle_setup {
    my ($base, $params) = @_;

    my $html = join("\n",
        "<form method='get' action='$base'>",
            (map { defined $params->{$_} ? "<input type='hidden' name='$_' value='" . $params->{$_} . "'>" : '' } keys %$params),
            "username: <input type='text' name='user'><br>",
            "password: <input type='password' name='pass'><br>",
            "<input type='hidden' name='action' value='login'>",
            "<input type='submit' value='login'>",
        "</form>",
    );

    return [ 200, [ 'Content-Type' => 'text/html', ], [ $html ] ];
}

# login action handler. this is where the login form goes. for the sake of
# this example we pretend that all logins succeed
sub handle_login {
    my ($base, $params) = @_;

    my $user = delete $params->{user};
    my $pass = delete $params->{pass};

    # now we know who the user is we can construct their identity url and
    # include it in the parameters
    $params->{identity} = _identity_url($base, $user);

    # get the Net::OpenID::Server object configured the way we want it. this
    # time we include the user as well
    my $openid = _get_openid_context($base, $params, $user);

    # for this demo we're trusting anything. here you probably want to ask the
    # user if they trust the RP as described above

    # construct the RP redirect url to indicate the user trusts the RP
    my $return_url = $openid->signed_return_url(%$params);

    return [ 301, [ 'Location' => $return_url, ], [ ] ];
}


# user action handler. this serves appropriate HTML or XRDS for an identity
# url to point to the endpoint
sub handle_user {
    my ($base, $params) = @_;

    # get the Net::OpenID::Server object configured the way we want it
    my $openid = _get_openid_context($base, $params);

    # construct the identity url for this user
    my $identity = _identity_url($base, $params->{user});
    my $endpoint = $openid->endpoint_url;

    # return either XRDS or HTML depending on what the client asked for
    if ($ENV{HTTP_ACCEPT} =~ m{ \b application/xrds\+xml \b }x) {
        return [ 200, [ 'Content-Type' => 'application/xrds+xml', ], [ _user_xrds($identity, $endpoint) ] ];
    }
    else {
        return [ 200, [ 'Content-Type' => 'text/html', ], [ _user_html($identity, $endpoint) ] ];
    }
}
    
# helper function to construct the identity url for the given user
sub _identity_url {
    my ($base, $user) = @_;
    return $base.'?action=user&user='.$user;
}

# helper function to prepare a Server object
sub _get_openid_context {
    my ($base, $params, $user) = @_;

    my $openid = Net::OpenID::Server->new(
        # args can take a number of different objects that may contain the
        # request parameters from the browser, eg a CGI, Apache::Request,
        # Apache2::Request or similar (see the documentation for more). if a
        # coderef is provided (as is the case here), it will be passed a
        # single argument containing the wanted parameter, and should return
        # the value of that parameter, or undef if its not available
        args => sub { $params->{+shift} },

        # get_user returns an identifier for the currently logged-in user, or
        # undef if there's no user. the return value is not used but is passed
        # as-is to is_identity and is_trusted
        get_user => sub {
            return $user;
        },

        # is_identity returns true if the passed user "owns" the passed
        # identity url. the user is the one returned from get_user, whereas
        # the identity typically comes from the RP via the browser. this could
        # conceivably return false in the case where the user is logged in to
        # the OP but has specified an identifier that is not their own. in
        # that case you return false here which will trigger setup
        is_identity => sub {
            my ($user, $identity) = @_;
            return if not $user;
            return $identity eq _identity_url($base, $user);
        },

        # is_trusted returns true if the user trusts the passed realm (trust
        # root). the user and is_identity parameters are the same as what was
        # returned by get_user and is_identity. if you're keeping a record
        # of realms the user trusts, its here that you'd check that record
        is_trusted => sub {
            my ($user, $realm, $is_identity) = @_;
            return if not $user;
            return $is_identity;
        },

        # urls for endpoint and setup. these are used when constructing
        # redirect urls
        endpoint_url => $base,
        setup_url    => $base.'?action=setup',

        # server_secret takes a coderef that is called to generate and sign
        # per-consumer secrets. it is passed a single argument containing a
        # unix timestamp and should produce a unique, reproducable and
        # non-guessable value based on that time. if this value does not meet
        # those criteria your RP is vulnerable to replay attacks
        #
        # for the sake of this demo we return a static string here. you MUST
        # NOT do this in a production environment
        server_secret => sub {
            return 'abc123';
        },
    );

    return $openid;
}

# helper function to return an XRDS structure for the identity and endpoint
sub _user_xrds {
    my ($identity, $endpoint) = @_;

    return <<XRDS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://\$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://\$xrd*(\$v*2.0)">
  <XRD version="2.0">
    <Service priority="0">
      <Type>http://specs.openid.net/auth/2.0/signon</Type>
      <URI>$endpoint</URI>
      <LocalID>$identity</LocalID>
    </Service>
    <Service priority="1">
      <Type>http://openid.net/signon/1.1</Type>
      <URI>$endpoint</URI>
      <openid:Delegate>$identity</openid:Delegate>
    </Service>
    <Service priority="2">
      <Type>http://openid.net/signon/1.0</Type>
      <URI>$endpoint</URI>
      <openid:Delegate>$identity</openid:Delegate>
    </Service>
  </XRD>
</xrds:XRDS>
XRDS
;
}

# helper function to return an HTML page for the identity and endpoint
sub _user_html {
    my ($identity, $endpoint) = @_;

    return <<HTML
<!doctype html>
<html>
  <head>
    <title>OpenID identity page</title>
    <link rel="openid.server" href="$endpoint">
    <link rel="openid2.provider" href="$endpoint">
  </head>
  <body>
    <p>This is an OpenID identity page. It will direct an OpenID RP to the OpenID endpoint at <b>$endpoint</b> to provide service for <b>$identity.</b></p>
  </body>
</html>
HTML
;
}

__END__

=pod

=head1 NAME

server.cgi - demo OpenID server/provider using Net::OpenID::Server

=head1 DESCRIPTION

This program demonstrates the use of Net::OpenID::Server to build an OpenID
server/provider (OP). It is not intended to be production quality, but just
show the basics needed to get an OP up and running.

It should work under pretty much any web server that can run CGI programs. Its
been tested under lighttpd on Linux.

It services identity URLs of the form: server.cgi?action=user&user=<username>

Read the code to find out how it all works!

=head1 AUTHOR

Robert Norris E<lt>rob@eatenbyagrue.orgE<gt>

=head1 LICENSE

This program is in the public domain.

=cut
