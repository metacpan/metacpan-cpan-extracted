package Mojo::AWS;
use Mojo::Base -base;
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex sha256_hex);
use Mojo::Util qw(url_escape);
use Scalar::Util 'blessed';

our $VERSION = '0.10';

has service    => '';
has region     => '';
has access_key => '';
has secret_key => '';
has transactor => '';

sub request_method {
    uc pop;
}

sub canonical_uri {
    my $path = join '/' => map { url_escape $_ } split /\// => pop->path;
    $path .= '/';
    return $path;
}

sub canonical_query_string {
    my $url = pop;

    my @cqs   = ();
    my $names = $url->query->names;
    for my $name (@$names) {
        my $values = $url->query->every_param($name);

        ## FIXME: we assume a lexicographical sort. I don't know how
        ## FIXME: AWS prefers to sort numerical values and couldn't
        ## FIXME: find any guidance on that
        for my $val (sort { $a cmp $b } @$values) {
            push @cqs, join '=', url_escape($name) => url_escape($val);
        }
    }

    return join '&' => @cqs;
}

sub canonical_headers {
    my $headers = Mojo::Headers->new->from_hash(pop // {});

    my @headers = ();
    my $names   = $headers->names;
    for my $name (sort { lc($a) cmp lc($b) } @$names) {
        my $values = $headers->every_header($name);

        my $value
          = join ',' => map { s/ +/ /g; $_ } map { s/\s+$//; $_ } map { s/^\s*//; $_ } @$values;

        push @headers, lc($name) . ':' . $value;
    }

    my $response = join "\n" => @headers;
    return $response . "\n";
}

sub signed_headers {
    ## FIXME: ensure 'host' (http/1.1) or ':authority' (http/2) header is present
    ## FIXME: ensure date or 'x-amz-date' is present and in iso 8601 format
    return join ';' => sort map { lc $_ } @{pop()};
}

sub hashed_payload {
    return lc sha256_hex(pop);
}

sub canonical_request {
    my $self = shift;
    my %args = @_;
    my $url  = Mojo::URL->new($args{url});

    my $creq = join "\n" => $self->request_method($args{method}),
      $self->canonical_uri($url), $self->canonical_query_string($url),
      $self->canonical_headers($args{headers}), $self->signed_headers($args{signed_headers}),
      $self->hashed_payload($args{payload});

    return $creq;
}

sub canonical_request_hash {
    return lc sha256_hex(pop);
}

sub aws_algorithm {
    return 'AWS4-HMAC-SHA256';
}

sub aws_datetime {
    (my $date = Mojo::Date->new(pop)->to_datetime) =~ s/[^0-9TZ]//g;
    return $date;
}

sub aws_date {
    my $self = shift;
    (my $date = $self->aws_datetime(pop)) =~ s/^(\d+)T.*/$1/;
    return $date;
}

sub aws_credentials {
    my $self = shift;
    my %args = @_;

    return join '/' => $self->aws_date($args{datetime}),
      $self->region, $self->service, 'aws4_request';
}

sub string_to_sign {
    my $self = shift;
    my %args = @_;

    my $string = join "\n" => $self->aws_algorithm,
      $self->aws_datetime($args{datetime}),
      $self->aws_credentials(
        datetime => $args{datetime},
        region   => $self->region,
        service  => $self->service
      ),
      $args{hash};

    return $string;
}

sub signing_key {
    my $self = shift;
    my %args = @_;

    my $date     = $self->aws_date($args{datetime});
    my $kDate    = hmac_sha256($date, 'AWS4' . $self->secret_key);
    my $kRegion  = hmac_sha256($self->region, $kDate);
    my $kService = hmac_sha256($self->service, $kRegion);
    my $kSigning = hmac_sha256('aws4_request', $kService);

    return $kSigning;
}

sub signature {
    my $self = shift;
    my %args = @_;

    my $digest = hmac_sha256_hex($args{string_to_sign}, $args{signing_key});

    return $digest;
}

sub authorization_header {
    my $self = shift;
    my %args = @_;

    my $algorithm      = $self->aws_algorithm;
    my $access_key     = $self->access_key;
    my $credential     = $args{credential_scope};
    my $signed_headers = join ';' => map {lc} @{$args{signed_headers}};
    my $signature      = $args{signature};
    my $headers
      = Mojo::Headers->new->authorization(
        "$algorithm Credential=$access_key/$credential, SignedHeaders=$signed_headers, Signature=$signature"
      );

    return $headers;
}

sub signed_request {
    my $self = shift;
    my %args = @_;

    ## FIXME: more guards
    die "Parameter 'method' required.\n" unless $args{method};
    die "Parameter 'url' required.\n" unless $args{url};
    die "Parameter 'url' must be a Mojo::URL object\n" if !blessed $args{url} || blessed $args{url} ne 'Mojo::URL';

    ## FIXME: Is it possible that x-amz-date and Date differ if they are
    ## FIXME: created across a second?

    ## FIXME (disposable build_tx): is there a better way to build a request body?
    my $payload
      = $self->transactor->tx($args{method} => $args{url}, @{$args{payload}})->req->body;

    ## build a normal transaction
    my $headers = Mojo::Headers->new->from_hash(
        {
            'Host'                 => $args{url}->host,
            'x-amz-content-sha256' => $self->hashed_payload($payload),
            'x-amz-date'           => $self->aws_datetime($args{datetime}),
            %{$args{signed_headers} // {}}
        },
    );

    ## build the authorization header
    my $signed_headers = [sort map {lc} @{$headers->names}];

    my $aws_credentials = $self->aws_credentials(
        datetime => $args{datetime},
        region   => $self->region,
        service  => $self->service
    );

    my $aws_signing_key = $self->signing_key(
        secret   => $self->secret_key,
        datetime => $args{datetime},
        region   => $self->region,
        service  => $self->service
    );

    my $canonical_request = $self->canonical_request(
        url            => $args{url},
        method         => $args{method},
        headers        => $headers->to_hash,
        signed_headers => $signed_headers,
        payload        => $payload,
    );

    my $canonical_request_hash = $self->canonical_request_hash($canonical_request);

    my $string_to_sign = $self->string_to_sign(
        datetime => $args{datetime},
        region   => $self->region,
        service  => $self->service,
        hash     => $canonical_request_hash,
    );

    my $signature
      = $self->signature(signing_key => $aws_signing_key, string_to_sign => $string_to_sign);

    my $auth_header = $self->authorization_header(
        access_key       => $self->access_key,
        credential_scope => $aws_credentials,
        signed_headers   => $signed_headers,
        signature        => $signature,
    );

    $headers->add(%{$args{headers}}) if $args{headers};
    $headers->add(Authorization => $auth_header->authorization);
    my $tx
      = $self->transactor->tx($args{method}, $args{url}, $headers->to_hash, @{$args{payload}});

    return $tx;
}

1;
