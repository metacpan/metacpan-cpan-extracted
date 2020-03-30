package Mojo::Server::AWSLambda::Response;

use Mojo::Base 'Mojo::Message::Response';
use Mojo::JSON qw(decode_json encode_json);

use MIME::Base64;
use Try::Tiny;
use JSON::Types;
use Encode;

sub output {
    my $self = shift;

    my $status  = $self->code || 404;
    my $headers = $self->headers->to_hash;
    my $body    = $self->body;

    my $singleValueHeaders = {};
    my $multiValueHeaders = {};
    foreach my $header (keys %{$headers}) {
       $singleValueHeaders->{lc $header} = $headers->{$header};
       push @{$multiValueHeaders->{lc $header} //= []}, $headers->{$header};
    }

    my $type = $singleValueHeaders->{'content-type'};
    my $isBase64Encoded = $type !~ m(^text/.*|application/(:?json|javascript|xml))i;
    if ($isBase64Encoded) {
        $body = encode_base64 $body, '';
    } 
    else {
        try {
            decode_utf8($body, Encode::FB_CROAK | Encode::LEAVE_SRC);
        } catch {
            $isBase64Encoded = 1;
            $body = encode_base64 $body, '';
        };
     }

     return +{
        isBase64Encoded => bool $isBase64Encoded,
        headers => $singleValueHeaders,
        multiValueHeaders => $multiValueHeaders,
        statusCode => number $status,
        body => string $body,
     }
}

1;
