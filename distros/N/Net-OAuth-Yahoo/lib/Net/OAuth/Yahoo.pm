package Net::OAuth::Yahoo;

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use Net::OAuth;
use URI::Escape;
use WWW::Mechanize;
use YAML::Syck;

=head1 NAME

Net::OAuth::Yahoo - Provides simple interface to access Yahoo! APIs

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our $ERRMSG  = undef;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

=head1 SYNOPSIS

    use Net::OAuth::Yahoo;

    # Construct hashref of OAuth information
    my $args = {
        consumer_key => "dj0yJmk9TUhIbnlZa0tYVDAzJmQ9WVdrOWMyMUxNVXBoTjJNbWNHbzlNVGd3TnpjMU5qazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lNg--",
        consumer_secret => "93dfc3e0bbeec0c63b86b6f9f3c55772e4f1fe26",
        signature_method => "HMAC-SHA1",
        nonce => "random_string",
        callback => "oob",
    };

    my $oauth = Net::OAuth::Yahoo->new( $args );
    
    # First, obtain the request token
    my $request_token = $oauth->get_request_token();
    
    # Second, fetch the OAuth URL to be presented to the user
    my $url = $oauth->request_auth( $request_token );

    # Third, obtain the OAuth Verifier.  The real way is to present the $url to the end user, have them click on the "Agree" button,
    # then obtain the OAuth Verifier.  I wrote a simulator subroutine that does this, provided Yahoo ID and password.
    # If you go with the real way, you can skip this step.
    my $yid = {
        login => login,
        passwd => passwd,
    };
    
    my $oauth_verifier = $oauth->sim_present_auth( $url, $yid );

    # Using the OAuth Verifier, let's get the token.
    my $token = $oauth->get_token( $oauth_verifier );
    
    # Now it's all done, time to access some API!
    my $api_url = "http://fantasysports.yahooapis.com/fantasy/v2/team/265.l.5098.t.2/players?format=json";
    my $json = $oauth->access_api( $token, $api_url );

    OTHER METHODS:
    The token expires after 1 hour, so you can reuse it until then.  3 methods are provided to facilitate the reuse.

    # Save the token in a YAML file.
    $oauth->save_token( "filename" );

    # Load the token from a YAML file.
    my $token = $oauth->load_token( "filename" );
    
    # Test the token against an URL.  Returns 1 if good, 0 otherwise.
    my $ret = $oauth->test_token( $token, $url );
    
    TESTS:
    Due to the nature of this module, information such as consumer_key, consumer_secret is required.  I have provided test_deeply.pl
    in case the user wants to test the module deeply.  This test script prompts for various Net::OAuth information
    as well as Yahoo login / password.
    
    DEBUGGING:
    This module returns "undef" if something goes wrong.  Also, an error message is set in $Net::Oauth::Yahoo::ERRMSG.
    The user can inspect like so:
    my $request_token = $oauth->get_request_token();
    print $Net::OAuth::Yahoo::ERRMSG if ( !defined $request_token );

=head1 SUBROUTINES/METHODS

=head2 new

    This is the constructor.  Takes a hashref of the following keys, and returns the Net::OAuth::Yahoo object.
    my $args = {
        consumer_key => "dj0yJmk9TUhIbnlZa0tYVDAzJmQ9WVdrOWMyMUxNVXBoTjJNbWNHbzlNVGd3TnpjMU5qazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lNg--",
        consumer_secret => "93dfc3e0bbeec0c63b86b6f9f3c55772e4f1fe26",
        signature_method => "HMAC-SHA1",
        nonce => "random_string",
        callback => "oob",
    };
    my $oauth = Net::OAuth::Yahoo->new( $args );

=cut

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {}, $class;

    $self->_validate_params($args);
    $self->{params}            = $args;
    $self->{request_token_url} = "https://api.login.yahoo.com/oauth/v2/get_request_token";
    $self->{token_url}         = "https://api.login.yahoo.com/oauth/v2/get_token";
    $self->{oauth}             = undef;

    return $self;
}

=head2 get_request_token

    This method talks to the Yahoo! login server then returns the request_token.  No argument is needed as the object contains
    all the information it needs.
    my $request_token = $oauth->get_request_token();

