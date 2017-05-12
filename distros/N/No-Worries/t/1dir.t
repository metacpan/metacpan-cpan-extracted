#!perl

use strict;
use warnings;
use Test::More tests => 33;
use File::Temp qw(tempdir);

use No::Worries::Dir qw(*);

our($tmpdir, @list, %hash);

$tmpdir = tempdir(CLEANUP => 1);
chdir($tmpdir) or die("*** cannot chdir($tmpdir): $!\n");
END {
    chdir("/") or die("*** cannot chdir(/): $!\n");
}

eval { @list = dir_read(".") };
is($@, "", "read empty directory");
is("@list", "", "read empty directory = ()");

eval { dir_ensure("foo/bar") };
is($@, "", "ensure directory");
ok(-d "foo", "ensure directory -d foo");
ok(-d "foo/bar", "ensure directory -d foo/bar");

eval { dir_ensure("foo") };
is($@, "", "ensure directory foo");
eval { dir_ensure("foo/bar") };
is($@, "", "ensure directory foo/bar");

eval { @list = dir_read("foo") };
is($@, "", "read directory");
is("@list", "bar", "read directory = (bar)");

eval { dir_change("foo") };
is($@, "", "change directory");
ok(-d "bar", "change directory -d bar");

eval { dir_remove("bar") };
is($@, "", "remove directory");
ok(!-d "bar", "remove directory !-d bar");

eval { dir_change("..") };
is($@, "", "change directory ..");
ok(-d "foo", "change directory .. -d foo");

eval { dir_remove("foo") };
is($@, "", "remove directory foo");
eval { dir_make("foo") };
is($@, "", "make directory foo");
eval { dir_remove("foo") };
is($@, "", "remove directory foo");
eval { dir_make("foo", mode => 0777) };
is($@, "", "make directory foo with mode");
eval { dir_make("foo") };
ok($@, "make existing directory fails");

%hash = (
    ""           => ".", # border case
    "/"          => "/",
    "///"        => "/",
    "foo"        => ".",
    "foo///"     => ".",
    "/foo"       => "/",
    "/foo/"      => "/",
    "/foo/bar"   => "/foo",
    "/foo///bar" => "/foo",
    "/foo/bar/"  => "/foo",
    "foo/bar"    => "foo",
    "foo///bar"  => "foo",
    "foo/bar/"   => "foo",
);
foreach my $path (sort(keys(%hash))) {
    is(dir_parent($path), $hash{$path}, "parent of '$path' is '$hash{$path}'");
}
