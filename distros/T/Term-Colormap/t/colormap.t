#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Capture::Tiny ':all';

BEGIN {
    use_ok(
        'Term::Colormap', qw(
          colorbar
          colormap
          color2rgb
          rgb2color
          print_colored
          print_colored_text
          color_table
          )
    ) || print "Bail out on imports!\n";
}

my @valid_colormaps = qw(
    ash
    bright
    gray
    primary
    rainbow
    snow
    blue-cyan-green
    red-pink-yellow
    green-orange-pink-blue
);

for my $name ( @valid_colormaps ) {
    my $mapping = colormap($name);
    ok ( scalar @$mapping, "Colormap $name" );
}

dies_ok { colormap('foo') } 'Colormap catches invalid names';

my $colors_seen = {};
for my $color ( 0 .. 255 ) {
    my $rgb = color2rgb($color);
    ok( 6 == length($rgb), 'color2rgb( ' . $color . ' ) = ' . $rgb);
    push @{ $colors_seen->{ $rgb } }, $color;
}

for my $rgb ( keys %$colors_seen ) {
    my $color_new = rgb2color( $rgb );
    ok( ( grep { $color_new == $_ } @{ $colors_seen->{$rgb} } ),
        'rgb2color( ' . $rgb . ' ) = ' . $color_new);
}

for my $color ( qw( -2 -1 256 257 foo ) ) {
    dies_ok { color2rgb($color) } 'color2rgb catches invalid colors';
}

# Colorbar Tests
my $rainbow = colormap( 'rainbow' );
ok( scalar @$rainbow, 'Colormap rainbow');
my $colorbar_output = capture_merged {
    colorbar($rainbow);
};

my $output_normalized = normalize_colored_text( $colorbar_output );
# ASCII Escape Sequences
my $expected = '|[|4|8|;|5|;|1|m| | ||[|0|m||[|4|8|;|5|;|1|9|6|m| | ||[|0|m||[|4|8|;|5|;|2|0|2|m| | ||[|0|m||[|4|8|;|5|;|2|0|8|m| | ||[|0|m||[|4|8|;|5|;|2|1|4|m| | ||[|0|m||[|4|8|;|5|;|2|2|0|m| | ||[|0|m||[|4|8|;|5|;|2|2|6|m| | ||[|0|m||[|4|8|;|5|;|1|1|m| | ||[|0|m||[|4|8|;|5|;|1|9|0|m| | ||[|0|m||[|4|8|;|5|;|1|5|4|m| | ||[|0|m||[|4|8|;|5|;|1|1|8|m| | ||[|0|m||[|4|8|;|5|;|8|2|m| | ||[|0|m||[|4|8|;|5|;|4|6|m| | ||[|0|m||[|4|8|;|5|;|1|0|m| | ||[|0|m||[|4|8|;|5|;|4|7|m| | ||[|0|m||[|4|8|;|5|;|4|8|m| | ||[|0|m||[|4|8|;|5|;|4|9|m| | ||[|0|m||[|4|8|;|5|;|5|0|m| | ||[|0|m||[|4|8|;|5|;|5|1|m| | ||[|0|m||[|4|8|;|5|;|1|4|m| | ||[|0|m||[|4|8|;|5|;|4|5|m| | ||[|0|m||[|4|8|;|5|;|3|9|m| | ||[|0|m||[|4|8|;|5|;|3|3|m| | ||[|0|m||[|4|8|;|5|;|2|7|m| | ||[|0|m||[|4|8|;|5|;|2|1|m| | ||[|0|m||[|4|8|;|5|;|1|2|m| | ||[|0|m||[|4|8|;|5|;|5|7|m| | ||[|0|m||[|4|8|;|5|;|9|3|m| | ||[|0|m||[|4|8|;|5|;|1|2|9|m| | ||[|0|m||[|4|8|;|5|;|1|6|5|m| | ||[|0|m||[|4|8|;|5|;|2|0|1|m| | ||[|0|m||[|4|8|;|5|;|5|m| | ||[|0|m';
ok($output_normalized eq $expected, "Rainbow is $colorbar_output")
    or diag( "Got \n$output_normalized\n, but expected \n$expected\n");

