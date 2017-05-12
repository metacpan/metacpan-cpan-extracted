use strict;
use warnings;

use Test::Most;
use MooseX::Params;

sub helem_create        :Args(foo)      { $_{bar} = 1 }
sub helem_assign_simple :Args(foo)      { $_{foo} = 1 }
sub helem_assign_alias  :Args(foo)      { $_ = 1 for @{$_{foo}} }
sub helem_assign_deep   :Args(foo)      { $_{foo}[2] = 1 }
sub helem_iter_alias    :Args(foo)      { 1 for @{$_{foo}} }
sub helem_return        :Args(foo)      { @{$_{foo}} }
sub hslice_assign       :Args(foo, bar) { @_{qw(foo bar)} = (1, 1) }
sub hslice_assign_alias :Args(foo, bar) { $_ = 1 for @_{qw(foo bar)} }
sub hslice_iter_alias   :Args(foo, bar) { 1 for @_{qw(foo bar)} }
sub hslice_return       :Args(foo, bar) { @_{qw(foo bar)} }

dies_ok  ( sub { helem_create(1) },           "helem create"           );
dies_ok  ( sub { helem_assign_simple(1) },    "helem simple assign"    );
lives_ok ( sub { helem_assign_alias([1,1]) }, "helem assign to alias"  );
lives_ok ( sub { helem_assign_deep([1,1]) },  "helem assign deep"      );
lives_ok ( sub { helem_iter_alias([1,1]) },   "helem iterate"          );
lives_ok ( sub { helem_return([1,1]) },       "helem return values"    );
dies_ok  ( sub { hslice_assign(1,1) },        "hslice assign"          );
dies_ok  ( sub { hslice_assign_alias(1,1) },  "hslice assign to alias" );
lives_ok ( sub { hslice_iter_alias(1,1) },    "hslice iterate"         );
lives_ok ( sub { hslice_return(1,1) },        "hslice return values"   );

done_testing;
