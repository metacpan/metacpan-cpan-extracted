use Test::More;

use Test::Mojo;

use Mojolicious::Lite;

plugin 'TextExceptions', ua_re => qr/^MyLittlePony/;

get '/' => sub { die "horribly" };

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is('500')->content_type_is('text/html;charset=UTF-8')->content_like(qr/<html>/);
$t->get_ok('/', {'User-Agent' => 'MyLittlePony/1.0'})->status_is('500')->content_type_is('text/plain;charset=UTF-8')
  ->content_like(qr/^horribly/);

done_testing;
