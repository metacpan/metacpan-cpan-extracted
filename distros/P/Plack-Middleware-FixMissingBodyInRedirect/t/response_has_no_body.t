use strict;
use warnings;
use Test::More tests => 47;
use Plack::Test;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;

test_psgi app => builder {
    enable 'FixMissingBodyInRedirect';

    mount '/empty_array' => sub {
        [302,
         [ "Location" => '/xyz',
           ],
         []];
    };

    mount '/empty_string' => sub {
        [302,
         [ "Location" => '/xyz',
           ],
         ['']];
    };

    mount '/array_with_one_undef' => sub {
        [302,
         [ "Location" => '/xyz',
           ],
           [undef]];
    };

    mount '/first_undef_rest_def' => sub {
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         [undef, "<html><body>Only first element was undef</body></html>"]];
    };

    mount '/already_set_body' => sub {
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         ["<html><body>Body is set</body></html>"]];
    };

    mount '/body_with_size_zero_file_handle' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        close $fh;
        open $fh, "<", "output.txt";
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/body_with_good_file_handle' => sub {
        open(my $fh, ">", "output.txt")
            or die "cannot open > output.txt: $!";
        my $text = "<html><body>I'm file's text</body></html>";
        print $fh $text;
        close $fh;
        open $fh, "<", "output.txt";
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         $fh];
    };

    mount '/zeros_only' => sub {
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         [0000]];
    };

    mount '/empty_strings_body' => sub {
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         ['', '', '', '' ]];
    };

    # Case when one has a custom filehandle like object that does ->getline
    mount '/filehandle_like' => sub {
        [302,
         [ "Location" => '/xyz',
           "Content-Type" => 'text/html; charset=utf-8'],
         ,do {
            my @lines = ( "aaa\n", "bbb\n");
            Plack::Util::inline_object(getline => sub { shift @lines }, close => sub {});
         }];
    };

    # test for delayed style response
    mount '/delayed_tuple' => sub {
      my $env = shift;
      return sub { shift->(
          [302,
            ['Location' => '/xyz',"Content-Type" => 'text/html; charset=utf-8'],
              ['aaabbbccc']]) };
    };

    # test for delayed write
    mount '/delayed_write' => sub {
      my $env = shift;
      return sub {
        my $responder = shift;
        my $writer = $responder->(
          [302, ['Location' => '/xyz',"Content-Type" => 'text/html; charset=utf-8']]);
        $writer->write('aaabbbccc');
        $writer->close;
      }
    };

    mount '/delayed_nowrite' => sub {
      my $env = shift;
      return sub {
        my $responder = shift;
        my $writer = $responder->(
          [302, ['Location' => '/xyz']]);
        $writer->close;
      }
    };

    mount '/filehandle_like_empty' => sub {
        [302,
         [ "Location" => '/xyz' ],
         ,do {
            my @lines = ();
            Plack::Util::inline_object(getline => sub { shift @lines }, close => sub {});
         }];
    };
},
client => sub {
    my $cb = shift;

    my @responses = (
        [ '/empty_array',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
        [ '/empty_string',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
        [ '/array_with_one_undef',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
        [ '/first_undef_rest_def',
          qr!<body>Only first element was undef</body>!,
          302,
          'text/html; charset=utf-8' ],
        [ '/already_set_body',
          qr!<html><body>Body is set</body></html>!,
          302,
          'text/html; charset=utf-8' ],
        [ '/body_with_size_zero_file_handle',
          qr!<body>!,
          302,
          'text/html; charset=utf-8' ],
        [ '/body_with_good_file_handle',
          qr!<html><body>I'm file's text</body></html>!,
          302,
          'text/html; charset=utf-8' ],
        [ '/zeros_only',
          qr!^0!,
          302,
          'text/html; charset=utf-8' ],
        [ '/empty_strings_body',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
        [ '/filehandle_like',
          qr!aaa\nbbb\n!,
          302,
          'text/html; charset=utf-8' ],
        [ '/delayed_tuple',
          qr!aaabbbccc!,
          302,
          'text/html; charset=utf-8' ],
        [ '/delayed_write',
          qr!aaabbbccc!,
          302,
          'text/html; charset=utf-8' ],
        [ '/delayed_nowrite',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
        [ '/filehandle_like_empty',
          qr/<body>/,
          302,
          'text/html; charset=utf-8' ],
    );

    foreach my $response ( @responses ) {
        my @response_array = @$response;
        my $route          = $response_array[0],
        my $content        = $response_array[1];
        my $response_code  = $response_array[2];
        my $content_type   = $response_array[3];
        my $res            = $cb->(GET $route);

        like( $res->content,
              $content,
              "Content for $route matches $content");

        is( $res->code,
            $response_code,
            "Response code for $route is $response_code" );

        is( $res->header('Content-Type'),
            $content_type,
            "Content-Type for $route is $content_type");

        next if !defined $res->header('Content-Length');
        my $content_length = length( $res->content );
        is( $res->header('Content-Length'),
            $content_length,
            "Content-Length for $route is correct (${content_length})");
    }
};

unlink "output.txt";
