#!/usr/bin/env perl
# Demonstrate the add -> compile -> match -> add -> compile cycle.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

my $r = Router::Ragel->new->add('/a', 'A')->compile;
printf "before: /a -> %s\n", scalar $r->match('/a');

# Adding a route invalidates the compiled state. The next match will croak.
$r->add('/b', 'B');
eval { $r->match('/a') };
print "caught (expected): $@" if $@;

# Recompile to bring /b online; /a is still there.
$r->compile;
printf "after:  /a -> %s\n", scalar $r->match('/a');
printf "after:  /b -> %s\n", scalar $r->match('/b');
