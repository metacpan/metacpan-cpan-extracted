
use Test;

plan tests => 30;

my $body  = new Body;
my $sword = new Sword;

# NOTE: by "too mortal" I mean, something in the XS is decrementing the ref
# counter on $sword so the second call_method($sword, "cut_body") fails. :(
ok( $sword->cut_body($body), "ouch" ) for 1 .. 30;

package Body;
use Object::Previous;

sub new { return bless {}, "Body" }
sub hurt_us { my $po = previous_object(); $po->hurt_us }

package Sword;

sub new { return bless {}, "Sword" }
sub cut_body { my $this = shift; my $target = shift; $target->hurt_us }
sub hurt_us { "ouch" }
