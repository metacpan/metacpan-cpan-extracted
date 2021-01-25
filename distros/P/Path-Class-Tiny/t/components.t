use Test::Most 0.25;

use Path::Class::Tiny;


my $d =  dir("/foo/bar");
my $f = file("baz/qux");

eq_or_diff [$f->components], [qw< baz qux >], "PC style: basic components call (relative)";
is scalar $f->components, 2, "PC style: components in scalar context is correct (relative)";
# for absolute, don't forget the root dir, which counts as one
eq_or_diff [$d->components], ['', qw< foo bar >], "PC style: basic components call (absolute)";
is scalar $d->components, 3, "PC style: components in scalar context is correct (absolute)";
# now put 'em together
eq_or_diff [$d->file($f)->components], ['', qw< foo bar baz qux >], "PC style: basic components call (combined)";
is scalar $d->file($f)->components, 5, "PC style: components in scalar context is correct (combined)";


# Path::Tiny style should work exactly the same way
my $p1 = path("/foo/bar");
my $p2 = path("baz/qux");

eq_or_diff [$p2->components], [qw< baz qux >], "PT style: basic components call (relative)";
is scalar $p2->components, 2, "PT style: components in scalar context is correct (relative)";
# for absolute, don't forget the root dir, which counts as one
eq_or_diff [$p1->components], ['', qw< foo bar >], "PT style: basic components call (absolute)";
is scalar $p1->components, 3, "PT style: components in scalar context is correct (absolute)";
# now put 'em together
eq_or_diff [$p1->child($p2)->components], ['', qw< foo bar baz qux >], "PT style: basic components call (combined)";
is scalar $p1->child($p2)->components, 5, "PT style: components in scalar context is correct (combined)";


# make sure dirname is just an alias to parent
is path("/root/bin")->dirname, "/root", 'dirname is not stupid Path::Tiny::dirname';


done_testing;
