use strict;
use warnings;
use Test::More;
use Data::Dumper;
use PLON;
use Encode;

subtest 'Normal mode', sub {
    # Given UTF-8 string.
    my $src = "\x{3042}";
    # When encode to PLON
    my $plon = PLON->new->encode($src);
    # Then response is encoded
    ok !Encode::is_utf8($plon);
    # And response is 'あ'
    is $plon, encode_utf8(qq!"\x{3042}"!);
    # When decode the response,
    my $decoded = PLON->new->decode($plon);
    # Then got a original source.
    is $decoded, $src;
    # You can decode with 'eval'.
    is eval "use utf8; $plon", $src;
};

subtest 'Ascii mode', sub {
    # Given UTF-8 string.
    my $src = "\x{3042}a";
    # WHen encode to PLON
    my $plon = PLON->new->ascii(1)->encode($src);
    # Then response is encoded
    ok !Encode::is_utf8($plon);
    # And response is 'あ'
    is $plon, q{"\x{3042}a"};
    # When decode the response,
    my $decoded = PLON->new->decode($plon);
    # Then got a original source.
    is $decoded, $src;
    # You can decode with 'eval'.
    is eval "use utf8; $plon", $src;
};

done_testing;

