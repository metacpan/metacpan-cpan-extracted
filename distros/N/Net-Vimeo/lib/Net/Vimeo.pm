package Net::Vimeo;

use Carp;
use Clone qw( clone );
use HTTP::Request;
use JSON qw( decode_json );
use Moose;
use Net::OAuth;

use namespace::autoclean;

with 'Net::Vimeo::OAuth';

our $VERSION = '0.000004';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my $api_urls = {
        api_url  => "http://vimeo.com/api/rest/v2",
    };

    return { %$api_urls, %$args };
};


has 'api_url' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    reader      => { api_url => sub { URI->new(shift->{api_url}) } },
);

sub make_api_request {
    my ( $self, $method, $params  ) = @_;

    croak 'You need to authorize your app before making api requests'
        unless ($self->access_token && $self->access_token_secret );

    # API request expects a method ... just check if the method argument is
    # defined
    carp "API method must be present in arguments( eq: method => 'vimeo.activity.userDid')" && return 
        unless ( $params->{method} );

    my $api_req = $self->_api_request($method || 'GET', $params, 'protected resource');
    my $res = $self->user_agent->send_request($api_req);

    return $res;
}

sub _api_request {
    my ( $self, $method, $params, $type ) = @_;

    my $http_request;

    if ( $method eq 'GET' ) {
        # Build url for request
        my $uri = $self->get_uri_for_request($params);

        $http_request = HTTP::Request->new($method, $uri);
    } 
    elsif ( $method eq 'POST' ) {
        $http_request = POST($self->api_url, Content => $self->_query_string_for($params));
    } 
    else {
        croak sprintf( "Unknown HTTP method %s", $method );
    }

    $self->apply_headers( $http_request, $type, $params );

    return $http_request;
}

sub apply_headers {
    my ( $self, $req, $type, $params ) = @_;

    return 
        unless ( $self->access_token && $self->access_token_secret );

    local $Net::OAuth::SKIP_UTF8_DOUBLE_ENCODE_CHECK = 1;

    my $uri = $req->uri->clone;

    my $request = $self->make_oauth_request(
        $type,
        request_url    => $uri,
        request_method => $req->method,
        token          => $self->access_token,
        token_secret   => $self->access_token_secret,
        %$params,
    );

    $req->header(authorization => $request->to_authorization_header);
}

sub _encode_args {
    my ( $self, $args ) = @_;

    return { map { utf8::upgrade($_) unless ref($_); $_ } %$args };
}

sub _query_string_for {
    my ( $self, $args ) = @_;

    my @pairs;
    while ( my ($k, $v) = each %$args ) {
        push @pairs, join '=', map URI::Escape::uri_escape_utf8($_,'^\w.~-'), $k, $v;
    }

    return join '&', @pairs;
}

sub get_uri_for_request {
    my ( $self, $params ) = @_;

    my $cloned_params = clone $params;
    $self->_encode_args($cloned_params);

    my $uri = $self->api_url;
    $uri->query($self->_query_string_for($cloned_params));

    return $uri;
}

sub return_content {
    my ( $self, $req ) = @_;

    croak "No request for content retrieving" 
        unless $req;

    return decode_json( $req->content );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Net::Vimeo - Make requests via OAuth to Vimeo Advanced API

=head1 VERSION

Version 0.000004

=head1 SYNOPSIS

    use Net::Vimeo;

    my $vimeo = Net::Vimeo->new( consumer_key => 'xxxx', consumer_secret => 'yyyy' );
    
    # First you need to get the authorization URL
    # If you need permission to upload a video, send the 
    # permission parameter, otherwise you will only have read permission
    my $vimeo_oauth_url = $vimeo_oauth->get_authorization_url( permission => 'write' );

    # Get the oauth_verifier from that url and
    # exchange the request tokens with access tokens
    $vimeo->get_access_token( { verifier => 'oauth_verifier' } );

    # Now you are authorized....you can start playing
    my $request_params = {
        method      => 'vimeo.activity.userDid',
        user_id     => 'someuserid',
        page        => 1,
        per_page    => 10,
        format      => 'json',
    };

    my $result = $vimeo->make_api_request( 'GET', $request_params);

The canonical documentation for the Advanced API is at L<http://developer.vimeo.com/apis/advanced>
with the method listing residing at L<http://developer.vimeo.com/apis/advanced/methods>

The distribution has a simple example bundled, and make sure to study the tests and
L<Net::Vimeo::OAuth> for further insight into the overall process of authentication.

=head1 CONSTRUCTOR

    my $vimeo = Net::Vimeo->new(
        consumer_key    => 'xxxx',
        consumer_secret => 'yyyy',
        access_token    => 'zzzz',  # optional
        access_token_secret => 'zzzz_secret' # optional
    );

On construction, consumer_key and consumer_secret are mandatory to identify your app 
against Vimeo. In case you want your app to be "statically" provided with an access_token,
you may set one on construction, but you'll commonly use the methods around get_access_token()
to ask a user for access so your app can act on behalf of granting users. See L<Net::Vimeo::OAuth>
for the underlying mechanism.

=head1 METHODS

=over 4

=item get_authorization_url( permission => $scope );

Returns a Vimeo URL (L<URI>-Object) which you will use to send a user to a
page (on Vimeo) where she may accept or decline that your app receives
access to her account. Acceptance means the user issues an access_token
for your app, an alphanumeric string.

=item make_api_request($method, $request_params)

After you have your access tokens via OAuth you can start
making requests to Vimeo Advanced API. Arguments necessary to make the call
to Vimeo Advanced API are: C<$method> which is a string representing the HTTP
method needed for your request. The second one is the api request params, you can 
find the needed params on Vimeo Advanced API documentation.

    $vimeo->make_api_request( 'GET', $request_params);

=back

=head1 AUTHOR

Mirela Iclodean, C<< <imirela at cpan.org> >>

=head1 SEE ALSO

L<Net::Vimeo::OAuth>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-vimeo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Vimeo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Vimeo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Vimeo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Vimeo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Vimeo>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Vimeo/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Mirela Iclodean.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). 

