#!/usr/bin/env perl

# Simple OpenID consumer/relying party
# Robert Norris, November 2010
# Public domain

# This program demonstrates the use of Net::OpenID::Consumer to build an
# OpenID consumer/relying party (RP). It is not intended to be production
# quality, but just show the basics needed to get an RP up and running. It
# uses CGI.pm since everyone understands that :)

use warnings;
use strict;

use CGI ();
use CGI::Carp qw(fatalsToBrowser);
use Net::OpenID::Consumer 1.030099;
use LWP::UserAgent;

my $cgi = CGI->new;

# determine our location and the auth realm based on the enviroment
my $realm = 'http://'.$ENV{HTTP_HOST};
my $base  = $realm.$ENV{SCRIPT_NAME};

# get the parameters from the browser into something useable
my $params = {$cgi->Vars};

# figure out what the caller is trying to do. there are three options:
# root: present a form where the user can enter their openid. this function
#       would be part of your normal login page
# login: the target for the login form. this too is probably already a part of
#        your application/framework
# callback: the place the OpenID Provider (OP) redirects the browser to once
# it has completed the authentication process (pass or failure)
my $action = delete $params->{action} || 'root';
if ($action !~ m{\A root | login | callback \z}x) {
    print $cgi->header(-status => 404);
    exit;
}

# arrange for the handler method to be called
my $method = "handle_$action";
my $ret = do { no strict 'refs'; $method->($realm, $base, $params) };

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


# root action handler. all this does is serve a simple login page. you would
# probably want to add openid as an option to your login page instead
sub handle_root {
    my ($realm, $base, $params) = @_;

    my $html = <<HTML
<form method='post' action='$base'>
<input type='hidden' name='action' value='login'>
OpenID: <input type='text' name='openid'>
<input type='submit'>
</form>
HTML
;
    return [ 200, [ 'Content-Type' => 'text/html' ], [ $html ] ];
}


# login action handler. takes an openid received from the login page and
# begins the auth process
sub handle_login {
    my ($realm, $base, $params) = @_;

    # get an Net::OpenID::Consumer object configured the way we want it
    my $consumer = _get_openid_context($params);

    # create a Net::OpenID::ClaimedIdentity object based on the entered
    # openid. this method will lookup the openid url (HTML or XRDS) to get the
    # openid server endpoint
    my $claimed_identity = $consumer->claimed_identity($params->{openid});

    # if we fail to get the claimed identity it means either the identity is
    # invalid (eg malformed) or the endpoint could not be determined. the
    # Consumer object provides more detail about what happened via its error
    # methods
    if (! $claimed_identity) {
        return [ 200, [ 'Content-Type' => 'text/plain' ],
                 [ 'Invalid identity: '.$consumer->err ] ];
    }

    # the claimed identity is valid, so now we need to build a url on the OP
    # to redirect the browser to
    my $check_url = $claimed_identity->check_url(
        # this is the url the OP should redirect the browser to when its
        # authentication process is completed
        return_to      => $base.'?action=callback',

        # this tells the OP what uri this login will be applied to. the OP is
        # being asked to verify if the identifier is valid for every uri
        # "under" this one. this is typically presented to the user by the OP
        # in a "do you trust this?" type of dialog
        trust_root     => $realm,

        # enabling delayed_return tells the OP that it now has full control of
        # the browser and can do whatever it likes (eg several screens worth
        # of authentication flow) before returning the browser back to us (ie
        # openid.mode = checkid_setup)
        #
        # if you want to do the login in the background via javascript, you'd set
        # this to 0 (ie checkid_immediate) so that the javascript code can
        # fail directly and cause the display to either prompt the user to
        # login manually with their provider or launch another openID login
        # from a visible window (where you *can* set delayed_return to 1)
        delayed_return => 1,
    );

    # redirect the browser to the OP
    return [ 301, [ Location => $check_url ], [] ];
}


