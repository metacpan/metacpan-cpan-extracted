use strict;
use warnings;

# ABSTRACT: simple wrapper for google+ OAuth2 API

=head1 NAME

OAuth2::Google::Plus

=head1 DESCRIPTION

This is an implementation of the google OAuth2 API. It's a rather specific
implementation of this specific OAuth2 provider. Small implementation details
differ per provider, this module attempts to abstract and document the Google version.

=head1 SYNOPSYS

    use OAuth2::Google::Plus;

    my $plus = OAuth2::Google::Plus->new(
        client_id       => 'CLIENT ID',
        client_secret   => 'CLIENT SECRET',
        redirect_uri    => 'http://my.app.com/authorize',
    );

    # generate the link for signup
    my $uri = $plus->authorization_uri( redirect_url => $url_string )

    # callback returns with a code in url
    my $access_token = $plus->authorize( $request->param('code') );

    # store $access_token somewhere safe...

    # use $authorization_token
    my $info = OAuth2::Google::Plus::UserInfo->new( access_token => $access_token );

=over

=item authorization_uri

Construct an URI object for authorization. This url should be use to provide a login
button to the user

=item authorize ( authorization_code => $code )

Use an authorization_token to retrieve an access_token from google. This access token
can be used to retrieve information about the user who authorized.

=back

=cut

{
    package OAuth2::Google::Plus;
    use Moo;
    use MooX::late;

    use Carp::Assert;
    use JSON qw|decode_json|;
    use LWP::UserAgent;
    use URI;

    sub ENDPOINT_URL {
        return 'https://accounts.google.com/o/oauth2';
    }

    has client_id => (
        is      => 'ro',
        isa     => 'Str',
        required => 1,
    );

    has client_secret => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has scope => (
        is       => 'ro',
        isa      => 'Str',
        default  => 'https://www.googleapis.com/auth/userinfo.email',
        required => 1,
    );

    has state => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
    );

    has redirect_uri => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has response => (
        is  => 'ro',
        writer => '_set_response',
    );

    has _endpoint => (
        is => 'ro',
        lazy_build => 1,
    );

    sub _build__endpoint {
        return OAuth2::Google::Plus::ENDPOINT_URL();
    }

    sub authorization_uri {
        my ( $self ) = @_;

        my $uri = URI->new( $self->_endpoint . '/auth' );

        $uri->query_form(
            access_type     => 'offline',
            approval_prompt => 'force',
            client_id       => $self->client_id,
            redirect_uri    => $self->redirect_uri,
            response_type   => 'code',
            scope           => $self->scope,
            ($self->state ? (state           => $self->state) : ()),
        );

        return $uri;
    }

    sub authorize {
        my ( $self, %params ) = @_;

        assert( $params{authorization_code}, 'missing named argument "authorization_code"');

        my $uri = URI->new( $self->_endpoint . '/token' );
        my $ua  = LWP::UserAgent->new;

        my $response = $ua->post( $uri, {
            client_id       => $self->client_id,
            client_secret   => $self->client_secret,
            code            =>  $params{authorization_code},
            grant_type      => 'authorization_code',
            redirect_uri    => $self->redirect_uri,
            scope           => $self->scope,
        });

        $self->_set_response( $response );

        if( $response->is_success ){
            my $json     = decode_json( $response->content );
            return $json->{access_token};
        }

        return;
    }
}

1;
