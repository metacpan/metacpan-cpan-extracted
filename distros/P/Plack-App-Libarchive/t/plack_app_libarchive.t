use Test2::V0 -no_srand => 1;
use 5.034;
use utf8;
use experimental qw( postderef );
use Plack::App::Libarchive;
use Test2::Tools::HTTP;
use Test2::Tools::DOM;
use HTTP::Request::Common;
use Plack::Builder ();
use Mojo::DOM58;
use Path::Tiny qw( path );
use URI;

psgi_app_add(Plack::App::Libarchive->new(archive => 'corpus/foo.tar')->to_app);

subtest 'index' => sub {

  http_request (
    GET('/'),
    http_response {
      http_code 200;
      http_content_type 'text/html';
      http_content_type_charset 'UTF-8';
      http_content dom {
        find 'title' => [
          dom { content 'foo.tar' }
        ];
        find 'ul li a' => [
          dom { attr href => 'foo.html'; content 'foo.html' },
          dom { attr href => 'foo.txt';  content 'foo.txt'  },
          dom { attr href => 'shot.png'; content 'shot.png' },
        ];
      };
    },
  );

  note http_tx->res->as_string;

};

subtest 'fetch entry' => sub {

  subtest 'foo.txt' => sub {

    http_request (
      GET('/foo.txt'),
      http_response {
        http_code 200;
        http_content_type 'text/plain';
        http_content_type_charset 'UTF-8';
        http_content "Hello World\n";
      }
    );

    note http_tx->res->as_string;

  };

  subtest 'foo.html' => sub {

    http_request (
      GET('/foo.html'),
      http_response {
        http_code 200;
        http_content_type 'text/html';
        http_content_type_charset 'UTF-8';
        http_content dom {
          find 'p' => [
            dom { content 'Hello World' },
            dom { content '龍' },
          ];
        };
      }
    );

    note http_tx->res->decoded_content;

  };

  subtest 'shot.png' => sub {

    http_request (
      GET('/shot.png'),
      http_response {
        http_code 200;
        http_content_type 'image/png';
        http_content path('corpus/shot.png')->slurp_raw;
      }
    );

    note http_tx->res->headers->as_string;

  };

  subtest 'favicon.ico (default)' => sub {

    http_request (
      GET('/favicon.ico'),
      http_response {
        http_code 200;
        http_content_type 'image/vnd.microsoft.icon';
        http_content path('share/favicon.ico')->slurp_raw;
      }
    );

  };

};

subtest '404' => sub {

  http_request (
    GET('/frooble-bits.txt'),
    http_response {
      http_code 404;
      http_content_type 'text/plain';
      http_content 'Not Found';
    },
  );

  note http_tx->res->as_string;

};

subtest 'mount elsewhere' => sub {

  my $guard = psgi_app_add( 'http://mount-point.test' => do {
    my $builder = Plack::Builder->new;
    $builder->mount('/frooble' => Plack::App::Libarchive->new(archive => 'corpus/foo.tar')->to_app);
    $builder->to_app;
  });

  my $url = URI->new('http://mount-point.test/frooble');

  http_request (
    GET($url),
    http_response {
      http_code 301;
      http_header 'location', '/frooble/';
    }
  );

  $url->path(http_tx->res->header('location'));

  http_request (
    GET($url),
    http_response {
      http_code 200;
      http_content_type 'text/html';
      http_content dom {
        find 'title' => [
          dom { content 'foo.tar' }
        ];
        find 'ul li a' => [
          dom { attr href => 'foo.html' },
          dom { attr href => 'foo.txt'  },
          dom { attr href => 'shot.png' },
        ]
      }
    }
  );

  foreach my $href (map { $_->attr('href') } Mojo::DOM58->new(http_tx->res->decoded_content)->find('ul li a')->to_array->@*)
  {
    my $url = URI->new_abs( $href, $url );

    http_request (
      GET($url),
      http_response {
        http_code 200;
      }
    );
  }

};

subtest 'tar with favicon.ico' => sub {

  my $guard = psgi_app_add( 'http://favicon.test' => Plack::App::Libarchive->new(archive => 'corpus/fav.tar')->to_app );

  my $url = URI->new('http://favicon.test/favicon.ico');

  http_request (
    GET($url),
    http_response {
      http_code 200;
      http_content_type 'image/vnd.microsoft.icon';
      http_content "xxx\n";
    }
  );

};

done_testing;
