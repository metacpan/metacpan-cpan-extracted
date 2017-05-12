use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use File::Temp;
use File::Spec;
use HTTP::Request::Common;
use Test::Output;

use OrePAN2::Server::CLI;

my $mock_tar_name = 'MockModule-0.01.tar.gz';
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $app = OrePAN2::Server::CLI->new("--delivery-dir=$dir", '--delivery-path=/orepan')->app;

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'CPAN::Uploader interface' => sub {
            my $res;
            stdout_like {
                $res = $cb->(POST "http://localhost/authenquery",
                    Content_Type => 'form-data',
                    Content      => +[
                        HIDDENNAME                  => 'hirobanex',
                        pause99_add_uri_httpupload  => ["./t/$mock_tar_name"]
                    ],
                );
            } qr/Wrote/,'orepan inject ?';

            is $res->code, 200, 'success request ?';
            ok -f File::Spec->catfile($dir, qw/modules 02packages.details.txt.gz/), 'is there 02packages.details.txt.gz ?';
            ok -f File::Spec->catfile($dir, qw/authors id H HI HIROBANEX/, $mock_tar_name), 'tarball exists';
        };
    };

done_testing;

