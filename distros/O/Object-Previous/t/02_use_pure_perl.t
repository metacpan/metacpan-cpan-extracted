
use Test;

plan tests=>1;

my $body  = new Body;
my $sword = new Sword;
   $sword->cut_body($body);

package Body;
use Object::Previous qw(pure_perl);
sub new { return bless {}, "Body" }
sub hurt_us { my $po = previous_object(); $po->hurt_us }

package Sword;
sub new { return bless {}, "Sword" }
sub cut_body { my $this = shift; my $target = shift; $target->hurt_us }
sub hurt_us {
    main::ok(1);
}
