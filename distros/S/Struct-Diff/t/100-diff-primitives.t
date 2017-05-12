#!perl -T

use strict;
use warnings;
use Storable qw(freeze);
use Struct::Diff qw(diff);
use Test::More tests => 29;

use lib "t";
use _common qw(scmp);

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

$got = diff(10, 20);
$exp = {N => 20,O => 10};
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
ok(
    keys %{$got} == 1
        and exists $got->{'U'}
            and $got->{'U'} == \$a
);

$got = diff($a, \$a);
ok(
    keys %{$got} == 2
        and exists $got->{'O'}
            and $got->{'O'} == $a
        and exists $got->{'N'}
            and $got->{'N'} == \$a
);

$got = diff($a, \$a, 'noO' => 1, 'noN' => 1);
is_deeply($got, {});

my $tmp = \\$a;
$got = diff(\$a, $tmp);
ok(
    keys %{$got} == 2
        and exists $got->{'O'}
            and $got->{'O'} == \$a
        and exists $got->{'N'}
            and $got->{'N'} == $tmp
);

$got = diff(\$a, \$b);
ok(
    keys %{$got} == 2
        and exists $got->{'O'}
            and $got->{'O'} == \$a
        and exists $got->{'N'}
            and $got->{'N'} == \$b
);

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
ok(
    keys %{$got} == 1
        and exists $got->{'U'}
        and $got->{'U'} eq $coderef1
);

my $coderef2 = sub { return 1 };
$got = diff($coderef1, $coderef2);
ok(
    keys %{$got} == 2
        and exists $got->{'O'}
            and ref $got->{'O'} eq 'CODE' and $got->{'O'} eq $coderef1
        and exists $got->{'N'}
            and ref $got->{'N'} eq 'CODE' and $got->{'N'} eq $coderef2
        and $got->{'O'} ne $got->{'N'}
);

### blessed
my $blessed1 = bless {}, 'SomeClassName';
$got = diff($blessed1, $blessed1);
ok(
    keys %{$got} == 1
        and exists $got->{'U'}
            and ref $got->{'U'} eq 'SomeClassName' and $got->{'U'} eq $blessed1
);

my $blessed2 = bless {}, 'SomeClassName';
$got = diff($blessed1, $blessed2);
ok(
    keys %{$got} == 2
        and exists $got->{'O'}
            and ref $got->{'O'} eq 'SomeClassName'
                and $got->{'O'} eq $blessed1
        and exists $got->{'N'}
            and ref $got->{'N'} eq 'SomeClassName'
                and $got->{'N'} eq $blessed2
        and $got->{'O'} ne $got->{'N'}
);
