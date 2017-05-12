#!perl -T

use strict;
use warnings;

use Test::More tests => 24;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new;
ok(defined $rw, 'RW object is defined');
is(ref $rw, 'Regexp::Wildcards', 'RW object is valid');

my $rw2 = $rw->new;
ok(defined $rw2, 'RW::new called as an object method works' );
is(ref $rw2, 'Regexp::Wildcards', 'RW::new called as an object method works is valid');

$rw2 = Regexp::Wildcards::new();
ok(defined $rw2, 'RW::new called without a class works');
is(ref $rw2, 'Regexp::Wildcards', 'RW::new called without a class is valid');

eval { $rw2 = Regexp::Wildcards->new(qw<a b c>) };
like($@, qr/Optional\s+arguments/, 'RW::new gets parameters as key => value pairs');

my $fake = { };
bless $fake, 'Regexp::Wildcards::Hlagh';
for (qw<do capture type convert>) {
 eval "Regexp::Wildcards::$_('Regexp::Wildcards')";
 like($@, qr/^First\s+argument/, "RW::$_ isn't a class method");
 eval "Regexp::Wildcards::$_(\$fake)";
 like($@, qr/^First\s+argument/, "RW::$_ only applies to RW objects");
}

for (qw<do capture>) {
 eval { $rw->$_(sub { 'dongs' }) };
 like($@, qr/Wrong\s+option\s+set/, "RW::$_ don't want code references");

 eval { $rw->$_(\*STDERR) };
 like($@, qr/Wrong\s+option\s+set/, "RW::$_ don't want globs");

 eval { $rw->$_(qw<a b c>) };
 like($@, qr/Arguments\s+must\s+be\s+passed.*unique\s+scalar.*key\s+=>\s+value\s+pairs/, "RW::$_ gets parameters after the first as key => value pairs");
}

eval { $rw->type('monkey!') };
like($@, qr/Wrong\s+type/, 'RW::type wants a type it knows');

eval { $rw->convert(undef, 'again monkey!') };
like($@, qr/Wrong\s+type/, 'RW::convert wants a type it knows');

for (qw<convert>) {
 ok(!defined $rw->$_(undef), "RW::$_ returns undef when passed undef");
}
