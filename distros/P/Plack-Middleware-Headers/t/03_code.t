use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $app = builder {
    enable 'Headers',
        code => '404',
        set => ['X-Robots-Tag' => 'noindex, noarchive, follow'];
    enable 'Headers',
        set => ['X-Plack-One' => 'one'];
    sub {
        my $env = shift;
        if ( $env->{'PATH_INFO'} eq '/' ) {
            return ['200', ['Content-Type' => 'text/plain'], ['hello world']];
        }
        else {
            return ['404', ['Content-Type' => 'text/plain'], ['not found']];
        }
    };
};

# See https://github.com/libwww-perl/http-message/issues/2#issuecomment-24443074
sub headers_as_hash {
    my $h = shift;
    return { 
        map { $_ => $h->header($_) } grep { $_ ne '::std_case' }
        keys %$h
    }
}

test_psgi app => $app, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        print ref($res)."\n";
        is_deeply headers_as_hash($res->headers), {
            'content-type' => 'text/plain',
            'x-plack-one' => 'one'
        };
    }
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/foo";
        my $res = $cb->($req);
        ok($res->code == 404) or diag($res->code);
        is_deeply headers_as_hash($res->headers), {
            'content-type' => 'text/plain',
            'x-plack-one' => 'one',
            'x-robots-tag' => 'noindex, noarchive, follow'
        };
    }
};

done_testing;
