use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';

package WithBar;
use Moo;
use Foo plugins => ['Bar'];
use Foo::A;
use Foo::B;
has a => ( is => 'ro', lazy => 1, default => sub { Foo::A->new } );
has b => ( is => 'ro', lazy => 1, default => sub { Foo::B->new } );

package WithBaz;
use Moo;
use Foo plugins => ['Baz'];
use Foo::A;
use Foo::B;
has a => ( is => 'ro', lazy => 1, default => sub { Foo::A->new } );
has b => ( is => 'ro', lazy => 1, default => sub { Foo::B->new } );

package WithBarBaz;
use Moo;
use Foo plugins => [ 'Bar', 'Baz' ];
use Foo::A;
use Foo::B;
has a => ( is => 'ro', lazy => 1, default => sub { Foo::A->new } );
has b => ( is => 'ro', lazy => 1, default => sub { Foo::B->new } );

package main;

my $with_bar = WithBar->new;

isa_ok( $with_bar->a, 'Foo::A' );
can_ok( $with_bar->a, 'a' );
can_ok( $with_bar->a, 'bar_a' );

isa_ok( $with_bar->b, 'Foo::B' );
can_ok( $with_bar->b, 'b' );
ok( !$with_bar->b->can('baz_b'), 'no Foo::B->baz_b in WithBar' );

my $with_baz = WithBaz->new;

isa_ok( $with_baz->a, 'Foo::A' );
can_ok( $with_baz->a, 'a' );
can_ok( $with_baz->a, 'baz_a' );
ok( !$with_baz->a->can('bar_a'), 'no Foo::A->bar_a in WithBaz' );

isa_ok( $with_baz->b, 'Foo::B' );
can_ok( $with_baz->b, 'b' );
can_ok( $with_baz->b, 'baz_b' );

my $with_bar_baz = WithBarBaz->new;

isa_ok( $with_bar_baz->a, 'Foo::A' );
can_ok( $with_bar_baz->a, 'a' );
can_ok( $with_bar_baz->a, 'bar_a' );
can_ok( $with_bar_baz->a, 'baz_a' );

isa_ok( $with_baz->b, 'Foo::B' );
can_ok( $with_baz->b, 'b' );
can_ok( $with_baz->b, 'baz_b' );

done_testing;
