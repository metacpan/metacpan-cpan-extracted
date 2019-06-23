package Net::Google::WebmasterTools::OAuth2;
{
  $Net::Google::WebmasterTools::OAuth2::VERSION = '0.03';
}
use strict;

# ABSTRACT: OAuth2 for Google Webmaster Tools API

use JSON;
use LWP::UserAgent;
use URI;

sub new {
    my $class = shift;
    my $self  = { @_ };

    die("client_id missing")     if !$self->{client_id};
    die("client_secret missing") if !$self->{client_secret};

    $self->{redirect_uri} ||= 'urn:ietf:wg:oauth:2.0:oob';

    return bless($self, $class);
}

sub authorize_url {
    my $self = shift;

    my $uri = URI->new('https://accounts.google.com/o/oauth2/auth');
    $uri->query_form(
        response_type => 'code',
        client_id     => $self->{client_id},
        redirect_uri  => $self->{redirect_uri},
        scope         => 'https://www.googleapis.com/auth/webmasters.readonly',
    );

    return $uri->as_string;
}

sub get_access_token {
    my ($self, $code) = @_;

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->post('https://accounts.google.com/o/oauth2/token', [
        code          => $code,
        client_id     => $self->{client_id},
        client_secret => $self->{client_secret},
        redirect_uri  => $self->{redirect_uri},
        grant_type    => 'authorization_code',
    ]);

    die('error getting token: ' . $res->status_line) unless $res->is_success;

    return from_json($res->decoded_content);
}

sub refresh_access_token {
    my ($self, $refresh_token) = @_;

    my $ua = LWP::UserAgent->new;
    my $res = $ua->post('https://accounts.google.com/o/oauth2/token', [
        refresh_token => $refresh_token,
        client_id     => $self->{client_id},
        client_secret => $self->{client_secret},
        grant_type    => 'refresh_token',
    ]);

    die('error getting token: ' . $res->status_line) unless $res->is_success;

    return from_json($res->decoded_content);
}

sub interactive {
    my $self = shift;

    my $url = $self->authorize_url;

    print(<<"EOF");
Please visit the following URL, grant access to this application, and enter
the code you will be shown:

$url

EOF

    print("Enter code: ");
    my $code = <STDIN>;
    chomp($code);

    print("\nUsing code: $code\n\n");

    my $res = $self->get_access_token($code);

    print("Access token:  ", $res->{access_token},  "\n");
    print("Refresh token: ", $res->{refresh_token}, "\n");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::WebmasterTools::OAuth2 - OAuth2 for Google Webmaster Tools API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Net::Google::WebmasterTools;
    use Net::Google::WebmasterTools::OAuth2;

    my $client_id     = "123456789012.apps.googleusercontent.com";
    my $client_secret = "rAnDoMsEcReTrAnDoMsEcReT";
    my $refresh_token = "RaNdOmSeCrEtRaNdOmSeCrEt";

    my $analytics = Net::Google::WebmasterTools->new;

    # Authenticate
    my $oauth = Net::Google::WebmasterTools::OAuth2->new(
        client_id     => $client_id,
        client_secret => $client_secret,
    );
    my $token = $oauth->refresh_access_token($refresh_token);
    $analytics->token($token);

=head1 DESCRIPTION

OAuth2 class for L<Net::Google::WebmasterTools> web service.

=head1 NAME

Net::Google::WebmasterTools::OAuth2 - OAuth2 for Google WebmasterTools API

=head1 VERSION

version 0.03

=head1 CONSTRUCTOR

=head2 new

    my $oauth = Net::Google::WebmasterTools::OAuth2->new(
        client_id     => $client_id,      # required
        client_secret => $client_secret,  # required
        redirect_uri  => $redirect_uri,
    );

Create a new object. Use the client id and client secret from the Google APIs
Console. $redirect_uri is optional and defaults to 'urn:ietf:wg:oauth:2.0:oob'
for installed applications.

=head1 METHODS

=head2 authorize_url

    my $url = $oauth->authorize_url;

Returns a Google URL where the user can authenticate, authorize the
application and retrieve an authorization code.

=head2 get_access_token

    my $token = $oauth->get_access_token($code);

Retrieves an access token and a refresh token using an authorization code.
Returns a hashref with the following entries:

=head3 access_token

=head3 refresh_token

=head3 expires_in

=head3 token_type

=head2 refresh_access_token

    my $token = $oauth->refresh_access_token($refresh_token);

Retrieves a new access token using a refresh token. Returns a hashref with the
following entries:

=head3 access_token

=head3 expires_in

=head3 token_type

=head2 interactive

    $oauth->interactive;

Obtain and print an access and refresh token interactively using the console.
The user is prompted to visit a Google URL and enter a code from that page.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Hammond <contact@rjh.am>, Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
