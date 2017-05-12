use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::Directory::Markdown;

my $handler = Plack::App::Directory::Markdown->new({ root => 't/share' });

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

        $res = $cb->(GET "/");
        like $res->content, qr/Index of\s+\//;

    SKIP: {
            skip "Filenames can't end with . on windows", 2 if $^O eq "MSWin32";

            mkdir "t/share/stuff..", 0777;
            open my $out, ">", "t/share/stuff../Hello.md" or die $!;
            print $out "# Hello\n";
            close $out;

            $res = $cb->(GET "/stuff../Hello.md");
            is $res->code, 200;
            like $res->content, qr!<h1>Hello</h1>!;

            unlink "t/share/stuff../Hello.md";
            rmdir "t/share/stuff..";
        }
    },
    app => $handler,
);

test_psgi %test;

done_testing;
