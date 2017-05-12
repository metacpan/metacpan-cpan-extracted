use Test::More tests => 3;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server

use Mojolicious::Lite;

plugin 'zombie_apocalypse';

get '/' => sub {
    shift->render(text => 'No Zombies detected');
};

# Tests
my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('No Zombies detected');

# Segfault will not return any more tests, so Test::More will not complain
my $pid = fork;
$t->get_ok('/brains') if !$pid;
waitpid $pid, 0;
