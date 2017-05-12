#!/usr/bin/perl

use strict;
use Carp;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use OpenID::Login;

# call with https://www.example.com/cgi-bin/01_openid_redirect.pl?identifier=https://user.example.com

my $cgi = new CGI;
my $identifier = $cgi->param('identifier') or croak 'required parameter identifier missing';

my $openid = OpenID::Login->new(
    claimed_id => $identifier,
    return_to  => 'https://www.examle.com/cgi-bin/02_openid_auth.pl',
    realm      => 'https:/www.example.com/',
    extensions => [
        {   ns         => 'ax',
            uri        => 'http://openid.net/srv/ax/1.0',
            attributes => {
                mode     => 'fetch_request',
                required => 'firstname,lastname,email',
                type     => {
                    email     => 'http://axschema.org/contact/email',
                    firstname => 'http://axschema.org/namePerson/first',
                    lastname  => 'http://axschema.org/namePerson/last',
                }
            }
        },
    ]
);

my $redirect_url = $openid->get_auth_url();
print $cgi->redirect($redirect_url);
