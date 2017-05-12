use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use IO::File;
use File::Slurp qw(read_file);

my $fname = 't/images/100x100.png';
my $handler = builder {
    enable 'Image::Scale';
    sub {
        my $env = shift;

        if ( $env->{PATH_INFO} eq '/simple.png' ) {
            return [
                200,
                [ 'Content-Type' => 'image/png' ],
                [ read_file($fname) ]
            ];

        } elsif ( $env->{PATH_INFO} eq '/filehandle.png' ) {
            return [
                200,
                [ 'Content-Type' => 'image/png' ],
                IO::File->new($fname,'<')
            ];

        } elsif ( $env->{PATH_INFO} eq '/delayed.png' ) {
            return sub {
                shift->([
                    200,
                    [ 'Content-Type' => 'image/png' ],
                    [ read_file($fname) ]
                ]);
            };

        } elsif ( $env->{PATH_INFO} eq '/delayedfilehandle.png' ) {
            return sub { shift->([
                200,
                [ 'Content-Type' => 'image/png' ],
                IO::File->new($fname,'<')
            ]) };

        } elsif ( $env->{PATH_INFO} eq '/streaming.png' ) {
            return sub {
                my $writer = shift->(
                    [ 200, ['Content-Type' => 'image/png'] ]
                );
                my $fh = IO::File->new($fname,'<');
                while( $fh->read(my $buf,10) ) {
                    $writer->write($buf);
                }
                $writer->close;
            };

        } elsif ( $env->{PATH_INFO} eq '/streaming-empty-304.png' ) {
            return sub {
                my $writer = shift->(
                    [ 304, ['Content-Type' => 'image/png'] ]
                );
                $writer->close;
            };
        }

        return [404,['Content-Type','text/plain'],[]];
    };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'simple response' => sub {

        my $res = $cb->(GET "http://localhost/simple_200x200.png");
        is $res->code, 200, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';

    };

    subtest 'filehandle response' => sub {

        my $res = $cb->(GET "http://localhost/filehandle_200x200.png");
        is $res->code, 200, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';

    };

    subtest 'delayed response' => sub {

        my $res = $cb->(GET "http://localhost/delayed_200x200.png");
        is $res->code, 200, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';

    };

    subtest 'delayed filehandle response' => sub {

        my $res = $cb->(GET "http://localhost/delayedfilehandle_200x200.png");
        is $res->code, 200, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';

    };

    subtest 'streaming response' => sub {

        my $res = $cb->(GET "http://localhost/streaming_200x200.png");
        is $res->code, 200, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';

    };

    subtest 'streaming empty 304 response' => sub {

        my $res = $cb->(GET "http://localhost/streaming-empty-304_200x200.png");
        is $res->code, 304, 'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';
        is $res->content, '', 'Response body is empty';

    };

};

done_testing;

