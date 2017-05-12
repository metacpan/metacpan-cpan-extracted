use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'StaticLog';

# Plugin should have no effect on normal dynamic and static requests..

get '/' => sub { shift->render(text => 'dynamic content') };

my $t   = Test::Mojo->new;

# dynamic behaviour still working like normal..
$t->get_ok('/')->status_is(200)->content_is('dynamic content');

# static rendering working like normal..
$t->get_ok('/one-eyed.txt')->status_is(200);

done_testing();

