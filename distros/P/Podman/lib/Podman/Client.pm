package Podman::Client;

use strict;
use warnings;
use utf8;

use Moose;

use Try::Tiny;
use Readonly;

use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::JSON ();
use Mojo::UserAgent;
use Mojo::Util ();
use Mojo::URL;

Readonly::Scalar my $VERSION => '20220124.0';

use Podman;
use Podman::Exception;

has 'ConnectionURI' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_BuildConnectionURI',
);

has 'Timeout' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { return 3600 },
);

has 'UserAgent' => (
    is       => 'ro',
    isa      => 'Mojo::UserAgent',
    lazy     => 1,
    builder  => '_BuildUserAgent',
    init_arg => undef,
);

has 'BaseURI' => (
    is       => 'ro',
    isa      => 'Mojo::URL',
    lazy     => 1,
    builder  => '_BuildBaseURI',
    init_arg => undef,
);

sub BUILD {
    my $Self = shift;

    $Self->ConnectionURI;
    $Self->UserAgent;
    $Self->BaseURI;

    return;
}

sub _BuildConnectionURI {
    my $Self = shift;

    return sprintf "http+unix://%s/podman/podman.sock",
      $ENV{XDG_RUNTIME_DIR} ? $ENV{XDG_RUNTIME_DIR} : '/tmp';
}

sub _BuildBaseURI {
    my $Self = shift;

    my $Scheme = Mojo::URL->new( $Self->ConnectionURI )->scheme();

    my $BaseURI =
      $Scheme eq 'http+unix' ? 'http://d/' : $Self->ConnectionURI;

    my $Transaction;
    my $Tries = 3;
    while ( $Tries-- ) {
        $Transaction = $Self->UserAgent->get(
            Mojo::URL->new($BaseURI)->path('version') );
        last if $Transaction->res->is_success;
    }
    return Podman::Exception->new( Code => 0, )->throw()
      if !$Transaction->res->is_success;

    my $JSON = $Transaction->res->json;
    my $Path = sprintf "v%s/libpod/", $JSON->{Version};

    return Mojo::URL->new($BaseURI)->path($Path);
}

sub _BuildUserAgent {
    my $Self = shift;

    my $UserAgent = Mojo::UserAgent->new(
        connect_timeout    => 10,
        inactivity_timeout => $Self->Timeout,
        insecure           => 1,
    );
    $UserAgent->transactor->name( sprintf "podman-perl/%s", $Podman::VERSION );

    my $ConnectionURI = Mojo::URL->new( $Self->ConnectionURI );
    my $Scheme     = $ConnectionURI->scheme();

    if ( $Scheme eq 'http+unix' ) {
        my $Path = Mojo::Util::url_escape( $ConnectionURI->path() );
        $UserAgent->proxy->http( sprintf "%s://%s", $Scheme, $Path );
    }

    return $UserAgent;
}

sub _MakeUrl {
    my ( $Self, $Path, $Parameters ) = @_;

    my $Url = Mojo::URL->new( $Self->BaseURI )->path($Path);

    if ($Parameters) {
        $Url->query($Parameters);
    }

    return $Url;
}

sub _HandleTransaction {
    my ( $Self, $Transaction ) = @_;

    if ( !$Transaction->res->is_success ) {
        return Podman::Exception->new( Code => $Transaction->res->code )
          ->throw();
    }

    my $Content =
      ( lc $Transaction->res->headers->content_type || '' ) eq
      'application/json'
      ? $Transaction->res->json
      : $Transaction->res->body;

    return $Content;
}

sub Get {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        GET => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );
    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

sub Post {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        POST => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );

    my $Data = $Options{Data};
    if ( $Data && ref $Data eq 'File::Temp' ) {
        $Transaction->req->content->asset(
            Mojo::Asset::File->new( path => $Data->filename ) );
    }
    else {
        $Transaction->req->content->asset(
            Mojo::Asset::Memory->new->add_chunk(
                Mojo::JSON::encode_json($Data)
            )
        );
    }

    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

sub Delete {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        Delete => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );
    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Client - API client.

=head1 SYNOPSIS

    # Connect to service
    my $Client = Podman::Client->new(
        ConnectionURI => 'http+unix:///run/user/1000/podman/podman.sock',
        Timeout       => 1800,
    );

    # Send GET request
    my $Response = $Client->Get(
        'version',
        Parameters => {},
        Headers    => {},
    );

=head1 DESCRIPTION

L<Podman::Client> is a HTTP client (user agent) based on L<Mojo::UserAgent>
with the needed support to connect to and query the L<http://podman.io> API.

=head1 ATTRIBUTES

=head2 ConnectionURI

    my $Client = Podman::Client->new( ConnectionURI => 'https://127.0.0.1:1234' );

URI to L<http://podman.io> API service, defaults to user UNIX domain socket,
e.g. C<http+unix://run/user/1000/podman/podman.sock>

=head2 Timeout

    my $Client = Podman::Client->new( Timeout => 1800 );

Maximum amount of time in seconds a connection can be inactive before getting
closed, defaults to C<3600s>. Setting the value to C<0> will allow connections
to be inactive indefinitely.

=head1 METHODS

L<Podman::Client> provides the valid HTTP requests to query the
L<Podman::Client> API. All methods take a relative endpoint path and optional
header parameters and path parameters. if the response has a HTTP code unequal
C<2xx> a L<Podman::Exception> is raised.

=head2 Get

    my $Response = $Client->Get('version');

Perform C<GET> request and return resulting content (hash, array or binary
data).

=head2 Delete

    my $Response = $Client->Delete('images/docker.io/library/hello-world');

Perform C<DELETE> request and return resulting content (hash, array).

=head2 Post

    my $Response = $Client->Post(
        'build',
        Data       => $FieHandle,
        Parameters => {
            'file' => 'Dockerfile',
            't'    => 'localhost/goodbye',
        },
        Headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

Perform C<POST> request and return resulting content (hash, array), takes
additional optional request data (hash, array or filehandle).

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
