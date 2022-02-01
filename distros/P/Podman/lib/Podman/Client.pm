package Podman::Client;

##! API connection client.
##!
##!     my $Client = Podman::Client->new(
##!         Connection => 'http+unix:///run/user/1000/podman/podman.sock',
##!         Timeout       => 1800,
##!     );
##!
##!     my $Response = $Client->Get(
##!         'version',
##!         Parameters => {},
##!         Headers    => {},
##!     );

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

### API connection Url. Possible connections are via UNIX socket (default) or
### tcp connection.
###
###     * http+unix
###     * http
###     * https
has 'Connection' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_BuildConnection',
);

### API connection timeout, default `3600 seconds`.
has 'Timeout' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { return 3600 },
);

### API connection object.
has 'UserAgent' => (
    is       => 'ro',
    isa      => 'Mojo::UserAgent',
    lazy     => 1,
    builder  => '_BuildUserAgent',
    init_arg => undef,
);

### API request Url depends on connection Url and Podman service version.
has 'RequestBase' => (
    is       => 'ro',
    isa      => 'Mojo::URL',
    builder  => '_BuildRequestBase',
    init_arg => undef,
);

sub _BuildConnection {
    my $Self = shift;

    return sprintf "http+unix://%s/podman/podman.sock",
      $ENV{XDG_RUNTIME_DIR} ? $ENV{XDG_RUNTIME_DIR} : '/tmp';
}

sub _BuildRequestBase {
    my $Self = shift;

    my $Scheme = Mojo::URL->new( $Self->Connection )->scheme();

    my $RequestBaseUrl =
      $Scheme eq 'http+unix' ? 'http://d/' : $Self->Connection;

    my $Transaction;
    my $Tries = 3;
    while ( $Tries-- ) {
        $Transaction = $Self->UserAgent->get(
            Mojo::URL->new($RequestBaseUrl)->path('version') );
        last if $Transaction->res->is_success;
    }
    return Podman::Exception->new( Code => 0, )->throw()
      if !$Transaction->res->is_success;

    my $JSON = $Transaction->res->json;
    my $Path = sprintf "v%s/libpod/", $JSON->{Version};

    return Mojo::URL->new($RequestBaseUrl)->path($Path);
}

sub _BuildUserAgent {
    my $Self = shift;

    my $UserAgent = Mojo::UserAgent->new(
        connect_timeout    => 10,
        inactivity_timeout => $Self->Timeout,
        insecure           => 1,
    );
    $UserAgent->transactor->name( sprintf "podman-perl/%s", $Podman::VERSION );

    my $Connection = Mojo::URL->new( $Self->Connection );
    my $Scheme     = $Connection->scheme();

    if ( $Scheme eq 'http+unix' ) {
        my $Path = Mojo::Util::url_escape( $Connection->path() );
        $UserAgent->proxy->http( sprintf "%s://%s", $Scheme, $Path );
    }

    return $UserAgent;
}

sub _MakeUrl {
    my ( $Self, $Path, $Parameters ) = @_;

    my $Url = Mojo::URL->new( $Self->RequestBase )->path($Path);

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

### Send API get request to path with optional parameters and headers.
sub Get {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        GET => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );
    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

### Send API post request to path with optional parameters, headers and
### data.
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

### Send API delete request to path with optional parameters and headers.
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
