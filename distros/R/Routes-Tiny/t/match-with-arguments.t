use strict;
use warnings;

use Test::More tests => 1;

use Routes::Tiny;

my $r = Routes::Tiny->new;

$r->add_route('/articles', arguments => {foo => 'bar'});

my $m = $r->match('articles');
is_deeply($m->arguments, {foo => 'bar'});
