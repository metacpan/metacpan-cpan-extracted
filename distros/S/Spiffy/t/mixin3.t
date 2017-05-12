use lib 't', 'lib';
package AAA;
use Spiffy -Base;

package BBB;
use Spiffy -Base;
field foo => 42;


package main;
use Test::More tests => 1;

my $a = AAA->new;
$a->mixin('BBB');
is($a->foo, 42);
