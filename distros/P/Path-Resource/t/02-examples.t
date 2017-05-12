#!perl -T

use Test::More;

BEGIN {
    if ($ENV{TEST_WIN32}) {
        eval "require File::Spec::Win32;" or plan skip_all => "Can't load File::Spec::Win32";
        use File::Spec;
        @File::Spec::ISA = qw/File::Spec::Win32/;
    }
}

plan qw/no_plan/;
use Test::Lazy qw/try check template/;

use Path::Class;
use Path::Resource;
use Path::Resource::Base;
my ($rsc, $base, $uri, $loc, $dir, $path);

$rsc = new Path::Resource dir => "/var/dir", uri => "http://hostname/loc";
is($rsc->uri->as_string, "http://hostname/loc");
is($rsc->dir->stringify, dir "/var/dir");

my $apple_rsc = $rsc->child("apple");
is($apple_rsc->uri->as_string, "http://hostname/loc/apple");
is($apple_rsc->dir->stringify, dir "/var/dir/apple");

my $banana_txt_rsc = $apple_rsc->child("banana.txt");
is($banana_txt_rsc->uri->as_string, "http://hostname/loc/apple/banana.txt");
is($banana_txt_rsc->file->stringify, file "/var/dir/apple/banana.txt");

$rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", path => "xyzzy");
is($rsc->dir->stringify, dir "/home/b/htdocs/xyzzy");
is($rsc->uri->as_string, "http://example.com/a/xyzzy");

$rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", path => "xyzzy/nothing.txt");
is($rsc->file->stringify, file "/home/b/htdocs/xyzzy/nothing.txt");
is($rsc->uri->as_string, "http://example.com/a/xyzzy/nothing.txt");

$rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", loc => "c");
is($rsc->dir->stringify, dir "/home/b/htdocs");
is($rsc->uri->as_string, "http://example.com/a/c");

$rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", loc => "/g/h");
is($rsc->dir->stringify, dir "/home/b/htdocs");
is($rsc->uri->as_string, "http://example.com/g/h");

$base = Path::Resource::Base->new(uri => "http://example.com/a", dir => "/home/b/htdocs", loc => "/g/h");
is($base->uri->as_string, "http://example.com/a");
is($base->dir->stringify, dir "/home/b/htdocs");
is($base->loc->stringify, "/g/h");

ok($base->uri("http://example.org")->isa("URI"));
is($base->uri, "http://example.org");

ok($base->dir("a/b")->isa("Path::Class::Dir"));
is($base->dir, dir "a/b");

ok($base->loc("g/h/b")->isa("Path::Abstract"));
is($base->loc, "g/h/b");
