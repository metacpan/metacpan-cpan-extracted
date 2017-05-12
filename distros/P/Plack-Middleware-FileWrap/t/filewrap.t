#!/usr/bin/perl

use strict;
use Test::More;
use FindBin qw/$Bin/;
use Plack::Builder;
use Plack::Test;
use Plack::Middleware::FileWrap;

my $html;
my $test_name;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ];
};

my @builders = (
    sub {
        $app = builder {
            enable 'FileWrap',
              headers => [ \'TEST HEAD' ],
              footers => [ \'TEST FOOT' ];
            $html      = 'TEST HEADHello WorldTEST FOOT';
            $test_name = "text ref";
            $app;
        };
    },
    sub {
        $app = builder {
            enable 'FileWrap',
              headers => ["$Bin/header.txt"],
              footers => ["$Bin/footer.txt"];
            $html      = 'HEADER IN FILEHello WorldFOOTER IN FILE';
            $test_name = "file";
            $app;
        };
    },
);

foreach my $builder (@builders) {
    $app = sub {
        return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ];
    };
    &$builder;
    test_psgi
      app    => $app,
      client => sub {
        my $cb = shift;
        my $res = $cb->( HTTP::Request->new( GET => 'http://localhost/' ) );
        is $res->decoded_content, $html, $test_name;
      };
}

done_testing;
