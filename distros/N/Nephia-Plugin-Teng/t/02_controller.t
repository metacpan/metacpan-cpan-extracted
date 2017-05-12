use strict;
use warnings;
use utf8;

use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use JSON;
use Encode qw/encode_utf8/;
use File::Spec;
use lib File::Spec->catdir(qw/t nephia-test_app lib/);
use File::Temp qw/tempfile/;
my ($fh, $tempfile) = tempfile();
undef $fh;
use Nephia::TestApp;
my $app = Nephia::TestApp->run(
    'DBI' => {
        connect_info => [ 'DBI:SQLite:dbname='.$tempfile ],
    }
);

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;

        subtest 'person GET' => sub {
            my $res = $cb->(GET '/person/1');
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is_deeply $json, {
                id => 1,
                name => 'bob',
                age => 20
            };
            ok 1;
        };

        subtest 'register POST' => sub {
            my %opts = @_;
            my $res =
                $cb->(POST '/register', [
                    name => 'alice',
                    age => 18, 
                ]);
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is_deeply $json, {
                id => 2,
                name => 'alice',
                age => 18
            };
        };
    };

done_testing;

