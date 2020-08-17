package RestAPI;
use v5.18;
our $VERSION = "0.12";
use Moo;
no warnings 'experimental';
use Types::Standard         qw( Any HashRef Bool Str Int );
use namespace::autoclean;
use XML::Simple             qw( XMLin XMLout );
use JSON::XS ();
use LWP::UserAgent ();
use Time::HiRes             qw( gettimeofday tv_interval );

# Basic construction params
has 'server'    => ( is => 'rw', isa => Str );
has 'port'      => ( is => 'rw', isa => Int );
has 'ssl_opts'  => ( is => 'rw', isa => HashRef );
has 'basicAuth' => ( is => 'rw', isa => Bool);
has ['realm', 'username', 'password', 'scheme'] => ( is => 'rw' );
has 'timeout'   => ( is => 'rw', isa => Int );

# Added construction params
has 'headers'   => ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'query'     => ( is => 'rw', isa => Str );
has 'path'      => ( is => 'rw', isa => Str, trigger => \&_set_request );
has 'q_params'  => ( is => 'rw', isa => HashRef, default => sub {{}}, trigger => \&_set_q_params );
has 'http_verb' => ( is => 'rw', isa => Str, default => 'GET' );
has 'payload'   => ( is => 'rw', isa => Any, trigger => \&_set_payload );
has 'encoding'  => ( is => 'rw', isa => Str );

# other objects
has 'req'        => ( is => 'ro', writer => '_set_req' );
has 'req_params' => ( is => 'ro', writer => '_set_req_params');
has 'ua'         => ( is => 'rw', writer => '_set_ua' );
has 'jsonObj'    => ( is => 'ro', default => sub { 
        return JSON::XS->new
                ->utf8
                ->allow_nonref
                ->convert_blessed;
} );
has 'raw'        => ( is => 'ro', writer => '_set_raw' );
has 'response'   => ( is => 'ro', writer => '_set_response' );
has 'metrics'    => ( is => 'ro', isa => HashRef, default => sub { {} } );

# encodes the payload if not encoded already
sub _set_payload {
    my $self = shift;
    if ( ref $self->payload ) {
        my $str;
        for ( $self->encoding ) {
            when ( m|xml| ) {
                $str = XMLout( $self->payload );
            }
            when ( m|json| ) {
                $str = $self->jsonObj->encode( $self->payload );
            }
        }
        $self->payload( $str );
    }
}

sub BUILD {
    my $self = shift;
    $self->_set_ua( LWP::UserAgent->new(
        ssl_opts => $self->ssl_opts,
        timeout  => $self->timeout,
        agent    => 'RestAPI/0.0.8',
    ));

    $self->server( "$self->{server}:$self->{port}" ) if ( $self->{server} && $self->{port} );

    if ( $self->basicAuth ) {
        $self->ua->credentials( 
            $self->server, 
            $self->realm, 
            $self->username, 
            $self->password 
        );
    }

    if ( $self->scheme ) {
        $self->server($self->scheme . '://' . $self->server);
    } 
}

sub _set_q_params {
    my $self = shift;
    return unless keys %{$self->q_params};
    my $q_params;
    while ( my ( $k, $v ) = each %{$self->q_params} ) {
        $q_params .= '&'."$k=$v";
    }
    $self->_set_req_params( substr( $q_params, 1, length($q_params) - 1 ) );
}

sub _set_request {
    my $self = shift;

    my $url;
    $url = $self->server if ( $self->{server} );

    if ( $self->query ) {
        $self->{query} = '/'.$self->{query} if ( $url && $self->{query} !~ m|^/|);
        $url .= $self->query;
    }

    if ( $self->path ) {
        $self->{path} = '/'.$self->{path} unless ( $self->{path} =~ m|^/| );
        $url .= $self->path;
    }

    $url .= '?'.$self->req_params if ($self->req_params);

    my $h = HTTP::Headers->new;
    $h->content_type($self->encoding) if ( $self->encoding );

    while ( my ( $k, $v ) = each( %{$self->headers} ) ) {
        $h->header( $k, $v );
    }

    $self->_set_req( HTTP::Request->new( $self->http_verb, $url, $h, $self->payload ) );
}

