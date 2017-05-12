#!perl -T

use Test::More;

BEGIN {
    eval "require File::Spec::Win32;" or plan skip_all => "Can't load File::Spec::Win32";
    use File::Spec;
    @File::Spec::ISA = qw/File::Spec::Win32/;
}

plan qw/no_plan/;
use Test::Lazy qw/try check template/;

use Path::Class;
use Path::Resource;
use vars qw($rsc);
$rsc = new Path::Resource dir => "apple", uri => "http://banana", loc => "cherry";

ok($rsc);
is($rsc->path, "");
is($rsc->dir, dir "apple");
is($rsc->loc, "/cherry");
#check($rsc->uri => is => "http://banana/cherry");
try("\$::rsc->uri" => is => "http://banana/cherry");

$rsc = $rsc->child("grape");
ok($rsc);
is($rsc->path, "grape");
is($rsc->dir, dir "apple/grape");
is($rsc->loc, "/cherry/grape");
is($rsc->uri, "http://banana/cherry/grape");

$rsc = $rsc->child("kiwi");
ok($rsc);
is($rsc->path, "grape/kiwi");
is($rsc->dir, dir "apple/grape/kiwi");
is($rsc->loc, "/cherry/grape/kiwi");
is($rsc->uri, "http://banana/cherry/grape/kiwi");

my $base = qq|Path::Resource->new(dir => "apple", uri => "http://banana", loc => "cherry")|;
my $template = template(\<<_END_);
${base}
${base}->child("grape")
${base}->child("grape")->child("kiwi")
${base}->child("grape")->child("kiwi")->parent
_END_

$template->test("%?->path", [
	[ is => "" ],
	[ is => "grape" ],
	[ is => "grape/kiwi" ],
	[ is => "grape" ],
]);

$template->test("%?->dir", [
	[ is => dir "apple" ],
	[ is => dir "apple/grape" ],
	[ is => dir "apple/grape/kiwi" ],
	[ is => dir "apple/grape" ],
]);

$template->test("%?->loc", [
	[ is => "/cherry" ],
	[ is => "/cherry/grape" ],
	[ is => "/cherry/grape/kiwi" ],
	[ is => "/cherry/grape" ],
]);

$template->test("%?->uri", [
	[ is => "http://banana/cherry" ],
	[ is => "http://banana/cherry/grape" ],
	[ is => "http://banana/cherry/grape/kiwi" ],
	[ is => "http://banana/cherry/grape" ],
]);

__END__

my $template;

my $stmt = qq|Path::Resource->new(dir => "apple", uri => "http://banana", loc => "cherry")|;
$template = template([ ([$stmt]) x 4 ]);
$template->test([
	[ "%?->path" => is => "" ],
	[ "%?->dir" => is => "apple" ],
	[ "%?->loc" => is => "cherry" ],
	[ "%?->uri" => is => "http://banana/cherry" ],
]);

$stmt .= qq|->child("grape")|;
$template = template([ ([$stmt]) x 4 ]);
$template->test([
	[ "%?->path" => is => "grape" ],
	[ "%?->dir" => is => "apple/grape" ],
	[ "%?->loc" => is => "cherry/grape" ],
	[ "%?->uri" => is => "http://banana/cherry/grape" ],
]);

__END__

my $base = qq|Path::Resource->new(dir => "apple", uri => "http://banana", loc => "cherry")|;
$template->test(
	qq|${base}->child("grape")|, [
	[ '%?->path' => is => "grape" ],
	[ '%?->dir' => is => "apple/grape" ],
	[ '%?->loc' => isnt => "cherry/grape" ],
	[ '%?->uri' => is => "http://banana/cherry/grape" ],
]);



=pod
my $rsc = new Path::Resource dir => "dir", uri => [ "http://hostname", "loc" ];
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->subdir("one");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one");
is($rsc->loc, "loc/one");
is($rsc->uri, "http://hostname/loc/one");

$rsc = $rsc->subdir("two");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two");
is($rsc->loc, "loc/one/two");
is($rsc->uri, "http://hostname/loc/one/two");

$rsc = $rsc->subfile("three.txt");
ok(!$rsc->is_dir);
ok($rsc->is_file);
is($rsc->path, "/one/two/three.txt");
is($rsc->file, "dir/one/two/three.txt");
eval { $rsc->dir }; ok($@);
is($rsc->loc, "loc/one/two/three.txt");
is($rsc->uri, "http://hostname/loc/one/two/three.txt");

eval { $rsc->subdir("impossible-file-subdir") }; ok($@);

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two");
is($rsc->loc, "loc/one/two");
is($rsc->uri, "http://hostname/loc/one/two");

$rsc = $rsc->subdir("four");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two/four");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two/four");
is($rsc->loc, "loc/one/two/four");
is($rsc->uri, "http://hostname/loc/one/two/four");

$rsc = $rsc->parent;
$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one");
is($rsc->loc, "loc/one");
is($rsc->uri, "http://hostname/loc/one");

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->subfile("five.jpg");
ok(!$rsc->is_dir);
ok($rsc->is_file);
is($rsc->file, "dir/five.jpg");
eval { $rsc->dir }; ok($@);
is($rsc->loc, "loc/five.jpg");
is($rsc->uri, "http://hostname/loc/five.jpg");
=cut
