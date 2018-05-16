use strict;
use Test::More 0.98;

use Mock::Quick;
use Path::Tiny;
use HTTP::Request;
use Test::Mojo;

plan tests => 3;

my $response;
my $bucket = qclass(
    -implement => 'Net::Amazon::S3::Bucket',
    -with_new  => 1,
    get_key    => sub {
        return $response;
    },
    account    => 1,
    bucket     => 1
);

my $s3 = qclass(
    -implement => 'Net::Amazon::S3',
    new        => sub { return $_[0]; },
    bucket     => sub {
        return $bucket->package->new;
    }
);

my $s3_request = qclass(
    -implement   => 'Net::Amazon::S3::Request::GetObject',
    -with_new    => 1,
    http_request => sub {
        return HTTP::Request->new(GET => "some_url");
    }
);

my $statsite = qclass(
    -implement => 'Net::Statsite::Client',
    -with_new  => 1,
    increment  => 1,
    update     => 1,
    timing     => 1,
);

my $headers = qclass(
    -implement     => 'Headers',
    -with_new      => 1,
    content_length => 1,
    last_modified  => 1,
);

my $res = qclass(
    -implement => 'Res',
    -with_new  => 1,
    headers    => sub {
        return $headers->package->new;
    },
);

my $c = qclass(
    -implement => 'Mojo',
    -with_new  => 1,
    res        => sub {
        return $res->package->new;
    },
    app => sub {
        return Test::Mojo->new();
    }
);

use_ok('Stor');
my $stor = Stor->new(
    statsite       => $statsite->package->new,
    basic_auth     => 'user:pass',
    s3_credentials => { host => 'host', user => 'some_user', pass => 'some_pass' },
);

subtest 'sha_transform' => sub {
    my $sha = '557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e';
    is(
        $stor->_sha_to_filepath($sha),
        '55/7a/65/557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e',
        'sha was transformed to filepath'
    );
    is(
        $stor->_sha_to_filepath(uc($sha)),
        '55/7a/65/557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e',
        'uc tranformed as lc'
    );
};

subtest 'get_from_s3' => sub {
    my $sha = '557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e';
    my $resp = $stor->get_from_s3($c->package->new, $sha);
    ok(!$stor->get_from_s3($c->package->new, $sha), 'file does not exist');

    $response = {
        'content_length' => 42,
        'last-modified'  => 123456789,
    };
    ok($stor->get_from_s3($c->package->new, $sha), 'file was succesfully downloaded');
};

