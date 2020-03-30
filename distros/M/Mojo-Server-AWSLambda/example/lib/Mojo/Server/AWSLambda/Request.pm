package Mojo::Server::AWSLambda::Request;


use Mojo::Base 'Mojo::Message::Request';
use MIME::Base64;

sub parse {
    my ($self, $env) = @_;
    $self->_parse_env($env);
    return $self;
}

sub _parse_env {
    my ($self, $payload) = @_;

    my $url = $self->url;

    $self->method($payload->{httpMethod});
    $url->scheme('http');
    $url->path($payload->{path});

    $self->_extract_headers($payload);
    $self->_extract_query($payload);
    $self->_extract_body($payload);
}

sub _extract_headers {
    my ($self, $payload) = @_;

    # Header prefix

    my $headers = $self->headers;
    my $url     = $self->url;
    my $base    = $url->base;
    
    my $lambda_headers = {
        %{$payload->{headers} // {}},
        %{$payload->{multiValueHeaders} // {}},
    };

    while (my ($key, $value) = each %$lambda_headers) {
        $key =~ s/-/_/g;
        $key = uc $key;
        if (ref $value eq "ARRAY") {
            $value = join ", ", @$value;
        }

        if ($key =~ /^(?:CONTENT_LENGTH|CONTENT_TYPE)$/) {
            my $accessor = lc($key);
            $headers->$accessor($value) if defined $value;
        }

        $headers->header($key => $value);
    }
}

sub _extract_query {
    my ($self, $payload) = @_;


    my $query = {
        %{$payload->{queryStringParameters} // {}},
        %{$payload->{multiValueQueryStringParameters} // {}},
    };
    my @params;
    while (my ($key, $value) = each %$query) {
        if (ref($value) eq 'ARRAY') {
            for my $v (@$value) {
                push @params, "$key=$v";
            }
        } else {
            push @params, "$key=$value";
        }
    }

    $self->url->query(join '&', @params);
}

sub _extract_body {
    my ($self, $payload) = @_;

    my $body = $payload->{body} // "";
    if ($payload->{isBase64Encoded}) {
        $body = decode_base64 $body;
    }

    $self->body($body);
}

1;
