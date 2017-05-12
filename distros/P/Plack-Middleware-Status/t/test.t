use strict;
use Test::More tests => 8;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable 'Status', path => qr{/501}, status => 501;
    enable 'Status', path => sub { $_ eq '/sub' }, status => 201;
    enable 'Status', path => qr{/invalid}, status => 999;
    sub { [ 200, [], ['Pass-through'] ] };
};

test_psgi $app, sub {
    my $cb = shift;

    my %expect = (
        '/'       => { status => 200, content => 'Pass-through' },
        '/501'    => { status => 501, content => 'Not Implemented' },
        '/sub'    => { status => 201, content => 'Created' },
        'invalid' => { status => 200, content => 'Pass-through' },
    );
    for my $url ( keys %expect ) {
        my $res = $cb->( GET $url );
        my $e   = $expect{$url};
        is $res->code, $e->{status};
        is $res->content, $e->{content}, "$url => $e->{status} - $e->{content}";
    }
};
