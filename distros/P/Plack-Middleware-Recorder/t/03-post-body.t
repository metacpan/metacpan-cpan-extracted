use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::Test;
use Test::More tests => 1;

my $tempfile = File::Temp->new;
close $tempfile;

my $app = builder {
    enable 'Recorder', output => $tempfile->filename;
    sub {
        my ( $env ) = @_;

        my $h    = $env->{'psgi.input'};
        my $body = '';

        $h->read($body, 1024);

        is $body, 'foobarmatic';

        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(POST '/', Content => 'foobarmatic');
};
