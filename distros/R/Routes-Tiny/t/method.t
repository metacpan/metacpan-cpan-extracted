use strict;
use warnings;

use Test::More tests => 9;

use Routes::Tiny;

my $r = Routes::Tiny->new;

$r->add_route('/articles');
ok($r->match('articles'));

$r->add_route('/logout', method => 'get');
ok($r->match('logout', method => 'get'));
ok(!$r->match('logout', method => 'post'));
ok(!$r->match('logout'));

$r->add_route('/photos/:id', method => [qw/get post/]);
ok(!$r->match('photos/1'));
ok($r->match('photos/1', method => 'get'));
ok($r->match('photos/1', method => 'post'));
ok(!$r->match('photos/1', method => 'head'));

$r->add_route('/logout', method => 'gEt');
ok($r->match('logout', method => 'geT'));