=cut

sub get_request_token {
    my $self = shift;

    $self->{oauth}                     = undef;                                 # clears anything that may have existed
    $self->{oauth}->{consumer_key}     = $self->{params}->{consumer_key};
    $self->{oauth}->{nonce}            = $self->{params}->{nonce};
    $self->{oauth}->{signature_method} = $self->{params}->{signature_method};
    $self->{oauth}->{consumer_secret}  = $self->{params}->{consumer_secret};
    $self->{oauth}->{callback}         = $self->{params}->{callback};
    my $url = $self->{request_token_url};
    $self->{request_token} = $self->_make_oauth_request( "request token", $url );

    return $self->{request_token};
}

=head2 get_token

    Takes the OAuth Verifier (the code that user presents to your webapp) and returns the access token.
    my $token = $oauth->get_token( $oauth_verifier );

=cut

sub get_token {
    my ( $self, $oauth_verifier ) = @_;

    unless ( defined $oauth_verifier ) {
        $ERRMSG = "get_token() invoked without oauth_verifier";
        return undef;
    }

    $self->{oauth}                     = undef;
    $self->{oauth}->{consumer_key}     = $self->{params}->{consumer_key};
    $self->{oauth}->{signature_method} = $self->{params}->{signature_method};
    $self->{oauth}->{nonce}            = $self->{params}->{nonce};
    $self->{oauth}->{consumer_secret}  = $self->{params}->{consumer_secret};
    $self->{oauth}->{verifier}         = $oauth_verifier;
    $self->{oauth}->{token}            = $self->{request_token}->{oauth_token};
    $self->{oauth}->{token_secret}     = $self->{request_token}->{oauth_token_secret};
    my $url = $self->{token_url};
    $self->{token} = $self->_make_oauth_request( "access token", $url );

    return $self->{token};
}

=head2 access_api

    Takes a token and an URL then makes an API call againt the URL.  Data from Yahoo API is returned verbatim.
    This means if you request JSON in the URL, then you'll get JSON back; otherwise XML.  
    my $json = $oauth->access_api( $token, $url );

=cut

sub access_api {
    my ( $self, $token, $url ) = @_;

    unless ( defined $token && defined $url ) {
        $ERRMSG = "access_api() did not receive a token or URL";
        return undef;
    }

    $self->{oauth}                     = undef;
    $self->{oauth}->{consumer_key}     = $self->{params}->{consumer_key};
    $self->{oauth}->{nonce}            = $self->{params}->{nonce};
    $self->{oauth}->{signature_method} = $self->{params}->{signature_method};
    $self->{oauth}->{token}            = uri_unescape( $token->{oauth_token} );
    $self->{oauth}->{token_secret}     = $token->{oauth_token_secret};
    $self->{oauth}->{consumer_secret}  = $self->{params}->{consumer_secret};

    return $self->_make_oauth_request( "protected resource", $url );
}

=head2 _make_oauth_request

    A private method that abstracts Net::OAuth calls.  It is used internally by the object.

=cut

sub _make_oauth_request {
    my ( $self, $req_type, $url ) = @_;

    unless ( defined $url ) {
        $ERRMSG = "_make_oauth_request() could not come up with a URL to make an API request";
        return undef;
    }

    my $ua = LWP::UserAgent->new;

    my $request = Net::OAuth->request($req_type)->new(
        %{ $self->{oauth} },
        request_method => "GET",
        request_url    => $url,
        timestamp      => time,
    );

    $request->sign;
    my $req = HTTP::Request->new( "GET" => $request->to_url );
    my $res = $ua->request($req);

    #print Dumper($res);

    if ( $res->is_success ) {
        return $res->content unless ( $req_type eq "request token" || $req_type eq "access token" );

        my @args_array = split( /&/, $res->content );
        my $args_ref;

        for (@args_array) {
            my ( $k, $v ) = split( /=/, $_ );
            $args_ref->{$k} = $v;
        }
        return $args_ref;
    }

    $ERRMSG = "_make_oauth_request() did not receive a good response";
    return undef;
}