my $colorbar_output2 = capture_merged {
    colorbar($rainbow,3,'v');
};
my $output_normalized2 = normalize_colored_text( $colorbar_output2 );
my $expected2 = '|[|4|8|;|5|;|1|m| | | ||[|0|m|
||[|4|8|;|5|;|1|9|6|m| | | ||[|0|m|
||[|4|8|;|5|;|2|0|2|m| | | ||[|0|m|
||[|4|8|;|5|;|2|0|8|m| | | ||[|0|m|
||[|4|8|;|5|;|2|1|4|m| | | ||[|0|m|
||[|4|8|;|5|;|2|2|0|m| | | ||[|0|m|
||[|4|8|;|5|;|2|2|6|m| | | ||[|0|m|
||[|4|8|;|5|;|1|1|m| | | ||[|0|m|
||[|4|8|;|5|;|1|9|0|m| | | ||[|0|m|
||[|4|8|;|5|;|1|5|4|m| | | ||[|0|m|
||[|4|8|;|5|;|1|1|8|m| | | ||[|0|m|
||[|4|8|;|5|;|8|2|m| | | ||[|0|m|
||[|4|8|;|5|;|4|6|m| | | ||[|0|m|
||[|4|8|;|5|;|1|0|m| | | ||[|0|m|
||[|4|8|;|5|;|4|7|m| | | ||[|0|m|
||[|4|8|;|5|;|4|8|m| | | ||[|0|m|
||[|4|8|;|5|;|4|9|m| | | ||[|0|m|
||[|4|8|;|5|;|5|0|m| | | ||[|0|m|
||[|4|8|;|5|;|5|1|m| | | ||[|0|m|
||[|4|8|;|5|;|1|4|m| | | ||[|0|m|
||[|4|8|;|5|;|4|5|m| | | ||[|0|m|
||[|4|8|;|5|;|3|9|m| | | ||[|0|m|
||[|4|8|;|5|;|3|3|m| | | ||[|0|m|
||[|4|8|;|5|;|2|7|m| | | ||[|0|m|
||[|4|8|;|5|;|2|1|m| | | ||[|0|m|
||[|4|8|;|5|;|1|2|m| | | ||[|0|m|
||[|4|8|;|5|;|5|7|m| | | ||[|0|m|
||[|4|8|;|5|;|9|3|m| | | ||[|0|m|
||[|4|8|;|5|;|1|2|9|m| | | ||[|0|m|
||[|4|8|;|5|;|1|6|5|m| | | ||[|0|m|
||[|4|8|;|5|;|2|0|1|m| | | ||[|0|m|
||[|4|8|;|5|;|5|m| | | ||[|0|m|
';

ok($output_normalized2 eq $expected2, "Rainbow (vertical) is \n$colorbar_output2")
    or diag( "Got \n$output_normalized2\n, but expected \n$expected2\n");

# Color Table Tests
my $color_table_output = capture_merged {
    color_table('rainbow');
};

my $color_table_normalized = normalize_colored_text( $color_table_output );

my $expected_color_table = '-|-|-|-|-|-|-| |r|a|i|n|b|o|w| |-|-|-|-|-|-|-|
|c|o|l|o|r| | | | | |n|u|m|b|e|r| | | |r|g|b|
||[|4|8|;|5|;|1|m| | | | | | | | ||[|0|m| | | | | |1| | | |8|0|0|0|0|0|
||[|4|8|;|5|;|1|9|6|m| | | | | | | | ||[|0|m| | | |1|9|6| | | |f|f|0|0|0|0|
||[|4|8|;|5|;|2|0|2|m| | | | | | | | ||[|0|m| | | |2|0|2| | | |f|f|5|f|0|0|
||[|4|8|;|5|;|2|0|8|m| | | | | | | | ||[|0|m| | | |2|0|8| | | |f|f|8|7|0|0|
||[|4|8|;|5|;|2|1|4|m| | | | | | | | ||[|0|m| | | |2|1|4| | | |f|f|a|f|0|0|
||[|4|8|;|5|;|2|2|0|m| | | | | | | | ||[|0|m| | | |2|2|0| | | |f|f|d|7|0|0|
||[|4|8|;|5|;|2|2|6|m| | | | | | | | ||[|0|m| | | |2|2|6| | | |f|f|f|f|0|0|
||[|4|8|;|5|;|1|1|m| | | | | | | | ||[|0|m| | | | |1|1| | | |f|f|f|f|0|0|
||[|4|8|;|5|;|1|9|0|m| | | | | | | | ||[|0|m| | | |1|9|0| | | |d|7|f|f|0|0|
||[|4|8|;|5|;|1|5|4|m| | | | | | | | ||[|0|m| | | |1|5|4| | | |a|f|f|f|0|0|
||[|4|8|;|5|;|1|1|8|m| | | | | | | | ||[|0|m| | | |1|1|8| | | |8|7|f|f|0|0|
||[|4|8|;|5|;|8|2|m| | | | | | | | ||[|0|m| | | | |8|2| | | |5|f|f|f|0|0|
||[|4|8|;|5|;|4|6|m| | | | | | | | ||[|0|m| | | | |4|6| | | |0|0|f|f|0|0|
||[|4|8|;|5|;|1|0|m| | | | | | | | ||[|0|m| | | | |1|0| | | |0|0|f|f|0|0|
||[|4|8|;|5|;|4|7|m| | | | | | | | ||[|0|m| | | | |4|7| | | |0|0|f|f|5|f|
||[|4|8|;|5|;|4|8|m| | | | | | | | ||[|0|m| | | | |4|8| | | |0|0|f|f|8|7|
||[|4|8|;|5|;|4|9|m| | | | | | | | ||[|0|m| | | | |4|9| | | |0|0|f|f|a|f|
||[|4|8|;|5|;|5|0|m| | | | | | | | ||[|0|m| | | | |5|0| | | |0|0|f|f|d|7|
||[|4|8|;|5|;|5|1|m| | | | | | | | ||[|0|m| | | | |5|1| | | |0|0|f|f|f|f|
||[|4|8|;|5|;|1|4|m| | | | | | | | ||[|0|m| | | | |1|4| | | |0|0|f|f|f|f|
||[|4|8|;|5|;|4|5|m| | | | | | | | ||[|0|m| | | | |4|5| | | |0|0|d|7|f|f|
||[|4|8|;|5|;|3|9|m| | | | | | | | ||[|0|m| | | | |3|9| | | |0|0|a|f|f|f|
||[|4|8|;|5|;|3|3|m| | | | | | | | ||[|0|m| | | | |3|3| | | |0|0|8|7|f|f|
||[|4|8|;|5|;|2|7|m| | | | | | | | ||[|0|m| | | | |2|7| | | |0|0|5|f|f|f|
||[|4|8|;|5|;|2|1|m| | | | | | | | ||[|0|m| | | | |2|1| | | |0|0|0|0|f|f|
||[|4|8|;|5|;|1|2|m| | | | | | | | ||[|0|m| | | | |1|2| | | |0|0|0|0|f|f|
||[|4|8|;|5|;|5|7|m| | | | | | | | ||[|0|m| | | | |5|7| | | |5|f|0|0|f|f|
||[|4|8|;|5|;|9|3|m| | | | | | | | ||[|0|m| | | | |9|3| | | |8|7|0|0|f|f|
||[|4|8|;|5|;|1|2|9|m| | | | | | | | ||[|0|m| | | |1|2|9| | | |a|f|0|0|f|f|
||[|4|8|;|5|;|1|6|5|m| | | | | | | | ||[|0|m| | | |1|6|5| | | |d|7|0|0|f|f|
||[|4|8|;|5|;|2|0|1|m| | | | | | | | ||[|0|m| | | |2|0|1| | | |f|f|0|0|f|f|
||[|4|8|;|5|;|5|m| | | | | | | | ||[|0|m| | | | | |5| | | |8|0|0|0|8|0|
';
ok($color_table_normalized eq $expected_color_table, "Rainbow table is \n$color_table_output")
    or diag( "Got \n$output_normalized\n, but expected \n$expected_color_table\n");

my $color_table_output2 = capture_merged {
    color_table('green-orange-pink-blue');
};

my $color_table_normalized2 = normalize_colored_text( $color_table_output2 );
my $expected_color_table2 = ' |g|r|e|e|n|-|o|r|a|n|g|e|-|p|i|n|k|-|b|l|u|e| |
|c|o|l|o|r| | | | | |n|u|m|b|e|r| | | |r|g|b|
||[|4|8|;|5|;|2|8|m| | | | | | | | ||[|0|m| | | | |2|8| | | |0|0|8|7|0|0|
||[|4|8|;|5|;|6|4|m| | | | | | | | ||[|0|m| | | | |6|4| | | |5|f|8|7|0|0|
||[|4|8|;|5|;|1|0|0|m| | | | | | | | ||[|0|m| | | |1|0|0| | | |8|7|8|7|0|0|
||[|4|8|;|5|;|1|3|6|m| | | | | | | | ||[|0|m| | | |1|3|6| | | |a|f|8|7|0|0|
||[|4|8|;|5|;|1|7|2|m| | | | | | | | ||[|0|m| | | |1|7|2| | | |d|7|8|7|0|0|
||[|4|8|;|5|;|2|0|8|m| | | | | | | | ||[|0|m| | | |2|0|8| | | |f|f|8|7|0|0|
||[|4|8|;|5|;|2|0|9|m| | | | | | | | ||[|0|m| | | |2|0|9| | | |f|f|8|7|5|f|
||[|4|8|;|5|;|2|1|0|m| | | | | | | | ||[|0|m| | | |2|1|0| | | |f|f|8|7|8|7|
||[|4|8|;|5|;|2|1|1|m| | | | | | | | ||[|0|m| | | |2|1|1| | | |f|f|8|7|a|f|
||[|4|8|;|5|;|2|1|2|m| | | | | | | | ||[|0|m| | | |2|1|2| | | |f|f|8|7|d|7|
||[|4|8|;|5|;|2|1|3|m| | | | | | | | ||[|0|m| | | |2|1|3| | | |f|f|8|7|f|f|
||[|4|8|;|5|;|1|7|7|m| | | | | | | | ||[|0|m| | | |1|7|7| | | |d|7|8|7|f|f|
||[|4|8|;|5|;|1|4|1|m| | | | | | | | ||[|0|m| | | |1|4|1| | | |a|f|8|7|f|f|
||[|4|8|;|5|;|1|0|5|m| | | | | | | | ||[|0|m| | | |1|0|5| | | |8|7|8|7|f|f|
||[|4|8|;|5|;|6|9|m| | | | | | | | ||[|0|m| | | | |6|9| | | |5|f|8|7|f|f|
||[|4|8|;|5|;|3|3|m| | | | | | | | ||[|0|m| | | | |3|3| | | |0|0|8|7|f|f|
';
ok($color_table_normalized2 eq $expected_color_table2,
   "Green-Orange-Pink-Blue table is \n$color_table_output2")
    or diag( "Got \n$color_table_normalized2\n, but expected \n$expected_color_table2\n");

my $color_table_output3 = capture_merged {
    color_table('snow');
};

my $color_table_normalized3 = normalize_colored_text( $color_table_output3 );
my $expected_color_table3 = '-|-|-|-|-|-|-|-| |s|n|o|w| |-|-|-|-|-|-|-|-|-|
|c|o|l|o|r| | | | | |n|u|m|b|e|r| | | |r|g|b|
||[|4|8|;|5|;|2|4|4|m| | | | | | | | ||[|0|m| | | |2|4|4| | | |8|0|8|0|8|0|
||[|4|8|;|5|;|2|4|5|m| | | | | | | | ||[|0|m| | | |2|4|5| | | |8|a|8|a|8|a|
||[|4|8|;|5|;|2|4|6|m| | | | | | | | ||[|0|m| | | |2|4|6| | | |9|4|9|4|9|4|
||[|4|8|;|5|;|2|4|7|m| | | | | | | | ||[|0|m| | | |2|4|7| | | |9|e|9|e|9|e|
||[|4|8|;|5|;|2|4|8|m| | | | | | | | ||[|0|m| | | |2|4|8| | | |a|8|a|8|a|8|
||[|4|8|;|5|;|2|4|9|m| | | | | | | | ||[|0|m| | | |2|4|9| | | |b|2|b|2|b|2|
||[|4|8|;|5|;|2|5|0|m| | | | | | | | ||[|0|m| | | |2|5|0| | | |b|c|b|c|b|c|
||[|4|8|;|5|;|2|5|1|m| | | | | | | | ||[|0|m| | | |2|5|1| | | |c|6|c|6|c|6|
||[|4|8|;|5|;|2|5|2|m| | | | | | | | ||[|0|m| | | |2|5|2| | | |d|0|d|0|d|0|
||[|4|8|;|5|;|2|5|3|m| | | | | | | | ||[|0|m| | | |2|5|3| | | |d|a|d|a|d|a|
||[|4|8|;|5|;|2|5|4|m| | | | | | | | ||[|0|m| | | |2|5|4| | | |e|4|e|4|e|4|
||[|4|8|;|5|;|2|5|5|m| | | | | | | | ||[|0|m| | | |2|5|5| | | |e|e|e|e|e|e|
';
ok($color_table_normalized3 eq $expected_color_table3,
   "Snow table is \n$color_table_output3")
    or diag( "Got \n$color_table_normalized3\n, but expected \n$expected_color_table3\n");

# rgb2color tests
dies_ok { rgb2color( 'garbage' ) } 'rgb2color dies when fed garbage';

my @bad;
for my $n (1 .. 1000) {
    my $hex = sprintf("%06x", int rand 256*256*25);
    my $color = rgb2color($hex);
    push @bad, $n
        unless ( 0 <= $color && $color <= 255 );
};
ok(scalar @bad == 0, 'rgb2color handles 1000 random color combinations');

# print_colored_test tests
my $colored_test_output = capture_merged {
    print_colored_text( 208, "Peach Colored Text" );
};
my $normalized_peach_text = normalize_colored_text( $colored_test_output );
my $expected_peach_text = '|[|3|8|;|5|;|2|0|8|m|P|e|a|c|h| |C|o|l|o|r|e|d| |T|e|x|t||[|0|m';
ok( $normalized_peach_text eq $expected_peach_text,
    "print_colored_text( 208, 'Peach Colored Text' ) => $colored_test_output");

# print_colored tests
my $colored_output = capture_merged {
    print_colored( 93, "Text on Lavender" );
};
my $normalized_lavender = normalize_colored_text( $colored_output );
my $expected_lavender = '|[|4|8|;|5|;|9|3|m|T|e|x|t| |o|n| |L|a|v|e|n|d|e|r||[|0|m';
ok( $normalized_lavender eq $expected_lavender,
    "print_colored( 93, 'Text on Lavender' ) => $colored_output");

done_testing();
exit 0;

sub normalize_colored_text {
    my ($txt) = @_;
    chomp($txt);
    return join('|',split //, $txt);
}
