# -*-CPerl-*-
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

our @urls = ();

plugin 'Loco',
  browser              => sub { push @urls, $_[0] },
  _test_browser_launch => 1;                           # not called

get '/' => { text => "works" };

my $t = Test::Mojo->new;
$t->get_ok('/');
is scalar @urls, 1, 'Browser::Open once';
$t->status_is(200)->content_is('works');
like $urls[0], qr!\Qhttp://127.0.0.1/hb/init?s=\E[0-9a-f]+$!,
  'Browser::Open right url';

done_testing();
