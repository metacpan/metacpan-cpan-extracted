#!perl -T

use Test::More tests => 32;

use Personality::Type::MBTI;

my $mbti = Personality::Type::MBTI->new();

my %dominant = (
    enfj => 'fe',
    enfp => 'ne',
    entj => 'te',
    entp => 'ne',
    esfj => 'fe',
    esfp => 'se',
    estj => 'te',
    estp => 'se',
    infj => 'ni',
    infp => 'fi',
    intj => 'ni',
    intp => 'ti',
    isfj => 'si',
    isfp => 'fi',
    istj => 'si',
    istp => 'ti',
);

# test all the types

for my $w (qw/e i/) {
    for my $x (qw/s n/) {
        for my $y (qw/t f/) {
            for my $z (qw/p j/) {
                my @test     = ( $w, $x, $y, $z ) x 4;
                my $type     = $mbti->type(@test);
                my $dominant = $mbti->dominant($type);
                is( $dominant, $dominant{$type}, "dominant($type) is $dominant{$type}" );
            }
        }
    }
}

my %auxiliary = (
    enfj => 'ni',
    enfp => 'fi',
    entj => 'ni',
    entp => 'ti',
    esfj => 'si',
    esfp => 'fi',
    estj => 'si',
    estp => 'ti',
    infj => 'ne',
    infp => 'fe',
    intj => 'ne',
    intp => 'te',
    isfj => 'se',
    isfp => 'fe',
    istj => 'se',
    istp => 'te',
);

# test all the types

for my $w (qw/e i/) {
    for my $x (qw/s n/) {
        for my $y (qw/t f/) {
            for my $z (qw/p j/) {
                my @test     = ( $w, $x, $y, $z ) x 4;
                my $type     = $mbti->type(@test);
                my $auxiliary = $mbti->auxiliary($type);
                is( $auxiliary, $auxiliary{$type}, "auxiliary($type) is $auxiliary{$type}" );
            }
        }
    }
}
