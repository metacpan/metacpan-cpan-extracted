#!perl

use Mojolicious::Lite;

# VERSION

plugin 'Breadcrumbs';

get '/user/account-settings' => 'account-settings';

app->start;

__DATA__

@@ account-settings.html.ep

You are at <%== breadcrumbs %>