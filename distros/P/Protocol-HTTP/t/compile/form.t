use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Test::Fatal;
use Protocol::HTTP::Request;

catch_run('[compile-form]');

my $canonize = sub {
    my $s = shift;
    if ($s !~ /; boundary=(-+\w+)/) { die("no boundary at string '$s'"); }
    my ($b) = $1;
    my $r = $s =~ s/$b/-----------------------XXXXXXXXXXXXXXXXX/gr;
    return $r;
};

my $sample = $canonize->(
    "POST /abc HTTP/1.1\r\n".
    "Content-Length: 232\r\n".
    "Content-Type: multipart/form-data; boundary=-----------------------xn654lb75PltJaTBy\r\n".
    "\r\n".

    "-------------------------xn654lb75PltJaTBy\r\n".
    "Content-Disposition: form-data; name=\"k1\"\r\n".
    "\r\n".
    "v1\r\n".

    "-------------------------xn654lb75PltJaTBy\r\n".
    "Content-Disposition: form-data; name=\"k2\"\r\n".
    "\r\n".
    "v2\r\n".

    "-------------------------xn654lb75PltJaTBy--\r\n"
);

subtest "simple multipart/form-data" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc',
        form => [k1 => 'v1', k2 => 'v2'],
    });
    is $canonize->($req->to_string), $sample;
};

subtest "multipart/form-data (2)" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc',
        form => {
            enc_type => ENCODING_MULTIPART,
            fields   => [k1 => 'v1', k2 => 'v2'],
        },
    });
    is $canonize->($req->to_string), $sample;
};

subtest "multipart/form-data (file)" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc',
        form => {
            enc_type => ENCODING_MULTIPART,
            fields   => [k1 => ['sample.jpg' => 'bla-bla-bla', 'image/jpeg']],
        },
    });
    is $canonize->($req->to_string), $canonize->(
        "POST /abc HTTP/1.1\r\n".
        "Content-Length: 197\r\n".
        "Content-Type: multipart/form-data; boundary=-----------------------xn654lb75PltJaTBy\r\n".
        "\r\n".

        "-------------------------xn654lb75PltJaTBy\r\n".
        "Content-Disposition: form-data; name=\"k1\"; filename=\"sample.jpg\"\r\n".
        "Content-Type: image/jpeg\r\n".
        "\r\n".
        "bla-bla-bla\r\n".

        "-------------------------xn654lb75PltJaTBy--\r\n"
    );
};

subtest "allow to submit multipart/form-data with GET-request" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc',
        method => METHOD_GET,
        form   => [k1 => 'v1', k2 => 'v2'],
    });
    my $changed_samle = ($sample =~ s/POST/GET/r);
    is $canonize->($req->to_string), $changed_samle;
};


subtest "multipart/form-data (3)" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc?k1=v1&k2=v2',
        form => ENCODING_MULTIPART,
    });
    is $canonize->($req->to_string), $sample;
};

subtest "application/x-www-form-urlencoded" => sub {
    my $req = Protocol::HTTP::Request->new({
        uri  => '/abc',
        form => {
            enc_type => ENCODING_URL,
            fields   => [k1 => 'v1', k2 => 'v2'],
        },
    });
    is $req->to_string,
        "GET /abc?k1=v1&k2=v2 HTTP/1.1\r\n".
        "\r\n"
    ;
};

subtest "wrong enc_type" => sub {
    like exception { Protocol::HTTP::Request->new({uri  => '/', form => -1, }) },
        qr/invalid form encoding/;
    like exception { Protocol::HTTP::Request->new({uri  => '/', form => {
            enc_type => -1,
            fields   => [k1 => 'v1', k2 => 'v2'],
        }}) },
        qr/invalid form encoding/;
};

done_testing;
