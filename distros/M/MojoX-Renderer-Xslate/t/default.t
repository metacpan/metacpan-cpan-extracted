use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

# Silence
app->log->level('fatal');

plugin 'xslate_renderer';

get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is("Hello, Xslate world!\n");

done_testing;

__DATA__

@@ index.html.tx
Hello, <: "Xslate" :> world!
