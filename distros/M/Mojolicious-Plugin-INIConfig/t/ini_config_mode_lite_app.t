use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More 'no_plan';
use Mojolicious::Lite;
use Test::Mojo;

# Load plugin
plugin 'INIConfig';

get '/' => 'index';

my $t = Test::Mojo->new;

# Template with config information
$t->get_ok('/')->status_is(200)->content_like(qr/bazfoo/);

__DATA__
@@ index.html.ep
<%= $config->{section}{foo} %><%= $config->{section}{bar} %>
