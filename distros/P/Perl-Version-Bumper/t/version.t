use v5.10;
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Exception qw( dies );
use Perl::Version::Bumper qw(
    version_fmt
    version_use
    stable_version
    stable_version_inc
    stable_version_dec
);

my %tests = ( #    fmt    use   fix    inc    dec
    '5.010'    => ' 5.010 v5.10  5.010  5.012  5.008',
    'v5.10'    => ' 5.010 v5.10  5.010  5.012  5.008',
    '5.029001' => ' 5.029 v5.29  5.028  5.030  5.028',
    '5.041007' => ' 5.041 v5.41  5.040  5.042  5.040',
);

for my $v ( sort keys %tests ) {
    my @expected = map /\Aundef\z/ ? undef : $_, split ' ', $tests{$v};
    is( version_fmt($v),        $expected[0], "version_fmt( $v )" );
    is( version_use($v),        $expected[1], "version_use( $v )" );
    is( stable_version($v),     $expected[2], "stable_version( $v )" );
    is( stable_version_inc($v), $expected[3], "stable_version_inc( $v )" );
    is( stable_version_dec($v), $expected[4], "stable_version_dec( $v )" );
}

# some fails
for my $v (qw( 5.008 2 4.036 )) {
    like(
        dies { version_fmt($v) },
        qr/\AUnsupported Perl version: \Q$v\E /,
        "version_fmt( $v ) fails"
    );
}

done_testing
