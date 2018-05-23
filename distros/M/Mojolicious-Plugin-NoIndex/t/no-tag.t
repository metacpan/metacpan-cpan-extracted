use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'NoIndex';

get '/' => sub {
    my $c = shift;
    $c->render( 'index' );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is("test\n");

done_testing();

__DATA__
@@ index.html.ep
test

