use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
plugin pager => {always_show_prev_next => 1};

get
  '/' => {total_items => 91},
  'default';

my $t = Test::Mojo->new;

$t->get_ok('/?page=1')->status_is(200)->element_exists_not('a.prev')->element_exists('a.first')
  ->element_exists('a.next');

$t->get_ok('/?page=2')->status_is(200)->element_exists('a.prev')->element_exists('a.first')
  ->element_exists('a.next');

$t->get_ok('/?page=5')->status_is(200)->element_exists('a.prev')->element_exists('a.first')
  ->element_exists_not('a.next');


done_testing;
__DATA__
@@ default.html.ep
<ul class="pager">
  % for my $page (pages_for) {
    <li><%= pager_link $page %></li>
  % }
</ul>
