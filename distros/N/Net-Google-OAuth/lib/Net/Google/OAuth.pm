package Net::Google::OAuth;

our $VERSION = '0.03';

use 5.008001;
use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use JSON::XS;
use Carp qw/carp croak/;

sub new {
    my ($class, %opt) = @_;
    my $self = {};
    $self->{client_secret}          = $opt{-client_secret}      || croak "You must specify '-client_secret' param";
    $self->{client_id}              = $opt{-client_id}          || croak "You must specify '-client_id' param";
    $self->{token}                  = {};
    $self->{ua}                     = LWP::UserAgent->new();

    # Get list of OpenId services
    __getOpenIdServices($self);

    return bless $self, $class;
}


sub generateAccessToken {
    my ($self, %opt)            = @_;
    $self->{scope}              = $opt{-scope}              || croak "You must specify '-scope' param";
    $self->{email}              = $opt{-email}              || croak "You must specify '-email' param";
    $self->{scope}              = 'https://www.googleapis.com/auth/' . $self->{scope};


    my $param = {
        'client_id'         => $self->{client_id},
        'response_type'     => 'code',
        'scope'             => $self->{scope},
        'redirect_uri'      => 'http://localhost:8000',
        'state'             => 'uniq_state_' . int(rand() * 100000),
        'login_hint'        => $self->{email},
        'nonce'             => int(rand() * 1000000) . '-' . int(rand() * 1000000) . '-' . int(rand() * 1000000),
        'access_type'       => 'offline',
    };

    my $uri = URI->new($self->{services}->{authorization_endpoint});
    $uri->query_form($param);
    
    print STDOUT "Please open this URL in your browser: \n", "\x1b[4;34m", $uri->as_string, "\x1b[0m", "\n";
    print STDOUT "Insert redirected address from browser here:\n";
    my $response_step1 = <STDIN>;
    $response_step1 =~ s/\r|\n//g;

    $uri = URI->new($response_step1) or croak "Can't parse response: $response_step1";
    my %query_form = $uri->query_form();
    my $code_step1 = $query_form{code} // croak "Can't get 'code' from response url";

    my $token = $self->__exchangeCodeToToken(
        -code           => $code_step1,
        -grant_type     => 'authorization_code',
    );

    for my $key (keys %$token) {
        $self->{token}->{$key} = $token->{$key};
    }

    return 1;
}

sub getTokenInfo {
    my ($self, %opt) = @_;
    my $access_token = $opt{-access_token} || $self->getAccessToken() || croak "You must specify '-access_token'";

    my $request = $self->{ua}->get('https://www.googleapis.com/oauth2/v2/tokeninfo?access_token=' . $access_token);
    my $response_code = $request->code;
    if ($response_code != 200) {
        croak "Can't getTokenInfo about token: $access_token. Code: $response_code";
    }

    my $response = decode_json($request->content);

    return $response;
}



sub refreshToken {
    my ($self, %opt) = @_;
    my $refresh_token = $opt{-refresh_token}    || croak "You must specify '-refresh_token' param";
    my $token = $self->__exchangeCodeToToken(
        -code           => $refresh_token,
        -grant_type     => 'refresh_token',
    );

    for my $key (keys %$token) {
        $self->{token}->{$key} = $token->{$key};
    }

    return 1;
}

sub __exchangeCodeToToken{
    #Exchange code or refresh token to AccessToken
    my ($self, %opt)    = @_;
    my $code            = $opt{-code};
    my $grant_type      = $opt{-grant_type} || croak "You must specify '-grant_type' param";

    # Exchange code to token
    my $param = {
        'client_id'         => $self->{client_id},
        'client_secret'     => $self->{client_secret},
        'redirect_uri'      => 'http://localhost:8000',
        'grant_type'        => $grant_type,
        'access_type'       => 'offline',
    };
    if ($grant_type eq 'authorization_code') {
        $param->{code} = $code;
    }
    elsif ($grant_type eq 'refresh_token') {
        $param->{refresh_token} = $code;
    }
    else {
        croak "Param '-grant_type' must contain values: 'authorization_code' or 'refresh_token'";
    }

    my $response = $self->{ua}->post(  
                                    $self->{services}->{token_endpoint},
                                    $param,
                                );
    my $response_code = $response->code;
    if ($response_code != 200) {
        croak "Can't get token. Code: $response_code";
    }

    my $token = decode_json($response->content);

    return $token;
}

sub __getOpenIdServices {
    my ($self) = @_;

    my $request = $self->{ua}->get('https://accounts.google.com/.well-known/openid-configuration');
    my $response_code = $request->code;
    if ($response_code != 200) {
        croak "Can't get list of OpenId services";
    }

    my $response = decode_json($request->content);

    $self->{services} = $response;

    return 1;
}

################### ACESSORS #########################
sub getAccessToken {
    return $_[0]->{token}->{access_token};
}

sub getRefreshToken {
    return $_[0]->{token}->{refresh_token};
}


=head1 NAME

B<Net::Google::OAuth> - Simple Google oauth api module

=head1 SYNOPSIS

This module get acess_token and refresh_token from google oath
    use Net::Google::OAuth;

    #Create oauth object. You need set client_id and client_secret value. Client_id and client_secret you can get on google, when register your app.
    my $oauth = Net::Google::OAuth->new(
                                            -client_id          => $CLIENT_ID,
                                            -client_secret      => $CLIENT_SECRET,
                                         );
    #Generate link with request access token. This link you must copy to your browser and run.
    $oauth->generateAccessToken(
                                    -scope      => 'drive',
                                    -email      => 'youremail@gmail.com',
                                    );
    print "Access token: ", $oauth->getAccessToken(), "\n";
    print "Refresh token: ", $oauth->getRefreshToken, "\n";

=head1 METHODS

=head2 new(%opt)

Create L<Net::Google::OAuth> object

    %opt:
        -client_id          => Your app client id (Get from google when register your app)
        -client_secret      => Your app client secret (Get from google when register your app)

=head2 generateAccessToken(%opt)

Generate link with request access token This link you must copy to your browser and go it. Redirect answer you must copy to console. Return 1 if success, die in otherwise

    %opt
        -scope              => Request access to scope (e.g. 'drive')
        -email              => Your gmail email

=head2 refreshToken(%opt)

Get access token through refresh_token. Return 1 if success, die in otherwise

    %opt:
        -refresh_token      => Your refresh token value (you can get refresh token after run method generateAccessToken() via getter getRefreshToken())

=head2 getTokenInfo(%opt)

Get info about access token (access_type, audience, expires_in, issued_to, scope). Return hashref of result or die in otherwise

    %opt:
        -access_token       => Value of access_token (default use value returned by method getRefreshToken())
    Example:
        my $token_info = $oauth->getTokenInfo( -access_token => $access_token );
        $token_info:
            {
                access_type   "offline",
                audience      "593952972427-e6dr18ua0leurrjt1num.apps.googleusercontent.com",
                expires_in    3558,
                issued_to     "593952972427-e6dr18ua0leurrjtum.apps.googleusercontent.com",
                scope         "https://www.googleapis.com/auth/drive"
            }


=head2 getAccessToken()

Return access token value

=head2 getRefreshToken()

Return refresh token value

=head1 DEPENDENCE

L<LWP::UserAgent>, L<JSON::XS>, L<URI>, L<HTTP::Request>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
