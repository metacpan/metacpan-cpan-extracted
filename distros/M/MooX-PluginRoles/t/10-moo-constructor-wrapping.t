use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Hook::LexWrap;

use lib 't/lib';

package WithBar;
use Moo;
use Foo plugins => ['Bar'];
use Foo::A;
has a => ( is => 'ro', default => sub { Foo::A->new } ); # not lazy

package main;

# track number of times new is called
# NOTE: this test detects problems with wrapping constructors in Moo
my $new_count = 0;
wrap *Foo::A::new => (
    pre => sub { $new_count++ },
);

my $exp_count = 0;

my $with_bar = WithBar->new;
$exp_count++;
isa_ok( $with_bar->a, 'Foo::A' );
can_ok( $with_bar->a, 'a' );
can_ok( $with_bar->a, 'bar_a' );

is($new_count, $exp_count, "new called only once");

done_testing;
