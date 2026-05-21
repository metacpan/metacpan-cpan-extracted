use strict;
use warnings;
use Test::More;
use lib 't/lib', 'lib';

use_ok('Nobody::Util');

# vcmp / vsort
ok(vcmp('1.2.3', '1.2.4') < 0,  'vcmp: 1.2.3 < 1.2.4');
ok(vcmp('1.10.0', '1.9.0') > 0, 'vcmp: 1.10.0 > 1.9.0');
ok(vcmp('2.0.0', '2.0.0') == 0, 'vcmp: equal versions');

my @sorted = vsort(qw(1.10.0 1.2.0 1.9.0 2.0.0));
is_deeply(\@sorted, [qw(1.2.0 1.9.0 1.10.0 2.0.0)], 'vsort: correct order');

# serdate — returns YYYYMMDD-HHMMSS (15 chars)
my $d = serdate();
like($d, qr/^\d{8}-\d{6}$/, 'serdate: returns YYYYMMDD-HHMMSS string');

# serial_maker — expects { fmt => $sprintf_fmt, ... }
{
  use File::Temp qw(tempdir);
  my $dir = tempdir(CLEANUP => 1);
  my $ser = serial_maker({ fmt => "$dir/test-%04d.txt" });
  my $r1 = $ser->();
  my $r2 = $ser->();
  ok(defined $r1 && defined $r1->{fn}, 'serial_maker: first result has fn');
  ok(defined $r2 && defined $r2->{fn}, 'serial_maker: second result has fn');
  isnt($r1->{fn}, $r2->{fn}, 'serial_maker: successive filenames differ');
}

# flatten
my @flat = flatten([1, [2, 3], [4, [5]]]);
is_deeply(\@flat, [1, 2, 3, 4, 5], 'flatten: nested array');

# lsort — sorts by length then lexicographically
my @ls = lsort(qw(banana fig cherry));
is_deeply(\@ls, [qw(fig banana cherry)], 'lsort: length then lex order');

# pad — pads with dots to the length of the longest
my @padded = pad(qw(hi hello));
is($padded[0], 'hi...', 'pad: shorter string padded with dots');
is($padded[1], 'hello', 'pad: longest string unchanged');

# class
is(class("My::Class"), "My::Class", 'class: plain string');
is(class(bless {}, "My::Object"), "My::Object", 'class: blessed object');

# safe_isa, safe_blessed, safe_can
my $obj = bless {}, 'My::Object';
ok(safe_isa($obj, 'My::Object'),   'safe_isa: returns true for correct class');
ok(!safe_isa($obj, 'Other::Class'),'safe_isa: returns false for incorrect class');
is(safe_blessed($obj), 'My::Object', 'safe_blessed: returns class name');
ok(!safe_blessed('not an object'), 'safe_blessed: returns false for non-object');

# mkref
my $scalar = 42;
my $ref = mkref($scalar);
ok(ref($ref) eq 'SCALAR', 'mkref: creates a scalar reference');
is(mkref($ref), $ref, 'mkref: returns existing reference unchanged');

# list utils
is(sum(1, 2, 3), 6, 'sum: calculates sum');
is(min(3, 1, 2), 1, 'min: finds minimum value');
is(max(3, 1, 2), 3, 'max: finds maximum value');
is_deeply([uniq(1, 2, 1, 3, 2)], [1, 2, 3], 'uniq: finds unique elements');

done_testing();
