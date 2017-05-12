#!/usr/bin/perl

use strict;
use Carp;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use OpenID::Login;

my $cgi = new CGI;

print $cgi->header("text/plain");

my $res = OpenID::Login->new( cgi => $cgi, return_to => 'https://www.examle.com/cgi-bin/openid_auth' );
my $identity_url = $res->verify_auth();

if ($identity_url) {    # openid login successfully completed.
    print "Verified Identity: $identity_url\n";
    my $ax = $res->get_extension('http://openid.net/srv/ax/1.0');
    if ($ax) {
        my $firstname = $ax->get_parameter('value.firstname');
        my $lastname  = $ax->get_parameter('value.lastname');
        my $email     = $ax->get_parameter('value.email');

        print "Result: $firstname $lastname ($email)\n";

        # now do e.g. set a session login cookie and redirect or directly present your protected data for this user
    }
} else {
    croak "Login failed.\n";
}
