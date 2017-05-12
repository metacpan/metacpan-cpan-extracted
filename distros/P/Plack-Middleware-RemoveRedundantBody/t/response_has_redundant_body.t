use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

test_psgi app => builder {
    enable 'RemoveRedundantBody';

    mount '/code_100_no_body_set' => sub {
        [100,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         []];
    };

    mount '/code_101_body_set' => sub {
        [101,
         [ "Content-Type" => 'text/html; charset=utf-8'],
           ["<html><body>Body is set for 100</body></html>"]];
    };

    mount '/code_204_body_set' => sub {
        [204,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         ["<html><body>Body is set</body></html>"]];
    };

    mount '/code_204_no_body_set' => sub {
        [204,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         []];
    };

    mount '/code_304_body_set' => sub {
        [304,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         ["<html><body>Body is set for 304</body></html>"]];
    };

    mount '/code_304_no_body_set' => sub {
        [304,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         []];
    };

    mount '/code_404_body_set' => sub {
        [404,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         ["<html><body>Body is set for 404</body></html>"]];
    };

    mount '/code_300_body_set' => sub {
        [300,
         ["Content-Type" => 'text/html; charset=utf-8'],
         ["<html><body>Body is set for 300</body></html>"]];
    };

    mount '/code_100_no_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        close $fh;
        open $fh, "<", "output.txt";
        [100,
         [ "Content-Type" => 'text/html; charset=utf-8' ],
         $fh];
    };

    mount '/code_204_no_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        close $fh;
        open $fh, "<", "output.txt";
        [204,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_304_no_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        close $fh;
        open $fh, "<", "output.txt";
        [304,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_404_no_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        close $fh;
        open $fh, "<", "output.txt";
        [100,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_100_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        my $text = "<html><body>I'm file's text</body></html>";
        print $fh $text;
        close $fh;
        open $fh, "<", "output.txt";
        [100,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_101_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        my $text = "<html><body>I'm file's text</body></html>";
        print $fh $text;
        close $fh;
        open $fh, "<", "output.txt";
        [101,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_204_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        my $text = "<html><body>I'm file's text</body></html>";
        print $fh $text;
        close $fh;
        open $fh, "<", "output.txt";
        [204,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/code_304_body_in_file_set' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        my $text = "<html><body>I'm file's text</body></html>";
        print $fh $text;
        close $fh;
        open $fh, "<", "output.txt";
        [304,
         [ "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };
},
client => sub {
    my $cb = shift;

    my @responses = (
        [ '/code_100_no_body_set',
          '',
          100,
          'text/html; charset=utf-8' ],
        [ '/code_101_body_set',
          '',
          101,
          'text/html; charset=utf-8' ],
        [ '/code_204_body_set',
          '',
          204,
          'text/html; charset=utf-8' ],
        [ '/code_204_no_body_set',
          '',
          204,
          'text/html; charset=utf-8' ],
        [ '/code_304_body_set',
          '',
          304,
          'text/html; charset=utf-8' ],
        [ '/code_304_no_body_set',
          '',
          304,
          'text/html; charset=utf-8' ],
        [ '/code_404_body_set',
          "<html><body>Body is set for 404</body></html>",
          404,
          'text/html; charset=utf-8' ],
        [ '/code_300_body_set',
          "<html><body>Body is set for 300</body></html>",
          300,
          'text/html; charset=utf-8' ],
        [ '/code_100_no_body_in_file_set',
          '',
          100,
          'text/html; charset=utf-8' ],
        [ '/code_204_no_body_in_file_set',
          '',
          204,
          'text/html; charset=utf-8' ],
        [ '/code_304_no_body_in_file_set',
          '',
          304,
          'text/html; charset=utf-8' ],
        [ '/code_100_body_in_file_set',
          '',
          100,
          'text/html; charset=utf-8' ],
        [ '/code_101_body_in_file_set',
          '',
          101,
          'text/html; charset=utf-8' ],
        [ '/code_204_body_in_file_set',
          '',
          204,
          'text/html; charset=utf-8' ],
        [ '/code_304_body_in_file_set',
          '',
          304,
          'text/html; charset=utf-8' ],
    );

    foreach my $response ( @responses ) {
        my @response_array = @$response;
        my $route          = $response_array[0],
        my $content        = $response_array[1];
        my $response_code  = $response_array[2];
        my $content_type   = $response_array[3];
        my $res            = $cb->(GET $route);

        is( $res->content,
              $content,
              "Content for $route matches $content");

        is( $res->code,
            $response_code,
            "Response code for $route is $response_code" );

        is( $res->header('Content-Type'),
            $content_type,
            "Content-Type for $route is $content_type");
    }
};

unlink "output.txt";
done_testing;
