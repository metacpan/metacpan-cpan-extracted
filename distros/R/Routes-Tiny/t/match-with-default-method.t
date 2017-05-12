use strict;
use warnings;

use Test::More tests => 4;

use Routes::Tiny;

my $r = Routes::Tiny->new( default_method => 'GET' );

$r->add_route('/articles');
$r->add_route('/another', method => 'PUT');

ok($r->match('articles', method => 'GET'));
ok(!$r->match('articles', method => 'POST'));
ok($r->match('another', method => 'PUT'));
ok(!$r->match('another', method => 'GET'));
