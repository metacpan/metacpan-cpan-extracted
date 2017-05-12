
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{
use 5.006; use strict; use warnings;
package Whatever;
},
  q{#!/usr/bin/perl
use 5.006;
use strict 'refs';
package Thinger;
my $x = 1;
},
  q{
use strict;
use warnings 'once';
package Foo;
our $x = 10;
},
);


my @not_ok = (
  q{
use strict;
use Carp;
package Yourface;
carp "Hello!";
},
  q{
$x = 10; use strict;
package Thinger;
},
);

my @custom_config = map { { allowed_pragmata => $_ } }
  ('strict warnings autodie', 'warnings fields perlversion' );

my @custom_config_ok = (
  q{
use strict;
use autodie qw(open);
package Ing;
my $x = 1;
},
  q{
use 5.006;
use warnings;
use fields qw(foo bar);
package D;
my $x = 1;
},
);

my @custom_config_not_ok = (
  q{
use 5.006;
use strict;
use autodie qw(open);
package Ed;
my $x = 1;
},
  q{
use strict;
use warnings;
package D;
my $x = 1;
},
);

plan tests => @ok + @not_ok + @custom_config_ok + @custom_config_not_ok;

my $policy = 'Lax::RequireExplicitPackage::ExceptForPragmata';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with \@ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "\@not_ok[$i] is no good");
}

for my $i (0 .. $#custom_config_ok) {
  my $violation_count = pcritique($policy, \$custom_config_ok[$i], $custom_config[$i]);
  is($violation_count, 0, "nothing wrong with \@custom_config_ok[$i]");
}

for my $i (0 .. $#custom_config_not_ok) {
  my $violation_count = pcritique($policy, \$custom_config_not_ok[$i], $custom_config[$i]);
  is($violation_count, 1, "\@custom_config_not_ok[$i] is no good");
}
