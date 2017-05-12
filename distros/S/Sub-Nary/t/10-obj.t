#!perl -T

use strict;
use warnings;

use Test::More tests => 6 + 1 * 2;

use Sub::Nary;

my $sn = new Sub::Nary;
ok(defined $sn, 'SN object is defined');
is(ref $sn, 'Sub::Nary', 'SN object is valid');

my $sn2 = $sn->new;
ok(defined $sn2, 'SN::new called as an object method works' );
is(ref $sn2, 'Sub::Nary', 'SN::new called as an object method works is valid');

my $sn3 = Sub::Nary::new();
ok(defined $sn3, 'SN::new called as a function works ');
is(ref $sn3, 'Sub::Nary', 'SN::new called as a functions returns a Sub::Nary object');

my $fake = { };
bless $fake, 'Sub::Nary::Hlagh';
for (qw/flush/) {
 eval "Sub::Nary::$_('Sub::Nary')";
 like($@, qr/^First\s+argument/, "SN::$_ isn't a class method");
 eval "Sub::Nary::$_(\$fake)";
 like($@, qr/^First\s+argument/, "SN::$_ only applies to SN objects");
}
