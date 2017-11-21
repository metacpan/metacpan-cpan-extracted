# RT 123582
print "1..1\n";

package TS;
sub TIESCALAR { bless ["tied"] }
sub FETCH     { $_[0][0] }

package main;

my ($a1, $a2);

$a1 = "plain";
tie $a2, 'TS';

use Set::Object;

my $set = Set::Object->new($a1, $a2);

my $members = join ',', $set->members;
my $ok = (($members eq 'plain,tied')
       or ($members eq 'tied,plain')) ? 1 : 0;

print 'not ' unless $ok;
print "ok 1\n";
print "# $members\n" unless $ok;
