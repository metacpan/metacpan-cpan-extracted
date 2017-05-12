use Test::More tests => 14;
use Sub::PatMat;

ok(1, "load");

sub fact : when($_[0] <= 1) { 1 }
sub fact    { my ($n) = @_; $n*fact($n-1) }
ok(fact(6) == 720, "fact() correct");

sub mysort : when($a < $b)  { -1 }
sub mysort : when($a == $b) {  0 }
sub mysort : when($a > $b)  {  1 }
ok(join(",", sort mysort (3,1,2)) eq "1,2,3", "mysort() correct");

sub arg : when(@_ == 1) { 1 }
sub arg : when(@_ == 2) { 2 }
sub arg : when(@_ == 4) { 4 }
ok(arg(1) == 1, "arg 1");
ok(arg(1,2) == 2, "arg 2");
eval { arg(1,2,3) }; ok($@ =~ /Bad match/, "arg 3");
ok(arg(1,2,3,4) == 4, "arg 4");
eval { arg(1,2,3,4,5) }; ok($@ =~ /Bad match/, "arg 5");

use vars qw(@p %p);
@p = (1,2);
%p = (hehe => 1);
sub nohash : when($p[0] && $p{hehe}) {
	my ($p) = @_;
	1;
}
sub nohash { 2 }
ok(nohash(0) == 1, "nohash");

sub par : when($p2 == 3) {
	my ($p1, $p2, %pp) = @_;
	1;
}
sub par { 2 }
ok(par(1,2,x=>3) == 2, "second par nomatch");
ok(par(1,3,x=>4) == 1, "second par match");

package Another;
use Sub::PatMat;

sub dispatch : when($what eq "help") { my ($what) = @_; "HELP" }
sub dispatch : when($what eq "blah") { my ($what) = @_; "BLAH" }
Test::More::ok(dispatch("help") eq "HELP", "dispatch() correct 1");
Test::More::ok(dispatch("blah") eq "BLAH", "dispatch() correct 2");
eval { dispatch("hest") };
Test::More::ok($@ =~ /Bad match/, "bad match correct");
