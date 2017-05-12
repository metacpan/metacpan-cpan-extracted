use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
plugin 'Renderer::WithoutCache';

my $log = "";
open my $fh, ">", \$log or die $!;
app->log->handle($fh);

get '/' => sub {
    my $c = shift;

    $c->render(template => 'foo');
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is("ok\n") for 1 .. 50;

unlike $log, qr/Rendering cached template/, 'Log does not contain anything about cached templates';

done_testing;

__DATA__

@@ foo.html.ep
ok
