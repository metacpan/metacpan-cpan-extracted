#!perl

use Test::More;

use_ok('Net::COLOURlovers');

my $cl = Net::COLOURlovers->new;
isa_ok( $cl, 'Net::COLOURlovers' );

for (qw( color colors colors_new colors_top color_random )) {
    can_ok( $cl, $_ );
}

for (qw( lover lovers lovers_new lovers_top )) {
    can_ok( $cl, $_ );
}

for (qw( palette palettes palettes_new palettes_top palette_random )) {
    can_ok( $cl, $_ );
}

for (qw( pattern patterns patterns_new patterns_top pattern_random )) {
    can_ok( $cl, $_ );
}

for (qw( stats_colors stats_lovers stats_palettes stats_patterns )) {
    can_ok( $cl, $_ );
}

done_testing;