=head2 _validate_params

    A private method that verifies parameters in the constructor.

=cut

sub _validate_params {
    my ( $self, $args ) = @_;
    my @list = ( "consumer_key", "consumer_secret", "signature_method", "nonce", "callback" );
    my @keys = keys %{$args};

    for my $required_key (@list) {
        unless ( grep( /^$required_key$/, @keys ) ) {
            $ERRMSG = "_validate_params() failed";
            return undef;
        }
    }
    return 1;
}

=head2 request_auth

    Takes a request token then returns the URL where the end user needs to access and grant your
    webapp to access protected resources.
    my $url = $oauth->request_auth( $request_token );

=cut

sub request_auth {
    my ( $self, $token ) = @_;

    if ( defined $token->{xoauth_request_auth_url} ) {
        return uri_unescape( $token->{xoauth_request_auth_url} );
    }
    else {
        $ERRMSG = "request_auth() did not receive a valid request token";
        return undef;
    }
}

=head2 sim_present_auth

    Takes an URL and hashref of Yahoo login / password information, then simulates the end user's action
    of granting your webapp to access protected resources.  The method returns the OAuth verifier.
    my $yid = {
        login => "some_login",
        passwd => "some_password",
    }
    
    my $oauth_verifier = $oauth->sim_present_auth( $url, $yid );

=cut

sub sim_present_auth {
    my ( $self, $url, $yid ) = @_;

    unless ( defined $url && defined $yid->{login} && defined $yid->{passwd} ) {
        $ERRMSG = "sim_present_auth() did not receive correct set of params";
        return undef;
    }

    my $mech = new WWW::Mechanize( autocheck => 1 );
    $mech->get($url);

    $mech->submit_form(
        form_number => 0,
        fields    => {
            login  => $yid->{login},
            passwd => $yid->{passwd},
        },
    );

    $mech->submit_form( button => "agree" );

    my ($code) = $mech->content =~ m|<span id="shortCode">(\w+)</span>|;

    unless ( defined $code ) {
        $ERRMSG = "sim_present_auth() could not get oauth_verifier";
        return undef;
    }

    return $code;
}

=head2 save_token

    Takes a filename and dumps the token in YAML format.
    $oauth->save_token( $file );

=cut

sub save_token {
    my ( $self, $file ) = @_;

    unless ( defined $file && defined $self->{token} ) {
        $ERRMSG = "save_token() did not receive filename or, object did not have a token";
        return undef;
    }
    YAML::Syck::DumpFile( $file, $self->{token} );
}

=head2 load_token

    Takes a filename and loads token from the file.  Returns the token object.
    my $token = $oauth->load_token( $file );

=cut

sub load_token {
    my ( $self, $file ) = @_;

    unless ( defined $file && -f $file ) {
        $ERRMSG = "load_token() could not find the file specified";
        return undef;
    }

    my $ref = YAML::Syck::LoadFile($file);

    unless ( defined $ref->{oauth_token} && defined $ref->{oauth_token_secret} ) {
        $ERRMSG = "load_token() token does not seem valid";
        return undef;
    }

    $self->{token} = $ref;
    return $ref;
}

=head2 test_token

    Takes a token object and URL to try fetching some data.  Returns 1 if success, 0 otherwise.
    This method is useful to see if your loaded token has not expired.
    my $ret_code = $oauth->test_token( $token );

=cut

sub test_token {
    my ( $self, $token, $url ) = @_;

    unless ( defined $token && defined $url ) {
        $ERRMSG = "test_token() did not receive the right params";
        return undef;
    }

    my $output = $self->access_api( $token, $url );
    ( defined $output ) ? return 1 : return 0;
}

=head2 get

    Simple getter.  Returns object attributes if defined, undef otherwise.
    my $token = $oauth->get( "token" );

=cut

sub get {
    my ( $self, $item ) = @_;
    ( defined $self->{$item} ) ? return $self->{$item} : undef;
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-oauth-yahoo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OAuth-Yahoo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OAuth::Yahoo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OAuth-Yahoo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OAuth-Yahoo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OAuth-Yahoo>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OAuth-Yahoo/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Net::OAuth::Yahoo
