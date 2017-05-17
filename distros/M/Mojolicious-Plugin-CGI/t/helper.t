use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin "CGI";

get
  "/cgi-bin/#script_name/*path_info" => {path_info => ''},
  sub {
  my $c           = shift;
  my $script_name = $c->stash('script_name');
  $script_name = "$script_name.cgi" unless $script_name =~ /\.cgi$/;
  $c->cgi->run(script => File::Spec->rel2abs(cgi_script($script_name)));
  };

my $t = Test::Mojo->new;

$t->get_ok('/cgi-bin/nope.cgi/foo')->status_is(500)->content_like(qr{Could not run CGI script});

$t->get_ok('/cgi-bin/env.cgi/some/path/info?query=123')->status_is(200)
  ->content_like(qr{^PATH_INFO=/some/path/info}m,               'PATH_INFO')
  ->content_like(qr{^QUERY_STRING=query=123}m,                  'QUERY_STRING')
  ->content_like(qr{^SCRIPT_FILENAME=\S+/t/cgi-bin/env\.cgi$}m, 'SCRIPT_FILENAME')
  ->content_like(qr{^SCRIPT_NAME=/cgi-bin/env\.cgi$}m,          'SCRIPT_NAME');

$t->get_ok('/cgi-bin/env/some/path/info?query=123')->status_is(200)
  ->content_like(qr{^PATH_INFO=/some/path/info}m,               'PATH_INFO')
  ->content_like(qr{^QUERY_STRING=query=123}m,                  'QUERY_STRING')
  ->content_like(qr{^SCRIPT_FILENAME=\S+/t/cgi-bin/env\.cgi$}m, 'SCRIPT_FILENAME')
  ->content_like(qr{^SCRIPT_NAME=/cgi-bin/env$}m,               'SCRIPT_NAME');

done_testing;
