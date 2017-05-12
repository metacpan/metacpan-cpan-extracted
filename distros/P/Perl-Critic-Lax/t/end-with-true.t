
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{
package Whatever;
1;
},
  q{
package Whatever;
return 1;
},
  q{
package Whatever;
return 0, 1;
},
  q{
package Whatever;
return "0e0";
},
  q{
package Whatever;
"This is your code on drugs.";
},
  q{
package Whatever;
return 0e0;
},
);

my @todo_ok = (
  q{
package Foo;
return (0, 0, 0, 1);
},
  q{
package Foo;
return ((((((((0), 1)))))));
},
);

my @not_ok = (
  q{
package Foo;
my $mystery_value = 1;
$mystery_value;
},
  q{
package Foo;
0;
},
  q{
package Foo;
"";
},
  q{
package Foo;
sub { die; }
},
);

plan tests => @ok + @todo_ok + @not_ok;

my $policy = 'Lax::RequireEndWithTrueConst';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with \@ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "\@not_ok[$i] is no good");
}

TODO: {
  local $TODO = "too lazy to bother just yet";
  for my $i (0 .. $#todo_ok) {
    my $violation_count = pcritique($policy, \$todo_ok[$i]);
    is($violation_count, 0, "\@todo_ok[$i] is no good");
  }
}

