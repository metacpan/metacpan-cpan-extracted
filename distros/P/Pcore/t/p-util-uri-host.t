#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;

my $test_data = {
    name => [
        'aaa.com'      => 'aaa.com',
        '..a...com...' => 'a.com',
        'мама.рф'      => 'xn--80aa8ab.xn--p1ai',
    ],
    is_ipv4 => [
        '1.2.3.4'          => 1,
        '127.0.0.1'        => 1,
        '300.300.300.300'  => 0,
        '127'              => 1,
        '1.2'              => 1,
        '1.23.54'          => 1,
        '1.2.3.4.5'        => 0,
        '4.3.2.16'         => 1,    # decimal
        '004.003.002.020'  => 1,    # octal
        '0x4.0x3.0x2.0x10' => 1,    # hexadecimal
        '4.003.002.0x10'   => 1,    # mix
    ],
    is_ipv6 => [
        '2001:0db8:0a0b:12f0:0000:0000:0000:0001' => 1,
        '2001:db8:a0b:12f0::1'                    => 1,
        '2001:db8::2:1'                           => 1,
    ],
    pub_suffix => [
        'asd.qwe1'                                  => undef,
        'bbb.ck'                                    => 'bbb.ck',                               # *.ck
        'aaa.bbb.ck'                                => 'bbb.ck',                               # *.ck
        'www.ck'                                    => 'ck',                                   # !www.ck
        'aaa.www.ck'                                => 'ck',                                   # !www.ck
        'kawasaki.jp'                               => 'kawasaki.jp',                          # *.kawasaki.jp
        'aaa.kawasaki.jp'                           => 'aaa.kawasaki.jp',                      # *.kawasaki.jp
        'city.kawasaki.jp'                          => 'kawasaki.jp',                          # !city.kawasaki.jp
        'aaa.city.kawasaki.jp'                      => 'kawasaki.jp',                          # !city.kawasaki.jp
        '网络.cn'                                     => 'xn--io0a7i.cn',
        'aaa.bbb.网络.cn'                             => 'xn--io0a7i.cn',
        'xn--cg4bki'                                => 'xn--cg4bki',
        'com'                                       => 'com',
        'service.gov.uk'                            => 'service.gov.uk',
        'aaa.service.gov.uk'                        => 'service.gov.uk',
        'aaa.bbb.sch.uk'                            => 'bbb.sch.uk',                           # *.sch.uk
        'bbb.sch.uk'                                => 'bbb.sch.uk',                           # *.sch.uk
        'sch.uk'                                    => 'sch.uk',
        'eu-central-1.compute...amazonaws.com'      => 'eu-central-1.compute.amazonaws.com',
        '..sss.eu-central-1..compute.amazonaws.com' => 'eu-central-1.compute.amazonaws.com',
    ],
    root_domain => [
        'asdas.cwedfwe'  => undef,                                                             # unknown pub. suffix
        'bbb.sch.uk'     => undef,                                                             # *.sch.uk
        'aaa.bbb.sch.uk' => 'aaa.bbb.sch.uk',                                                  # *.sch.uk
    ],
    is_root_domain => [
        'aaa.com'          => 1,
        'asdasd.asdas.com' => 0,
    ],
};

our $TESTS;

for my $method ( keys $test_data->%* ) {
    $TESTS += $test_data->{$method}->@* / 2;
}

plan tests => $TESTS;

for my $method ( sort keys $test_data->%* ) {
    for my $test ( P->list->pairs( $test_data->{$method}->@* ) ) {
        my $host = P->host( $test->[0] );

        my $res1 = $host->can($method) ? $host->$method : $host->{$method};
        my $res2 = $test->[1] // q[];

        if ( $res1 ne $res2 ) {
            say qq[RESULT: "$res1", EXPECTED: "$res2"];
        }

        ok( $res1 eq $res2, $method . '_' . $host->{name} );
    }
}

done_testing $TESTS;

1;
__END__
=pod

=encoding utf8

=cut
