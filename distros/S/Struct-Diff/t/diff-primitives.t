#!perl -T

use strict;
use warnings;
use Storable qw(freeze);
use Struct::Diff qw(diff);
use Test::More tests => 40;

use lib "t";
use _common qw(scmp);

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

my ($got, $exp);

### undefs
$got = diff(undef, undef);
$exp = {U => undef};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(undef, 0);
$exp = {N => 0,O => undef};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(undef, '');
$exp = {N => '',O => undef};
is_deeply($got, $exp) || diag scmp($got, $exp);

### numbers
$got = diff(0, 0);
$exp = {U => 0};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(0, undef);
$exp = {N => undef,O => 0};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(0, '');
$exp = {N => '',O => 0};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(1, 1.0);
$exp = {U => 1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(1.0, 1);
$exp = {U => '1'};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(1, 2);
$exp = {N => 2,O => 1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('2.0', 2);
$exp = {N => 2,O => '2.0'};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('2', 2);
$exp = {N => 2,O => '2'};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('10', 20);
$exp = {N => 20,O => '10'};
ok(freeze($got) eq freeze($exp)); # almost the same as above, cehck result doesn't mangled

### strings
$got = diff('', undef);
$exp = {N => undef,O => ''};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('', 0);
$exp = {N => 0,O => ''};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('a', "a");
$exp = {U => 'a'};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff('a', 'b');
$exp = {N => 'b',O => 'a'};
is_deeply($got, $exp) || diag scmp($got, $exp);

### refs
my ($a, $b) = (0, 0);
$got = diff(\$a, \$a);
$exp = {U => \$a};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff($a, \$a);
$exp = {N => \$a,O => $a};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff($a, \$a, 'noO' => 1, 'noN' => 1);
is_deeply($got, {});

$got = diff(\$a, \\$a);
$exp = {O => \$a,N => \\$a};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff(\$a, \$b);
$exp = {U => \0};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff({x => \{y => \$a}}, {x => \{y => \$b}});
$exp = {U => {x => \{y => \0}}};
is_deeply($got, $exp) || diag scmp($got, $exp);

### arrays/hashes
$got = diff({}, {});
$exp = {U => {}};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff([], []);
$exp = {U => []};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff([], {});
$exp = {N => {},O => []};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff({}, []);
$exp = {N => [],O => {}};
is_deeply($got, $exp) || diag scmp($got, $exp);

### code
my $coderef1 = sub { return 0 };
$got = diff($coderef1, $coderef1);
$exp = {U => $coderef1};
is_deeply($got, $exp) || diag scmp($got, $exp);

my $coderef2 = sub { return 1 };
$got = diff($coderef1, $coderef2);
$exp = $exp = {N => $coderef2,O => $coderef1};;
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff($coderef1, sub { return 0 });
$exp = {U => $coderef1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$got = diff($coderef1, sub { return 00 });
$exp = {U => $coderef1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$coderef2 = sub { 0 };
$got = diff($coderef1, $coderef2);
$exp = {N => $coderef2,O => $coderef1};
is_deeply($got, $exp) || diag scmp($got, $exp);

### blessed
my $blessed1 = bless {}, 'SomeClassName';
$got = diff($blessed1, $blessed1);
$exp = {U => $blessed1};
is_deeply($got, $exp) || diag scmp($got, $exp);

my $blessed2 = bless {}, 'SomeClassName';
$got = diff($blessed1, $blessed2);
$exp = {U => $blessed1};
is_deeply($got, $exp, "Equal by data objects") || diag scmp($got, $exp);

$blessed2 = bless [], 'SomeClassName';
$got = diff($blessed1, $blessed2);
$exp = {N => $blessed2,O => $blessed1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$blessed2 = bless {}, 'OtherClassName';
$got = diff($blessed1, $blessed2);
$exp = {N => $blessed2,O => $blessed1};
is_deeply($got, $exp) || diag scmp($got, $exp);

$blessed1 = bless { a => 0 }, 'SomeClassName';
$blessed2 = bless { a => 1 }, 'SomeClassName';
$got = diff($blessed1, $blessed2);
$exp = {N => $blessed2,O => $blessed1};
is_deeply($got, $exp, "No deep diff for objects") || diag scmp($got, $exp);

### Regexp
my $re1 = qr/pat/msix;
$got = diff($re1, $re1);
$exp = {U => $re1};
is_deeply($got, $exp, "Same regexp") || diag scmp($got, $exp);

$got = diff($re1, qr/pat/ixms);
$exp = {U => $re1};
is_deeply($got, $exp, "Equal by data regexps") || diag scmp($got, $exp);

my $re2 = qr/pat/m;
$got = diff($re1, $re2);
$exp = {N => $re2,O => $re1};
is_deeply($got, $exp, "Different by mods regexps") || diag scmp($got, $exp);

$re2 = qr/FOO/msix;
$got = diff($re1, $re2);
$exp = {N => $re2,O => $re1};
is_deeply($got, $exp, "Different by pattern regexps") || diag scmp($got, $exp);

