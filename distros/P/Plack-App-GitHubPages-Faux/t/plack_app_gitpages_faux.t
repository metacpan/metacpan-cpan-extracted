use utf8;
use Test2::V0 -no_srand => 1;
use Plack::App::GitHubPages::Faux;
use Importer 'Test2::Tools::HTTP' => ':short';
use HTTP::Request::Common;
use Path::Tiny qw( path );
use Test2::Todo;

foreach my $root (path('corpus')->children)
{
  my $url  = "http://@{[ $root->basename ]}";

  my $app = Plack::App::GitHubPages::Faux->new(root => "$root")->to_app;

  note "adding app at $url";
  app_add $url => $app;
}

req
  GET('http://something1.test/ascii.html'),
  res {
    code 200;
    content "<html>some html</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'normal ascii html file';

tx->note;

req
  GET('http://something1.test/unicode.html'),
  res {
    code 200;
    content "<html>龍</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'normal utf-8 html file';

tx->note;

req
  GET('http://something1.test/notfound'),
  res {
    code 404;
    content_type 'text/plain';
  },
  'normal not found';

tx->note;

req
  GET('http://something1.test/ascii.html'),
  res {
    code 200;
    content "<html>some html</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'normal ascii html file';

tx->note;

my $todo = Test2::Todo->new( reason => 'redirecting to / would probably be more correct' );

req
  GET('http://something1.test'),
  res {
    code 301;
    location '/';
  },
  'main page';

tx->note;

$todo->end;

req
  GET('http://something1.test/'),
  res {
    code 200;
    content "<html>an index 1</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'index file';

req
  GET('http://something1.test/dir'),
  res {
    code 301;
    location '/dir/';
  },
  'redirect to trailing slash';

tx->note;

req
  GET('http://something1.test/dir/'),
  res {
    code 200;
    content "<html>an index 2</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'index file';

tx->note;

req
  GET('http://custom404.test/missing'),
  res {
    code 404;
    content "<html>custom 404</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  'custom 404 page';

tx->note;

req
  GET('http://custom404.test/'),
  res {
    code 404;
    content "<html>custom 404</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  '404 on root with no /index.html';

tx->note;

req
  GET('http://custom404.test'),
  res {
    code 404;
    content "<html>custom 404</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  '404 on root with no /index.html without redirect';

tx->note;

req
  GET('http://custom404.test/foo/'),
  res {
    code 404;
    content "<html>custom 404</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  '404 on directory with no index.html without redirect';

tx->note;

req
  GET('http://custom404.test/foo'),
  res {
    code 404;
    content "<html>custom 404</html>\n";
    content_type 'text/html';
    charset 'UTF-8';
    content_length_ok;
  },
  '404 on directory with no index.html without redirect';

tx->note;

done_testing
