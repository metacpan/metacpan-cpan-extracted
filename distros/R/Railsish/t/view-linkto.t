#!/usr/bin/env perl -w
use strict;
use Test::More tests => 3;

use Railsish::ViewHelpers;

{
    my $html = link_to("Dashboard", "/dashboard", class => "nav");
    is($html, qq{<a href="/dashboard" class="nav">Dashboard</a>});
}

{
    my $html = link_to("<>!", "/dashboard", class => "nav");
    is($html, qq{<a href="/dashboard" class="nav">&lt;&gt;!</a>});
}

{
    my $html = link_to("<>!", "/dashboard", class => "<>!");
    is($html, qq{<a href="/dashboard" class="&lt;&gt;!">&lt;&gt;!</a>});
}
