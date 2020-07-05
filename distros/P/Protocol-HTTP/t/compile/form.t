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
    "POST / HTTP/1.1\r\n".
    "Content-Length: 226\r\n".
    "Content-Type: multipart/form-data; boundary=-----------------------xn654lb75PltJaTBy\r\n".
    "\r\n".

    "-----------------------xn654lb75PltJaTBy\r\n".
    "Content-Disposition: form-data; name=\"k1\"\r\n".
    "\r\n".
    "v1\r\n".

    "-----------------------xn654lb75PltJaTBy\r\n".
    "Content-Disposition: form-data; name=\"k2\"\r\n".
    "\r\n".
    "v2\r\n".

    "-----------------------xn654lb75PltJaTBy--\r\n"
);

subtest "simple multipart/form-data" => sub {
    MyTest::native_srand(777);
    my $req = Protocol::HTTP::Request->new({
        form => [k1 => 'v1', k2 => 'v2'],
    });
    is $canonize->($req->to_string), $sample;
};

subtest "multipart/form-data (2)" => sub {
    MyTest::native_srand(777);
    my $req = Protocol::HTTP::Request->new({
        form => {
            enc_type => ENCODING_MULTIPART,
            fields   => [k1 => 'v1', k2 => 'v2'],
        },
    });
    is $canonize->($req->to_string), $sample;
};

subtest "allow to submit multipart/form-data with GET-request" => sub {
    MyTest::native_srand(777);
    my $req = Protocol::HTTP::Request->new({
        method => METHOD_GET,
        form   => [k1 => 'v1', k2 => 'v2'],
    });
    my $changed_samle = ($sample =~ s/POST/GET/r);
    is $canonize->($req->to_string), $changed_samle;
};


subtest "multipart/form-data (3)" => sub {
    MyTest::native_srand(777);
    my $req = Protocol::HTTP::Request->new({
        uri  => '/?k1=v1&k2=v2',
        form => ENCODING_MULTIPART,
    });
    is $canonize->($req->to_string), $sample;
};

subtest "application/x-www-form-urlencoded" => sub {
    my $req = Protocol::HTTP::Request->new({
        form => {
            enc_type => ENCODING_URL,
            fields   => [k1 => 'v1', k2 => 'v2'],
        },
    });
    is $req->to_string,
        "GET /?k1=v1&k2=v2 HTTP/1.1\r\n".
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
