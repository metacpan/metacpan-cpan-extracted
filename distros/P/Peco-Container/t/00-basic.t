use lib './lib';

use strict;
use warnings;

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );
ok( $c->is_empty );
ok( $c->count == 0 );
$c->register( 'key1', 'scalar' );

ok( not $c->is_empty );
ok( $c->contains('key1') );
ok( $c->spec('key1') );
ok( $c->count == 1 );
ok( $c->service('key1') eq 'scalar' );

