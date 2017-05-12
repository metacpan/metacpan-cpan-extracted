use strict;
use Test::More;

use File::Which qw(which);
plan skip_all => 'could not find git' unless which('git');

use IO::Compress::Gzip qw(gzip);

use Plack::Test;
use HTTP::Request::Common;
use Plack::App::GitSmartHttp;

my $app = Plack::App::GitSmartHttp->new(
    root          => "t/test_repos",
    upload_pack   => 1,
    received_pack => 1,
);

subtest 'success' => sub {
    test_psgi $app, sub {
        my $cb      = shift;
        my $content = <<__CONTENT__;
006fwant 6410316f2ed260666a8a6b9a223ad3c95d7abaed multi_ack_detailed no-done side-band-64k thin-pack ofs-delta
0032want 6410316f2ed260666a8a6b9a223ad3c95d7abaed
00000009done
__CONTENT__
        my $res = $cb->(
            POST "/repo1/git-upload-pack",
            "Content-Type"   => "application/x-git-upload-pack-request",
            "Content-Length" => 174,
            "Content"        => $content,
        );
        is $res->code, 200;
        is $res->header("Content-Type"), 'application/x-git-upload-pack-result';
    };
};

subtest 'success gzip' => sub {
    test_psgi $app, sub {
        my $cb      = shift;
        my $content = <<__CONTENT__;
006fwant 6410316f2ed260666a8a6b9a223ad3c95d7abaed multi_ack_detailed no-done side-band-64k thin-pack ofs-delta
0032want 6410316f2ed260666a8a6b9a223ad3c95d7abaed
00000009done
__CONTENT__
        my $content_gzipped;
        gzip \$content => \$content_gzipped;

        my $res = $cb->(
            POST "/repo1/git-upload-pack",
            "Content-Type"     => "application/x-git-upload-pack-request",
            "Content-Length"   => 174,
            "Content-Encoding" => 'gzip',
            "Content"          => $content_gzipped,
        );
        is $res->code, 200;
        is $res->header("Content-Type"), 'application/x-git-upload-pack-result';
    };
};

subtest 'success x-gzip' => sub {
    test_psgi $app, sub {
        my $cb      = shift;
        my $content = <<__CONTENT__;
006fwant 6410316f2ed260666a8a6b9a223ad3c95d7abaed multi_ack_detailed no-done side-band-64k thin-pack ofs-delta
0032want 6410316f2ed260666a8a6b9a223ad3c95d7abaed
00000009done
__CONTENT__
        my $content_gzipped;
        gzip \$content => \$content_gzipped;

        my $res = $cb->(
            POST "/repo1/git-upload-pack",
            "Content-Type"     => "application/x-git-upload-pack-request",
            "Content-Length"   => 174,
            "Content-Encoding" => 'x-gzip',
            "Content"          => $content_gzipped,
        );
        is $res->code, 200;
        is $res->header("Content-Type"), 'application/x-git-upload-pack-result';
    };
};

subtest 'no content' => sub {
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(
            POST "/repo1/git-upload-pack",
            "Content-Type" => "application/x-git-upload-pack-request",
        );
        is $res->code, 400;
    };
};

done_testing
