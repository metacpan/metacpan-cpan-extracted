use Mojo::Base -strict;
use Mojolicious::Lite;
use Test::More tests => 3;
use Test::Mojo;

plugin 'ParamExpand', max_array => 1;

my $qs = join '&', 'users.0=a', 'users.1=b';
my $t = Test::Mojo->new;
$t->get_ok("/exception?$qs")
    ->status_is(500)
    ->content_like(qr/limit exceeded/);

__DATA__
@@ exception.html.ep
<%= stash('exception')->message %>
