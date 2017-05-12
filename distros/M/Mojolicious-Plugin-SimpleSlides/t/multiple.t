use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'SimpleSlides';

my $t = Test::Mojo->new;

$t->get_ok('/0')
  ->status_is(404);

$t->get_ok('/4')
  ->status_is(404);

sub gen_subtest {
  my ($t, $page, $text, $prev, $next) = @_;
  return sub {
    $t->get_ok($page)
      ->status_is(200)
      ->text_like( '#main' => qr/$text/ );

    my $dom = $t->tx->res->dom;
    my @nav = $dom->find('.nav a')->map(sub{$_->{href}})->each;
    is $nav[0], $prev, "prev is $prev";
    is $nav[1], $next, "next is $next";
  }
}

subtest 'page 1 (unset last_slide)' => gen_subtest($t, '/1', 'Hello World', '/', '/');

app->simple_slides->last_slide(3);

subtest 'page 1' => gen_subtest($t, '/1', 'Hello World', '/', '/2');
subtest 'page 2' => gen_subtest($t, '/2', 'Hello Cleveland', '/', '/3');
subtest 'page 3' => gen_subtest($t, '/3', 'Hello Tokyo', '/2', '/3');

done_testing;

__DATA__

@@ 1.html.ep

Hello World

@@ 2.html.ep

Hello Cleveland

@@ 3.html.ep

Hello Tokyo