sub do {
    my $self = shift;

    $self->_set_request();

    my %headers;
    my $t0 = [gettimeofday];
    $self->_set_response( $self->ua->request( $self->req ) );
    $self->{metrics}->{'response_time'} = tv_interval( $t0, [gettimeofday] );

    die "Error: ".$self->response->status_line
        unless ( $self->response->is_success );

    %headers = $self->response->flatten();
    $self->_set_raw( $self->response->decoded_content );
    if ( exists $headers{'Content-Transfer-Encoding'} &&
        $headers{'Content-Transfer-Encoding'} eq 'binary' ) {
        return $self->raw;
    }
     
    my $r_encoding = $self->response->header("Content_Type")
        or return $self->raw;

    my $outObj;
    for ( $r_encoding ) {
        when ( m|application/xml| ) {
            if ( $self->raw =~ /^<\?xml/ ) {
                $outObj = XMLin( $self->raw );
            } else {
                $outObj = $self->raw;
            }
        }
        when ( m|application/json| ) {
            $outObj = $self->jsonObj->decode( $self->raw );
        }
        when ( m|text| ) {
            $outObj = $self->raw;
        }
    }
    return $outObj;
}

__PACKAGE__->meta->make_immutable;

__END__

#===============================================================================

=head1 NAME

RestAPI - a base module to interact with a REST API interface

=head1 VERSION

Version 0.09


=head1 SYNOPSIS

    use RestAPI;

    # a REST GET request
    my $client = RestAPI->new(
        basicAuth   => 1,
        realm       => "Some Realm",
        ssl_opts    => { verify_hostname => 0 },
        username    => "foo",
        password    => "bar",
        timeout     => 10,      # in secs
        scheme      => 'https', # if missing it is assumed comprised in the server or in the query
        server      => '...',
        query       => '...',   # (maybe fixed) request part
        path        => '...',   # added alongside the request
        q_params    => { foo => bar },
        headers     => { k => 'v' },
        http_verb   => 'GET',            # any http verb...
        encoding    => 'application/xml' # or whatever...
    );

    # a REST POST request
    my $client = RestAPI->new(
        basicAuth   => 1,
        realm       => "Some Realm",
        username    => "foo",
        password    => "bar",
        scheme      => 'https',
        timeout     => 10,      # in secs
        server      => '...',
        query       => '...',
        path        => '...',
        q_params    => { foo => bar },
        http_verb   => 'POST',
        payload     => '...',
        encoding    => 'application/xml'
    );

    # a REST UPDATE request
    my $client = RestAPI->new(
        basicAuth   => 1,
        realm       => "Some Realm",
        username    => "foo",
        password    => "bar",
        scheme      => 'https',
        timeout     => 10,      # in secs
        server      => '...',
        query       => '...',
        path        => '...',
        q_params    => { foo => bar },
        http_verb   => 'PUT',
        payload     => '...',
        encoding    => 'application/xml'
    );

    # a REST DELETE request
    my $client = RestAPI->new(
        basicAuth   => 1,
        realm       => "Some Realm",
        username    => "foo",
        password    => "bar",
        scheme      => 'https',
        timeout     => 10,      # in secs
        server      => '...',
        query       => '...',
        path        => '...',
        q_params    => { foo => bar },
        http_verb   => 'DELETE',
        encoding    => 'application/xml'
    );

    try {
        my $response_data = $client->do();

        # $self->response is the HTTP::Response object
        # you get back from your request...
        my %response_headers = $client->response->flatten();
    } catch {
        die "Error performing request, status line: $!\n";
    }

    my $raw_response = $client->raw();  # the raw response.

=head1 EXPORT

None

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at sky.uk> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RestAPI


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of Perl itself.

=cut

#===============================================================================
