package WebApp;
use Mojo::Base -strict;

use Mojolicious::Lite;

plugin 'ViewBuilder';
push @{ app->plugins->namespaces }, 'Test';
plugin 'TestPlugin';

get '/' => sub {
    shift->render(
        template  => "pluggable",
    );
};
app->start;
1;
__DATA__
@@ pluggable.html.ep
<%=pluggable_view('activity')%>