# callback action handler. the OP redirects the browser here in response to
# the process begun in handle_login. usually thats after the auth process has
# completed successfully, but failures (eg user denying access) will also come
# here and need to be handled
sub handle_callback {
    my ($realm, $base, $params) = @_;

    # get the Net::OpenID::Consumer object
    my $consumer = _get_openid_context($params);

    # call the response handler. it takes a few coderefs to handle the various
    # things that might be received from the OP. the data returned by the
    # coderef is what will be returned by the handler
    return $consumer->handle_server_response(

        # not_openid is called when the parameters passed to the callback url
        # don't represent a valid openid message. this means either the OP is
        # broken or (more likely) a user is trying to access the callback url
        # directly. there's not much you can do here other than fail
        # gracefully.
        not_openid => sub {
            return [ 200, [ 'Content-Type' => 'text/plain', ], [ 'Not an OpenID message.' ] ];
        },

        # since we have delayed_return == 1 above
        # covering the setup_needed case is not actually necessary
        setup_needed => sub {
            # this might be version 1.1 and setup_url may have been
            # been provided, in which case we could redirect
            if ($consumer->message->protocol_version < 2) {
                my $setup_url = $consumer->user_setup_url;
                return [ 301, [ Location =>  $setup_url ], [] ]
                  if ($setup_url);
            }

            return [ 200, [ 'Content-Type' => 'text/plain', ],
                     [ 'You must login with your provider first.' ] ];
        },

        # cancelled is called when the OP informs us that the user cancelled
        # the login process in some way. this is typically a result of the
        # user answering "no" or "deny" to a "do you trust this site" type of
        # message
        cancelled => sub {
            return [ 200, [ 'Content-Type' => 'text/plain', ], [ 'User cancelled login process.' ] ];
        },

        # verified is called when the OP informs us that it believes that the
        # user owns the claimed identity. that usually means the user
        # successfully authenticated with the OP and agreed to trust your
        # application. the user's identity uri is passed to the sub. this is
        # not necessarily the same as the claimed identifier used to begin the
        # login process, but it will be unique and specific to this user.
        # typically at this point you will use the identity as the primary key
        # to load or create a user account in your application
        verified => sub {
            my ($verified_identity) = @_;

            return [ 200, [ 'Content-Type' => 'text/plain', ], [ 'Verified identity: '.$verified_identity->url ] ];
        },

        # any other error will be reported here. the Consumer object will make
        # more information about the error available via its error methods
        error => sub {
            my ($error) = @_;

            return [ 200, [ 'Content-Type' => 'text/plain', ], [ 'Error: '.$consumer->err ] ];
        },

    );
}

# helper function to prepare a Consumer object
sub _get_openid_context {
    my ($params) = @_;

    my $consumer = Net::OpenID::Consumer->new(

        # ua takes a LWP::UserAgent object that will be used fetch the
        # identity url provided by the user.  Since this can be an
        # arbitrary URL it's possible for a user to make your
        # application to a fetch on some other url on its behalf,
        # possibly something inside your firewall.
        # If that's a problem for you, consider vetting the identifer
        # provided by the user or subclassing LWP::UserAgent to
        # protect against such things (see LWPx::ParanoidAgent for an
        # example of this)
        ua              => LWP::UserAgent->new,

        # args can take a number of different objects that may contain
        # the request parameters from the browser, eg a CGI,
        # Apache::Request, Apache2::Request or similar (see the
        # documentation for more). if a coderef is provided (as is the
        # case here), it will either be passed a single argument
        # containing the wanted parameter, in which case it should
        # return the value of that parameter (or undef if not
        # available), or it will be passed no arguments and the full
        # list of parameter names should be returned

        args            => sub { @_ ? $params->{+shift} : keys %$params },

        # consumer_secret takes a coderef that is called to generate the
        # "nonce" value for the return_to uri. it is passed a single argument
        # containing a unix timestamp and should produce a unique,
        # reproducable and non-guessable value based on that time. if this
        # value does not meet those criteria your RP is vulnerable to replay
        # attacks
        #
        # for the sake of this demo we return a static string here. you MUST
        # NOT do this in a production environment
        consumer_secret => sub { return 'xyz789' },
    );

    return $consumer;
}

__END__

=pod

=head1 NAME

consumer.cgi - demo OpenID consumer/relying party using Net::OpenID::Consumer

=head1 DESCRIPTION

This program demonstrates the use of Net::OpenID::Consumer to build an OpenID
consumer/relying party (RP). It is not intended to be production quality, but
just show the basics needed to get an RP up and running.

It should work under pretty much any web server that can run CGI programs. Its
been tested under lighttpd on Linux.

Read the code to find out how it all works!

=head1 AUTHOR

Robert Norris E<lt>rob@eatenbyagrue.orgE<gt>

=head1 LICENSE

This program is in the public domain.

=cut
