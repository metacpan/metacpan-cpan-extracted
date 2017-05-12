# -*- perl -*-

use Test::More tests => 4;

BEGIN { use Pod::Clipper; }

my $data = "";
while (<DATA>) {
    $data .= $_;
}

my $block;
my $clipper = Pod::Clipper->new({ data => $data, append_newline => 1 });
my $all_blocks = $clipper->all;

is($#{$all_blocks}, 2, "Got the correct number of blocks");

$block = q/# there better be three blocks in this data: this one,
# the pod block below, and the stuff after =cut.
/;

is($block, $all_blocks->[0]->data, "Block 0: Got the expected results");

$block = q/=pod

test
one
two
three

=cut
/;

is($block, $all_blocks->[1]->data, "Block 1: Got the expected results");

$block = q/
my $foo = "bar";
/;

is($block, $all_blocks->[2]->data, "Block 2: Got the expected results");

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
