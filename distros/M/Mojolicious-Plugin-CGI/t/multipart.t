use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/file_upload' => cgi_script('file_upload')];

my $t = Test::Mojo->new;

$t->post_ok(
  '/file_upload' => form => {
    mytext => [
      {file => 't/foo.txt'},
      {file => 't/bar.txt'},
      {file => 't/test_file_with_a_long_filename.txt'},
    ]
  }
);
$t->status_is(200);

$t->content_like(
  qr{^\d+
=== multipart/form-data; boundary=(\w+)
=== \d+
--- --\1\r
--- Content-Disposition: form-data; name="mytext"; filename="foo\.txt"\r
--- \r
--- some more
--- data
--- \r
--- --\1\r
--- Content-Disposition: form-data; name="mytext"; filename="bar\.txt"\r
--- \r
--- even more
--- data here
--- \r
--- --\1\r
--- Content-Disposition: form-data; name="mytext"; filename="test_file_with_a_long_filename\.txt"\r
--- \r
--- and yet more
--- data in here
--- \r
--- --\1--}s
);

done_testing;
