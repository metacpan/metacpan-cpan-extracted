package Puncheur::Plugin::JSON;
use 5.010;
use strict;
use warnings;
use JSON;

our @EXPORT = qw/res_json/;

sub res_json {
    my ($self, $data) = @_;

    state $json = JSON->new->ascii(1);
    state $escape = {
        '+' => '\\u002b', # do not eval as UTF-7
        '<' => '\\u003c', # do not eval as HTML
        '>' => '\\u003e', # ditto.
    };
    my $body = $json->encode($data);
    $body =~ s!([+<>])!$escape->{$1}!g;

    my $user_agent = $self->req->user_agent || '';
    # defense from JSON hijacking
    if (
        (!$self->request->header('X-Requested-With')) &&
        $user_agent =~ /android/i                     &&
        defined $self->req->header('Cookie')          &&
        ($self->req->method||'GET') eq 'GET')
    {
        my $content = "Your request may be JSON hijacking.\nIf you are not an attacker, please add 'X-Requested-With' header to each request.";
        return $self->create_response(
            403,
            [
                'Content-Type'   => $self->html_content_type,
                'Content-Length' => length($content),
            ],
            [$content],
        );
    }

    my $encoding = $self->encoding;
    $encoding = lc $encoding->mime_name if ref $encoding;

    # add UTF-8 BOM if the client is Safari
    if ( $user_agent =~ m/Safari/ and $encoding eq 'utf-8' ) {
        $body = "\xEF\xBB\xBF" . $body;
    }

    return $self->create_response(
        200,
        [
            'Content-type'   => "application/json; charset=$encoding",
            'Content-Length' => length($body)
        ],
        [ $body ]
    );
}

1;
