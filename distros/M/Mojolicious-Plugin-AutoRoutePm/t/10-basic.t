use Mojo::Base -strict;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;
use Mojo::File 'path';
use lib;


my $site = path(__FILE__)->sibling('site')->to_string;
lib->import($site);
push @{app->renderer->paths}, $site;

plugin 'AutoRoutePm', {
		route 			=> [ app->routes ],
        top_dir => 'site',
};


my $t = Test::Mojo->new;

$t->get_ok('/welcome')->status_is(200)->content_is("Welcome\n");

done_testing();
