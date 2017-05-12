#  -*- perl -*-
#
#  Storable test for Set::Object objects

use strict;

BEGIN {
    eval "use Storable qw(freeze thaw dclone)";
    if ($@) {
	eval 'use Test::More skip_all => "Storable not installed"';
	exit(0);
    } else {
	eval 'use Test::More tests => 7';
    }
}

use_ok("Set::Object", qw(refaddr));
my $objects = [ map { bless { $_ => rand(42) }, $_ }
		qw(Barnie Fred Wilma)                 ];

my $stored = freeze ($objects);
is_deeply(thaw($stored), $objects, "Storable works");

my $set = Set::Object->new(@$objects);
$stored = freeze($set);

use Data::Dumper;
#print Dumper $stored;

my $returned = thaw($stored);
#print "no segfault yet!\n";
#diag(Dumper($returned, $set));
is_deeply([ sort { ref($a) cmp ref($b) } $returned->members ],
	  [ sort { ref($a) cmp ref($b) } $set->members ],
	  "Set::Object serialises via Storable!");
isnt($$returned, $$set, "thaw returned a new Set::Object");

my $spawned = dclone($set);
is_deeply([ sort { ref($a) cmp ref($b) } $spawned->members ],
	  [ sort { ref($a) cmp ref($b) } $set->members ],
	  "Set::Object dclones via Storable!");
isnt($$spawned, $$set, "dclone returned a new Set::Object");

my $old;
my $test = dclone ($old = [ map { Set::Object->new() } (1..1000) ]);

is(@$old, @$test, "empty sets");

