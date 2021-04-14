use Test::More;

use Test::Mojo;

use Mojolicious::Lite;

plugin 'TextExceptions';

get '/'    => sub { die "horribly" };
get '/api' => [format => ['json']] => {format => undef} => sub { die "horribly" };

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is('500')->content_type_is('text/plain;charset=UTF-8')->content_like(qr/^horribly/);
$t->get_ok('/', {'User-Agent' => 'MyLittlePony/1.0'})->status_is('500')->content_type_is('text/html;charset=UTF-8')
  ->content_like(qr/<html>/);

$t->get_ok('/api.json')->status_is('500')->content_type_is('application/json;charset=UTF-8')
  ->json_is('/error', 'Yikes');

done_testing;

__DATA__
@@ exception.json.ep
{"error":"Yikes"}
