#!/usr/bin/env perl -w
use strict;
use Test::More tests => 3;
use FindBin qw($Bin);

use Railsish::View;

my $view = Railsish::View->new(
    template_root => "$Bin/app2/app/views"
);

{
    my $html = $view->render("welcome/index", layout => undef);
    is $html,"<h1>Welcome</h1>\n";
}

{
    my $html = $view->render("welcome/index");
    like $html, qr/Welcome/;
}

{
    my $html = $view->render(file => "welcome/index.html.tt2");
    like $html, qr/Welcome/;
}
