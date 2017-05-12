use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Mojo::Util 'encode';
use Test::Mojo;
use Data::Dumper;

plugin 'TemplatePerlish';

get '/inline/:foo' => { handler => 'tp', inline => '[% foo %] ☃' };
get '/data/:foo' => { handler => 'tp' } => 'data_section';
get '/tmpl/:foo' => { handler => 'tp' } => 'tmpl_file';

my $t = Test::Mojo->new;

$t->get_ok('/inline/bar')->content_is('bar ☃');
is $t->tx->res->body, encode('UTF-8', 'bar ☃'), 'right encoded content';
$t->get_ok('/data/bar')->content_is("bar ☃\n");
is $t->tx->res->body, encode('UTF-8', "bar ☃\n"), 'right encoded content';
$t->get_ok('/tmpl/bar')->content_is("bar ☃\n");
is $t->tx->res->body, encode('UTF-8', "bar ☃\n"), 'right encoded content';

done_testing();

__DATA__

@@ data_section.html.tp
[% foo %] ☃
__END__
