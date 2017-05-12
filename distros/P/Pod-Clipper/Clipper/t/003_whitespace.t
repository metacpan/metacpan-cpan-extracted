# -*- perl -*-

use Test::More tests => 13;

BEGIN { use Pod::Clipper; }

my $data = "";
while (<DATA>) {
    $data .= $_;
}

my $block;
my $clipper = Pod::Clipper->new({ data => $data,
                                  ignore_whitespace => 0,
                                  ignore_trailing_whitespace => 1 });
my $all_blocks = $clipper->all;

is($#{$all_blocks}, 5, "Got the correct number of blocks");

$block = q/


# This is the first block. The whitespace above is
# part of it./;

is($block, $all_blocks->[0]->data, "Block 0: Got the expected data");
ok(!$all_blocks->[0]->is_pod, "Block 0: Got the expected block type");

$block = q/=pod

test
one
two
three

=cut/;

is($block, $all_blocks->[1]->data, "Block 1: Got the expected data");
ok($all_blocks->[1]->is_pod, "Block 1: Got the expected block type");

$block = q/=pod

test

=begin foo

test

=end foo

=cut/;

is($block, $all_blocks->[2]->data, "Block 2: Got the expected results");
ok($all_blocks->[2]->is_pod, "Block 2: Got the expected block type");

$block = '';

is($block, $all_blocks->[3]->data, "Block 3: Got the expected data");
ok(!$all_blocks->[3]->is_pod, "Block 3: Got the expected block type");

$block = q/=pod

test

=cut/;

is($block, $all_blocks->[4]->data, "Block 4: Got the expected data");
ok($all_blocks->[4]->is_pod, "Block 4: Got the expected block type");

$block = q/
my $foo = "bar";
# there is some whitespace below but it will be ignored
# because ignore_trailing_whitespace is set/;

is($block, $all_blocks->[5]->data, "Block 5: Got the expected data");
ok(!$all_blocks->[5]->is_pod, "Block 5: Got the expected block type");



__DATA__



# This is the first block. The whitespace above is
# part of it.
=pod

test
one
two
three

=cut
=pod

test

=begin foo

test

=end foo

=cut

=pod

test

=cut

my $foo = "bar";
# there is some whitespace below but it will be ignored
# because ignore_trailing_whitespace is set



