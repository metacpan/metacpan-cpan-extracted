use strict;
use warnings;
use Test::More;
use Redis::LeaderBoardMulti;
use Test::Warn;

sub pack_scores {
    my ($order, $scores) = @_;
    my $l = Redis::LeaderBoardMulti->new(
        key   => 'sortable-member',
        order => $order,
    );
    return $l->_pack_scores($scores);
}

sub unpack_scores {
    my ($order, $packed_scores) = @_;
    my $l = Redis::LeaderBoardMulti->new(
        key   => 'sortable-member',
        order => $order,
    );
    return $l->_unpack_scores($packed_scores);
}

sub test_unpack {
    my ($order, $scores, $str) = @_;
    my $packed =  pack_scores($order, $scores);
    my $unpacked = [unpack_scores($order, $packed)];
    my $ok = is_deeply $unpacked, $scores,
        "test_unpack [@{[join ', ', @$order]}], [@{[join ', ', @$scores]}]";
    my $strpacked = join ' ', map {sprintf '%02X', $_} unpack 'W*', $packed;
    is $strpacked, $str;
    note "packed: $str";
    note "unpacked: [@{[join ', ', @$unpacked]}]";
}

subtest 'compare score' => sub {
    cmp_ok pack_scores(['desc'], [ 0]), 'gt', pack_scores(['desc'], [  1]);
    cmp_ok pack_scores([ 'asc'], [ 0]), 'lt', pack_scores([ 'asc'], [  1]);
    cmp_ok pack_scores(['desc'], [-1]), 'gt', pack_scores(['desc'], [  0]);
    cmp_ok pack_scores([ 'asc'], [-1]), 'lt', pack_scores([ 'asc'], [  0]);
    cmp_ok pack_scores(['desc'], [-2]), 'gt', pack_scores(['desc'], [ -1]);
    cmp_ok pack_scores([ 'asc'], [-2]), 'lt', pack_scores([ 'asc'], [ -1]);
    cmp_ok pack_scores(['desc'], [ 1]), 'gt', pack_scores(['desc'], [256]);
    cmp_ok pack_scores([ 'asc'], [ 1]), 'lt', pack_scores([ 'asc'], [256]);

    my $INT_MAX = ~0 >> 1;
    my $INT_MIN = -$INT_MAX - 1;
    cmp_ok pack_scores(['desc'], [$INT_MIN  ]), 'gt', pack_scores(['desc'], [$INT_MIN+1]);
    cmp_ok pack_scores([ 'asc'], [$INT_MIN  ]), 'lt', pack_scores([ 'asc'], [$INT_MIN+1]);
    cmp_ok pack_scores(['desc'], [$INT_MAX-1]), 'gt', pack_scores(['desc'], [$INT_MAX  ]);
    cmp_ok pack_scores([ 'asc'], [$INT_MAX-1]), 'lt', pack_scores([ 'asc'], [$INT_MAX  ]);
    cmp_ok pack_scores(['desc'], [$INT_MIN  ]), 'gt', pack_scores(['desc'], [$INT_MAX  ]);
    cmp_ok pack_scores([ 'asc'], [$INT_MIN  ]), 'lt', pack_scores([ 'asc'], [$INT_MAX  ]);
};

subtest 'compare multi scores' => sub {
    cmp_ok pack_scores(['desc', 'desc'], [0, 0]), 'gt', pack_scores(['desc', 'desc'], [0, 1]);
    cmp_ok pack_scores([ 'asc',  'asc'], [0, 0]), 'lt', pack_scores([ 'asc',  'asc'], [0, 1]);
};

subtest 'unpack' => sub {
    test_unpack(['desc'], [  0], "7F FF FF FF FF FF FF FF");
    test_unpack(['desc'], [  1], "7F FF FF FF FF FF FF FE");
    test_unpack(['desc'], [ -1], "80 00 00 00 00 00 00 00");
    test_unpack(['desc'], [256], "7F FF FF FF FF FF FE FF");
    test_unpack(['desc'], [ 0x7FFFFFFF], "7F FF FF FF 80 00 00 00");
    test_unpack(['desc'], [-0x80000000], "80 00 00 00 7F FF FF FF");

    test_unpack(['asc'], [  0], "80 00 00 00 00 00 00 00");
    test_unpack(['asc'], [  1], "80 00 00 00 00 00 00 01");
    test_unpack(['asc'], [ -1], "7F FF FF FF FF FF FF FF");
    test_unpack(['asc'], [256], "80 00 00 00 00 00 01 00");
    test_unpack(['asc'], [ 0x7FFFFFFF], "80 00 00 00 7F FF FF FF");
    test_unpack(['asc'], [-0x80000000], "7F FF FF FF 80 00 00 00");
};


sub test_32bit_integer {
    my ($order, $scores) = @_;
    my $packed = pack_scores($order, $scores);
    my $packed32 = do {
        local $Redis::LeaderBoardMulti::SUPPORT_64BIT = 0;
        pack_scores($order, $scores);
    };
    my $strpacked = join ' ', map {sprintf '%02X', $_} unpack 'W*', $packed;
    my $strpacked32 = join ' ', map {sprintf '%02X', $_} unpack 'W*', $packed32;
    is $packed, $packed32, "'$strpacked' = '$strpacked32' [@{[join ', ', @$scores]}]";
}

subtest '32bit/64bit conversion' => sub {
    plan skip_all => 'Your perl does not support 64bit integer' unless $Redis::LeaderBoardMulti::SUPPORT_64BIT;
    test_32bit_integer(['asc'], [ 0]);
    test_32bit_integer(['asc'], [ 1]);
    test_32bit_integer(['asc'], [-1]);
    test_32bit_integer(['asc'], [ 0x7FFFFFFF]);
    test_32bit_integer(['asc'], [-0x80000000]);
};

subtest 'warn 32bit overflow' => sub {
    local $Redis::LeaderBoardMulti::SUPPORT_64BIT = 0;

    warning_is  {
        unpack_scores(['asc'], "\x80\x00\x00\x00\x7F\xFF\xFF\xFF");
    } undef, "0x7FFFFFFF will not overflow";

    warning_like  {
        unpack_scores(['asc'], "\x80\x00\x00\x00\x80\x00\x00\x00");
    } qr/score overflow/i, "0x80000000 will overflow";

    warning_is  {
        unpack_scores(['asc'], "\x7F\xFF\xFF\xFF\x80\x00\x00\x00");
    } undef, "-0x80000000 will not overflow";

    warning_like  {
        unpack_scores(['asc'], "\x7F\xFF\xFF\xFF\x7F\xFF\xFF\xFF");
    } qr/score overflow/i, "-0x80000001 will overflow";
};

done_testing;
