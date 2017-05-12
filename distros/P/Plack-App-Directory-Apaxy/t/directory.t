use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::Directory::Apaxy;

my $handler = Plack::App::Directory::Apaxy->new({ root => 'share' });

my %test = (
    client => sub {
        my $cb  = shift;

        # URI-escape
        my $res = $cb->(GET "http://localhost/");
        my($ct, $charset) = $res->content_type;
        ok $res->content =~ m{/%23foo};

        $res = $cb->(GET "/..");
        is $res->code, 403;

        $res = $cb->(GET "/..%00foo");
        is $res->code, 400;

        $res = $cb->(GET "/..%5cfoo");
        is $res->code, 403;

        $res = $cb->(GET "/");
        like $res->content, qr/Index of \//;

        for my $url (qw{
            /_apaxy/icons/archive.png
            /_apaxy/icons/audio.png
            /_apaxy/icons/authors.png
            /_apaxy/icons/bin.png
            /_apaxy/icons/blank.png
            /_apaxy/icons/bmp.png
            /_apaxy/icons/c.png
            /_apaxy/icons/calc.png
            /_apaxy/icons/cd.png
            /_apaxy/icons/copying.png
            /_apaxy/icons/cpp.png
            /_apaxy/icons/css.png
            /_apaxy/icons/deb.png
            /_apaxy/icons/default.png
            /_apaxy/icons/diff.png
            /_apaxy/icons/doc.png
            /_apaxy/icons/draw.png
            /_apaxy/icons/eps.png
            /_apaxy/icons/exe.png
            /_apaxy/icons/folder-home.png
            /_apaxy/icons/folder-open.png
            /_apaxy/icons/folder-page.png
            /_apaxy/icons/folder-parent-old.png
            /_apaxy/icons/folder-parent.png
            /_apaxy/icons/folder.png
            /_apaxy/icons/gif.png
            /_apaxy/icons/gzip.png
            /_apaxy/icons/h.png
            /_apaxy/icons/hpp.png
            /_apaxy/icons/html.png
            /_apaxy/icons/ico.png
            /_apaxy/icons/image.png
            /_apaxy/icons/install.png
            /_apaxy/icons/java.png
            /_apaxy/icons/jpg.png
            /_apaxy/icons/js.png
            /_apaxy/icons/json.png
            /_apaxy/icons/log.png
            /_apaxy/icons/makefile.png
            /_apaxy/icons/markdown.png
            /_apaxy/icons/package.png
            /_apaxy/icons/pdf.png
            /_apaxy/icons/perl.png
            /_apaxy/icons/php.png
            /_apaxy/icons/playlist.png
            /_apaxy/icons/png.png
            /_apaxy/icons/pres.png
            /_apaxy/icons/ps.png
            /_apaxy/icons/psd.png
            /_apaxy/icons/py.png
            /_apaxy/icons/rar.png
            /_apaxy/icons/rb.png
            /_apaxy/icons/readme.png
            /_apaxy/icons/rpm.png
            /_apaxy/icons/rss.png
            /_apaxy/icons/rtf.png
            /_apaxy/icons/script.png
            /_apaxy/icons/source.png
            /_apaxy/icons/sql.png
            /_apaxy/icons/tar.png
            /_apaxy/icons/tex.png
            /_apaxy/icons/text.png
            /_apaxy/icons/tiff.png
            /_apaxy/icons/unknown.png
            /_apaxy/icons/vcal.png
            /_apaxy/icons/video.png
            /_apaxy/icons/xml.png
            /_apaxy/icons/zip.png
            /_apaxy/style.css
            /favicon.ico
        }) {
            $res = $cb->(GET $url);
            is $res->code, 200, $url;
        }

    SKIP: {
            skip "Filenames can't end with . on windows", 2 if $^O eq "MSWin32";

            mkdir "share/stuff..", 0777;
            open my $out, ">", "share/stuff../Hello.txt" or die $!;
            print $out "Hello\n";
            close $out;

            $res = $cb->(GET "/stuff../Hello.txt");
            is $res->code, 200;
            is $res->content, "Hello\n";

            unlink "share/stuff../Hello.txt";
            rmdir "share/stuff..";
        }
    },
    app => $handler,
);

test_psgi %test;

done_testing;
