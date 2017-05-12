#!/usr/bin/env perl

use Mojolicious::Lite;
use lib qw(lib ../lib);

plugin 'AntiSpamMailTo';

get '/' => 'index';

app->start;

__DATA__

@@ index.html.ep

<p><a
    href="<%== mailto_href 'zoffix@cpan.com' %>">
        Send me an email at <%== mailto 'zoffix@cpan.com' %>
</a></p>
