use String::Approx 'aslice';
use Test::More tests => 20;

@s = aslice("xyz", "abcdef");
is(@s, 1);
is(@{$s[0]}, 0);

@s = aslice("xyz", "abcdefxyzghi");
is(@s, 1);
is($s[0]->[0], 6);
is($s[0]->[1], 4);;

@s = aslice("xyz", ["i"], "ABCDEFXYZGHI");
is(@s, 1);
is($s[0]->[0], 6);
is($s[0]->[1], 4);

@s = aslice("xyz", ["minimal_distance"], "abcdefx!yzghi");
print "# @{$s[0]}\n";
is(@s, 1);
is($s[0]->[0], 6);
is($s[0]->[1], 4);
is($s[0]->[2], 1);

@s = aslice("xyz", ["minimal_distance"], "abcdefxzghi");
print "# @{$s[0]}\n";
is(@s, 1);
is($s[0]->[0], 6);
is($s[0]->[1], 2);
is($s[0]->[2], 1);

@s = aslice("xyz", ["minimal_distance"], "abcdefx!zghi");
print "# @{$s[0]}\n";
is(@s, 1);
is($s[0]->[0], 6);
is($s[0]->[1], 3);
is($s[0]->[2], 1);

# that's it.
