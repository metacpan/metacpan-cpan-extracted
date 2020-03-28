use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'DataTables';

my $t = Test::Mojo->new;

get '/dt_1' => 'dt_1';
$t->get_ok('/dt_1')->status_is(200)->element_exists('script[src]');

get '/dt_2' => 'dt_2';
$t->get_ok('/dt_2')->status_is(200)->element_exists('link[href]')->element_exists('link[rel]');

done_testing();

__DATA__

@@ dt_1.html.ep

%= datatable_js

@@ dt_2.html.ep

%= datatable_css
