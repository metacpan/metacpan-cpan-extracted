#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;
use Test::Exception;
use Parse::WWWAuthenticate qw(parse_wwwa);


subtest 'Basic' => sub {
    {
        my $header = 'Basic realm="foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="foo"';
    }
    {
        my $header = 'BASIC REALM="foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'BASIC REALM="foo"';
    }
    {
        my $header = 'Basic realm=foo';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm=foo';
    }
    {
        my $header = 'Basic realm=\\f\\o\\o';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => '\\f\\o\\o',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm=\\f\\o\\o';
    }
    {
        my $header = 'Basic realm=\'foo\'';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => "'foo'",
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm=\'foo\'';
    }
    {
        my $header = 'Basic realm="foo%20bar"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo%20bar',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="foo%20bar"';
    }
    {
        my $header = 'Basic , realm="foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic , realm="foo"';
    }
    {
        my $header = 'Basic, realm="foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic, realm="foo"';
    }
    {
        my $header = 'Basic';
        throws_ok { parse_wwwa( $header ) } qr/realm parameter is missing/;
    }
    {
        my $header = 'Basic realm="foo", realm="bar"';
        throws_ok { parse_wwwa( $header ) } qr/only one realm is allowed/;
    }
    {
        my $header = 'Basic realm = "foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm = "foo"';
    }
    {
        my $header = 'Basic realm="\\f\\o\\o"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="\\f\\o\\o"';
    }
    {
        my $header = 'Basic realm="\\"foo\\""';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => '"foo"',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="\\"foo\\""';
    }
    {
        my $header = 'Basic realm="foo", bar="xyz",, a=b,,,c=d';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                    bar   => 'xyz',
                    a     => 'b',
                    c     => 'd',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="foo", bar="xyz",, a=b,,,c=d';
    }
    {
        my $header = 'Basic bar="xyz", realm="foo"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo',
                    bar   => 'xyz',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic bar="xyz", realm="foo"';
    }
    {
        my $header = 'Basic realm="foo-ä"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'foo-ä',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="foo-ä"';
    }
    {
        my $header = 'Basic realm="=?ISO-8859-1?Q?foo-=E4?="';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => '=?ISO-8859-1?Q?foo-=E4?=',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="=?ISO-8859-1?Q?foo-=E4?="';
    }
};
subtest 'Multiple Challenges' => sub {
    {
        my $header = 'Basic realm="basic", Newauth realm="newauth"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                },
            },
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="basic", Newauth realm="newauth"';
    }
    {
        my $header = 'Newauth realm="newauth", Basic realm="basic"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth',
                },
            },
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth", Basic realm="basic"';
    }
    {
        my $header = ',Basic realm="basic"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                },
            },
        ];
        is_deeply \@info, $check, ',Basic realm="basic"';
    }
    {
        my $header = 'Newauth realm="apps", type=1, title="Login to \\"apps\\"", Basic realm="simple" ';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'apps',
                    type  => 1,
                    title => 'Login to "apps"',
                },
            },
            {
                name   => 'Basic',
                params => {
                    realm => 'simple',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="apps", type=1, title="Login to \\"apps\\"", Basic realm="simple" ';
    }
    {
        my $header = 'Newauth realm="Newauth Realm", basic=foo, Basic realm="Basic Realm" ';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'Newauth Realm',
                    basic => 'foo',
                },
            },
            {
                name   => 'Basic',
                params => {
                    realm => 'Basic Realm',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="Newauth Realm", basic=foo, Basic realm="Basic Realm" ';
    }
};

subtest 'Parsing quirks' => sub {
    {
        my $header = 'Basic foo="realm=nottherealm", realm="basic"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                    foo   => 'realm=nottherealm',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic foo="realm=nottherealm", realm="basic"';
    }
    {
        my $header = 'Basic nottherealm="nottherealm", realm="basic"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                    nottherealm => "nottherealm",
                },
            },
        ];
        is_deeply \@info, $check, 'Basic nottherealm="nottherealm", realm="basic"';
    }
    TODO:
    {
        local $TODO = "Need to implement a check for balanced quoting";
        my $header = 'Basic realm="basic';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Basic',
                params => {
                    realm => 'basic',
                },
            },
        ];
        is_deeply \@info, $check, 'Basic realm="basic';
    }
};
subtest 'Unknown Schemes' => sub {
    {
        my $header = 'Newauth realm="newauth"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth"';
    }
    {
        my $header = 'Newauth realm="newauth,"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,"';
    }
    {
        my $header = 'Newauth realm="newauth,", user="test"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                    user  => 'test',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,", user="test"';
    }
    {
        my $header = 'Newauth realm="newauth,", user = "test"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                    user  => 'test',
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,", user = "test"';
    }
    {
        my $header = 'Newauth realm="newauth,", user = "test", Basic1 realm="hallo,welt"';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                    user  => 'test',
                },
            },
            {
                name   => 'Basic1',
                params => {
                    realm => "hallo,welt"
                },
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,", user = "test", Basic1 realm="hallo,welt"';
    }
    {
        my $header = 'Newauth realm="newauth,", user = "test", Basic1 realm="hallo,welt", Negotiate';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                    user  => 'test',
                },
            },
            {
                name   => 'Basic1',
                params => {
                    realm => "hallo,welt"
                },
            },
            {
                name   => 'Negotiate',
                params => {},
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,", user = "test", Basic1 realm="hallo,welt", Negotiate';
    }
    {
        my $header = 'Newauth realm="newauth,", user = "test", Basic1 realm="Hallo,Welt", Negotiate';
        my @info   = parse_wwwa( $header );
        my $check  = [
            {
                name   => 'Newauth',
                params => {
                    realm => 'newauth,',
                    user  => 'test',
                },
            },
            {
                name   => 'Basic1',
                params => {
                    realm => "Hallo,Welt"
                },
            },
            {
                name   => 'Negotiate',
                params => {},
            },
        ];
        is_deeply \@info, $check, 'Newauth realm="newauth,", user = "test", Basic1 realm="Hallo,Welt", Negotiate';
    }
};

done_testing();
