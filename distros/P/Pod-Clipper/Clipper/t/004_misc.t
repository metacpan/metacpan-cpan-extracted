# -*- perl -*-

use Test::More tests => 5;

BEGIN { use Pod::Clipper; }

my $data = "";
while (<DATA>) {
    $data .= $_;
}

my $block;
my $clipper = Pod::Clipper->new({ data => $data });
my $all_blocks = $clipper->all;

is($#{$all_blocks}, 2, "Got the correct number of blocks");

$clipper->data("   something new   ");

is($#{$all_blocks}, 2, "Got the same number of blocks without calling rebuild()");

$clipper->rebuild;
$all_blocks = $clipper->all;
is($#{$all_blocks}, 0, "rebuild() works");

$block = 'something new';

is($block, $all_blocks->[0]->data, "Block 0: Got the expected data");

$clipper->ignore_whitespace(0);
$clipper->rebuild();
$all_blocks = $clipper->all;

$block = '   something new   ';

is($block, $all_blocks->[0]->data, "Block 0: Got the expected data with ignore_whitespace = false");


__DATA__
# there better be three blocks in this data: this one,
# the pod block below, and the stuff after =cut.
=pod

test
one
two
three

=cut

my $foo = "bar";
