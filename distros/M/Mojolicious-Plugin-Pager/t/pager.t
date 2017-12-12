use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

plugin 'pager';
helper pager_text => sub {
  my ($c, $page) = @_;
  return sub { $page->{prev} ? 'Prev' : $page->{next} ? 'Next' : $page->{n} };
};

get
  '/' => {total_entries => 1431, entries_per_page => 20},
  'default';

get
  '/custom' => {total_entries => 57, entries_per_page => 20},
  'custom';

get
  '/small' => {total_entries => 139, entries_per_page => 20, page_param_name => 'y'},
  'default';

get
  '/paged' => {total_entries => 1, entries_per_page => 20},
  'default';

get
  '/stash' => {pages_as_array_ref => 1, total_items => 57, items_per_page => 20},
  'stash';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->element_exists_not('a.last')->element_exists_not('a.prev')
  ->element_exists_not('a[href="/page=8"]')->element_count_is('a', 9)
  ->element_exists('a[href="/?page=1"].first.active')->element_exists('a[href="/?page=2"].page')
  ->element_exists('a[href="/?page=8"].page')->element_exists('a[href="/?page=2"].next');

$t->get_ok('/?page=3')->status_is(200)->element_exists_not('a.last')
  ->element_exists_not('a[href="/page=9"]')->element_count_is('a', 10)
  ->text_is('a[href="/?page=2"][rel="prev"].prev', 'Prev')
  ->text_is('a[href="/?page=4"][rel="next"].next', 'Next')
  ->element_exists('a[href="/?page=2"][rel="prev"].prev')
  ->element_exists('a[href="/?page=1"].first')->element_exists('a[href="/?page=3"].active')
  ->element_exists('a[href="/?page=8"].page')
  ->element_exists('a[href="/?page=4"][rel="next"].next');

$t->get_ok('/?page=4')->status_is(200)->element_exists_not('a.last')->element_exists_not('a.first')
  ->element_exists_not('a[href="/page=10"]')->element_count_is('a', 10)
  ->element_exists('a[href="/?page=3"].prev')->element_exists('a[href="/?page=4"].active')
  ->element_exists('a[href="/?page=9"].page')->element_exists('a[href="/?page=5"].next');

$t->get_ok('/?page=23')->status_is(200)->element_exists_not('a.last')
  ->element_exists_not('a.first')->element_exists_not('a[href="/page=29"]')
  ->element_count_is('a', 10)->element_exists('a[href="/?page=22"].prev')
  ->element_exists('a[href="/?page=23"].active')->element_exists('a[href="/?page=28"].page')
  ->element_exists('a[href="/?page=24"].next');

$t->get_ok('/?page=23')->status_is(200)->element_exists_not('a.last')
  ->element_exists_not('a.first')->element_exists_not('a[href="/page=29"]')
  ->element_count_is('a', 10)->element_exists('a[href="/?page=22"].prev')
  ->element_exists('a[href="/?page=23"].active')->element_exists('a[href="/?page=28"].page')
  ->element_exists('a[href="/?page=24"].next');

$t->get_ok('/?x=y&page=72')->status_is(200)->element_exists_not('a.first')
  ->element_exists_not('a.next')->element_exists_not('a[href="/x=y&page=73"]')
  ->element_count_is('a', 9)->element_exists('a[href="/?x=y&page=70"].page')
  ->element_exists('a[href="/?x=y&page=71"].prev')
  ->element_exists('a[href="/?x=y&page=72"].active.last');

for my $p (64 .. 71) {
  $t->get_ok("/?page=$p")->status_is(200)->element_exists('a.next')->element_count_is('a', 10)
    ->element_exists(qq(a[href="/?page=$p"].active));
}

$t->get_ok('/custom')->status_is(200)->element_count_is('a', 3)->text_is('a', 'hey!')
  ->element_exists('a[href="/custom?x=3"]');

$t->get_ok('/stash')->status_is(200)->element_count_is('a', 3)->text_is('a', 'hey!')
  ->element_exists('a[href="/stash?x=3"]');

$t->get_ok('/small?y=2')->status_is(200)->element_exists_not('a.prev')
  ->element_exists_not('a.next')->element_count_is('a', 7)
  ->element_exists('a[href="/small?y=1"].first')->element_exists('a[href="/small?y=2"].active')
  ->element_exists('a[href="/small?y=7"].last');

$t->get_ok('/paged?page=2')->status_is(200)->element_count_is('a', 1)->text_is('a', '1');

done_testing;

__DATA__
@@ default.html.ep
<ul class="pager">
  % for my $page (pages_for $total_entries / $entries_per_page) {
    <li><%= pager_link $page, pager_text($page) %></li>
  % }
</ul>
@@ custom.html.ep
<ul class="pager">
  % for my $page (pages_for $total_entries / $entries_per_page) {
    % my $url = url_with; $url->query->param(x => $page->{n});
    <li><%= link_to "hey!", $url %></li>
  % }
</ul>
@@ stash.html.ep
<ul class="pager">
  % for my $page (@{pages_for()}) {
    % my $url = url_with; $url->query->param(x => $page->{n});
    <li><%= link_to "hey!", $url %></li>
  % }
</ul>
