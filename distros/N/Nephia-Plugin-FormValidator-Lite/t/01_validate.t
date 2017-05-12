use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use URI;
use File::Spec;
use File::Basename qw/dirname/;

use lib File::Spec->catdir(dirname(__FILE__), 'nephia-test_app','lib');
use Nephia::TestApp;

my $app = Nephia::TestApp->run(
    appname => 'MyApp',
    'Plugin::FormValidator::Lite' => {
        function_message => 'en',
        constants => [qw/Email/]
    }
);

test_psgi $app, sub {
    my $cb = shift;

    subtest "valid request" => sub {
        my $uri = URI->new('/form');
        my %opts = @_;
        my $res =
            $cb->(POST $uri, [
                first_name => 'John',
                last_name => 'Doe',
                mail => 'john@example.com'
            ]);
        my $content = $res->content;
        like $content, qr/<p>FULL NAME: John Doe<\/p>/;
        like $content, qr/<p>E-MAIL ADDRESS: john\@example.com<\/p>/;
    };

    subtest "invalid request" => sub {
        my $uri = URI->new('/form');
        my %opts = @_;
        my $res =
            $cb->(POST $uri, [
                first_name => 'John',
                last_name => '',
                mail => 'john@example.com'
            ]);
        my $content = $res->content;
        like $content, qr/<li>please input LAST NAME<\/li>/;
    };
};

done_testing;
