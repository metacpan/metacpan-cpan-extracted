#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 10;

use POSIX::1003::Confstr qw(confstr %confstr _CS_PATH);

my $path = confstr('_CS_PATH');
ok(defined $path, "_CS_PATH via function = $path");

my $path2 = _CS_PATH;
ok(defined $path2, "_CS_PATH directly = $path2");
cmp_ok($path, 'eq', $path2);

my $key = $confstr{_CS_PATH};
ok(defined $key, "key = $key");

my $path3;
eval { $path3 = confstr($key) };
like($@, qr/^pass the constant name as string at/);
ok(!defined $path3);

my $path4;
eval { $path4 = confstr(_CS_PATH) };
like($@, qr/^pass the constant name as string at/);
ok(!defined $path4);

use POSIX::1003::Confstr qw(confstr_names);
my @names = confstr_names;
if($^O =~ /^(?:net|open)bsd/)
{   # there is only 1 name defined on some BSDs
    cmp_ok(scalar @names, '>=', 1, @names." names on $^O");
}
else
{   cmp_ok(scalar @names, '>', 10, @names." names");
}

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = confstr($name);
    printf "  %4d %-40s %s\n", $confstr{$name}, $name
       , (defined $val ? $val : 'undef');
    defined $val or $undefd++;
}
ok(1, "$undefd _CS_ constants return undef");
