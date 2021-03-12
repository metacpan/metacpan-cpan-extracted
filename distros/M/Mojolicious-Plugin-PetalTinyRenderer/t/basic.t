use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'PetalTinyRenderer';
app->defaults(
    foo => "bar",
    collection => Mojo::Collection->new(1,2,3,"foo"),
);

get '/inline' => sub {
    shift->render(inline => "<div tal:content='foo'/>\n", handler => 'tal');
};
for ( qw/ data ns file h c mc / ) {
    get "/$_";
}

my $t = Test::Mojo->new;
for ( qw/ data ns file h c inline / ) {
    $t->get_ok("/$_")->status_is(200)->content_is("<div>bar</div>\n");
}
$t->get_ok("/mc")->status_is(200)->content_is("123foo\n");

$t->get_ok('/missing')->status_is(404);

done_testing();

__DATA__
@@ data.html.tal
<div tal:content="foo"/>
@@ ns.html.tal
<div xmlns:fun="http://purl.org/petal/1.0/"><span fun:replace="foo"/></div>
@@ h.html.tal
<div tal:content="h/stash --foo"/>
@@ c.html.tal
<div tal:content="c/stash --foo"/>
@@ mc.html.tal
<span tal:repeat="val collection" tal:replace="val"/>
