use strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

get '/' => sub { shift->render(text => 'Test') };

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->content_is('Test')
  ->header_is(Server => 'Mojolicious (Perl)');

plugin 'NoServerHeader';

$t->get_ok('/')
  ->content_is('Test');

ok not exists $t->tx->res->headers->to_hash->{Server};

done_testing;
