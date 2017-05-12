
die "you're not running this right, use make test" unless -d "blib/lib";
BEGIN { unshift @INC, "blib/lib" }

use strict;
use warnings;
use Term::GentooFunctions qw(:all);
use Data::Dumper;

$Data::Dumper::Sortkeys = "hell yes!!";

equiet(1) if $ENV{SHH_QUIET};

my $r1 = edo "list2sclr returns " => sub { return (1,2,3,4) };
einfo Dumper(\$r1);

my @r2 = edo "list2arr returns " => sub { return (1,2,3,4) };
einfo Dumper(\@r2);

my @r3 = edo "arr2arr returns " => sub { my @a = (1,2,3,4); @a };
einfo Dumper(\@r3);

my %r4 = edo "list2hash returns " => sub { return (1,2,3,4) };
einfo Dumper(\%r4);

my %r5 = edo "hash2hash returns " => sub { my %h = (1,2,3,4); %h };
einfo Dumper(\%r5);
