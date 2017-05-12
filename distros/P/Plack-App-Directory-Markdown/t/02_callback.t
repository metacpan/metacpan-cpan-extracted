use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::Directory::Markdown;

my $handler = Plack::App::Directory::Markdown->new({
    root => 't/share',
    callback => sub {
        my ($content_ref, $env, $dir) = @_;

        ${$content_ref} =~ s!h1>!h2>!g;
    }
});

my %test = (
    client => sub {
        my $cb  = shift;

    SKIP: {
            skip "Filenames can't end with . on windows", 2 if $^O eq "MSWin32";

            mkdir "t/share/stuff..", 0777;
            open my $out, ">", "t/share/stuff../Hello.md" or die $!;
            print $out "# Hello\n";
            close $out;

            my $res = $cb->(GET "/stuff../Hello.md");
            is $res->code, 200;
            like $res->content, qr!<h2>Hello</h2>!;

            unlink "t/share/stuff../Hello.md";
            rmdir "t/share/stuff..";
        }
    },
    app => $handler,
);

test_psgi %test;

done_testing;
