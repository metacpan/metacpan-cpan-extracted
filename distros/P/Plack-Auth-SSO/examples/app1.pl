#!/usr/bin/env perl
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, "..", "lib" );
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu -load => [ $FindBin::Bin ];
use Plack::Builder;
use Plack::Auth::SSO::CAS;
use Plack::Auth::SSO::ORCID;
use Catmandu;
use JSON;

#Catmandu config. Please copy catmandu.yml.example to catmandu.yml in this directory and fill in!
my $config = Catmandu->config;

#whitelist for users
my $users = Catmandu->store("users")->bag();

#base url for this application
my $uri_base = $config->{uri_base};

builder {

    #Plack Session is required
    enable "Session";

    #package that authenticates CAS users
    mount "/auth/cas" => Plack::Auth::SSO::CAS->new(

        #see Catmandu->config->{cas}
        %{ $config->{cas} },
        #uri_base is needed in order to construct correct urls
        uri_base => $uri_base,
        authorization_path => "/authorize"

    )->to_app;

    #package that authenticates ORCID users
    mount "/auth/orcid" => Plack::Auth::SSO::ORCID->new(

        #see Catmandu->config->{orcid}
        %{ $config->{orcid} },
        uri_base => $uri_base,
        authorization_path => "/authorize",

    )->to_app;

    #logout route
    mount "/logout" => sub {

        my $session = Plack::Session->new(shift);
        $session->expire();

        [
            302,
            [ "Location" => "${uri_base}/" ],
            []
        ];

    };

    #plack application that retrieves auth_sso and authorizes users
    #if necessary, one can split this up in two routes (e.g. "/authorize/cas" and "/authorize/orcid")
    mount "/authorize" => sub {


        my $env = shift;
        my $session = Plack::Session->new($env);
        my $auth_sso = $session->get("auth_sso");

        #not authenticated yet
        unless($auth_sso){

            return [
                302,
                [ "Location" => "${uri_base}/" ],
                []
            ];

        }

        #process auth_sso (white list, roles ..)
        my $user;
        if ( $auth_sso->{package} eq "Plack::Auth::SSO::CAS" ) {

            $user = $users->select( sso_cas => $auth_sso->{uid} )->first();

        }
        elsif ( $auth_sso->{package} eq "Plack::Auth::SSO::ORCID" ) {

            $user = $users->select( sso_orcid => $auth_sso->{uid} )->first();

        }

        #user not in whitelist
        unless ( defined($user) ) {

            return [
                403,
                [ "Content-Type" => "text/plain" ],
                [ "authenticated user, but not included in our whitelist" ]
            ];

        }

        #mark as logged in
        $session->set( "user", $user );

        #redirect to route that is only accessible for logged in users
        [
            302,
            [ Location => "${uri_base}/authorized" ],
            []
        ];
    };

    mount "/authorized" => sub {

        state $json = JSON->new()->utf8(1)->pretty(1);

        my $env = shift;
        my $session = Plack::Session->new($env);

        my $user = $session->get("user");

        unless ( is_hash_ref( $user ) ) {

            return [
                403,
                [ "Content-Type" => "text/plain" ],
                [ "Access forbidden" ]
            ];

        }

        my $auth_sso = $session->get("auth_sso");

        #show information to the user
        my $pre = $json->encode( $auth_sso );

        my %_escape_table = ( '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', q{"} => '&quot;', q{'} => '&#39;', q{`} => '&#96;', '{' => '&#123;', '}' => '&#125;' );
        $pre =~ s/([&><"'`{}])/$_escape_table{$1}/ge;

        my $html = <<EOF;
<!doctype html>
<html>
    <head>
        <title>Plack::Auth::SSO demo application</title>
    </head>
    <body>
        <h2>Hello $user->{_id}!</h2>
        <h2>You are authenticated with package $auth_sso->{package}!</h2>
        Here is the authentication hash:
        <pre>$pre</pre>
        <a href="${uri_base}/logout">Logout</a>
    </body>
</html>

EOF

        [
            200,
            [
                "Content-Type" => "text/html"
            ],
            [ $html]
        ];

    };

    mount "/" => sub {

        my $user = Plack::Session->new(shift)->get("user");

        if ( is_hash_ref($user) ) {

            return [
                302,
                [ Location => "${uri_base}/authorized" ],
                []
            ];

        }

        my $html = <<EOF;
<!doctype html>
<html>
    <head>
        <title>Plack::Auth::SSO demo application</title>
    </head>
    <body>
        <h2>Select a way to authenticate</h2>
        <ul>
            <li>
                <a href="${uri_base}/auth/cas">Sign in with CAS</a>
            </li>
            <li>
                <a href="${uri_base}/auth/orcid">Sign in with ORCID</a>
            </li>
        </ul>
    </body>
</html>
EOF

        [ 200, [ "Content-Type" => "text/html" ], [ $html ] ];

    };

};
