#!/usr/bin/env perl

use Mojolicious::Lite;
use lib qw(lib ../lib);

plugin 'Parametry';

get '/' => 'index';

app->start;

__DATA__

@@ index.html.ep

<form action="/" method=GET>
<p>Param meow_meow has value <%= P->meow_meow %></p>
<input name=meow_meow><button>Submit</button>
</form>
