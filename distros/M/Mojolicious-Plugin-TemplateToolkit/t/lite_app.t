use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Mojo::Util 'encode';
use Test::Mojo;

plugin 'TemplateToolkit';

get '/inline/:foo' => { handler => 'tt2', inline => '[% foo %] ☃' };
get '/data/:foo' => { handler => 'tt2' } => 'data_section';
get '/tmpl/:foo' => { handler => 'tt2' } => 'tmpl_file';
get '/empty' => { handler => 'tt2' };

my $t = Test::Mojo->new;

$t->get_ok('/inline/bar')->content_is('bar ☃');
is $t->tx->res->body, encode('UTF-8', 'bar ☃'), 'right encoded content';
$t->get_ok('/data/bar')->content_is("bar ☃\n");
is $t->tx->res->body, encode('UTF-8', "bar ☃\n"), 'right encoded content';
$t->get_ok('/tmpl/bar')->content_is("bar ☃\n");
is $t->tx->res->body, encode('UTF-8', "bar ☃\n"), 'right encoded content';
$t->get_ok('/empty')->status_is(200)->content_is('');

done_testing;

__DATA__

@@ empty.html.tt2

@@ data_section.html.tt2
[% foo %] ☃
__END__
