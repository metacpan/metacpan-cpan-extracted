#!/usr/bin/env perl

use Test::More;
use Test::Mojo;
use lib 'lib';

use Mojolicious::Lite;
#~ plugin 'JSUrlFor::Angular';
get '/test_route' => sub { } => 'тестовый маршрут';

my $t = Test::Mojo->new(__PACKAGE__);

  my $stdout = command($t);
  #~ warn $stdout;
  like $stdout, qr/тестовый маршрут/, 'right route';
  like $stdout, qr/function url_for\(route_name, captures, param\) \{/, 'right route';


sub command {
    my $t = shift;
    my $stdout;
    local *STDOUT;
    #~ binmode(STDOUT, ":utf8");
    open(STDOUT, ">", \$stdout);
    $t->app->commands->run(qw(generate js_url_for_angular));
    utf8::decode($stdout);
    return $stdout;
}

done_testing;
