#!perl

use 5.010;
use strict;
use warnings;

use Perinci::AccessUtil qw(insert_riap_stuffs_to_res
                           strip_riap_stuffs_from_res
                           decode_args_in_riap_req);
use Test::More 0.98;

subtest "insert_riap_stuffs_to_res" => sub {
    is_deeply(insert_riap_stuffs_to_res([200,"OK",undef, {"riap.v"=>1.2}]),
              [200,"OK",undef,{"riap.v"=>1.2}],
              "existing version");
    is_deeply(insert_riap_stuffs_to_res([200,"OK",undef]),
              [200,"OK",undef,{"riap.v"=>1.1}],
              "default for default version is 1.1");
    is_deeply(insert_riap_stuffs_to_res([200,"OK",undef], 1.2),
              [200,"OK",undef,{"riap.v"=>1.2}],
              "default version");
    subtest result_encoding => sub {
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0"]),
                  [200,"OK","\0\0\0",{"riap.v"=>1.1}],
                  "encoding is not active under version 1.1");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0"], 1.2),
                  [200,"OK","AAAA",{"riap.v"=>1.2, "riap.result_encoding"=>"base64"}],
                  "encoding is automatically active under version 1.2");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0"], 1.2, {v=>1.1, result=>{schema=>["str"]}}),
                  [200,"OK","\0\0\0",{"riap.v"=>1.2}],
                  "encoding is not active if result schema says type is not buf");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0"], 1.2, {v=>1.1, result=>{schema=>["buf"]}}),
                  [200,"OK","AAAA",{"riap.v"=>1.2, "riap.result_encoding"=>"base64"}],
                  "encoding is active if result schema says type is buf");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0",{"riap.result_encoding"=>"foo"}], 1.2),
                  [200,"OK","\0\0\0",{"riap.v"=>1.2, "riap.result_encoding"=>"foo"}],
                  "encoding is not active if riap.result_encoding is already set");
        is_deeply(insert_riap_stuffs_to_res([200,"OK",[]], 1.2),
                  [200,"OK",[],{"riap.v"=>1.2}],
                  "encoding is not active if result is not a string");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","abc"], 1.2),
                  [200,"OK","abc",{"riap.v"=>1.2}],
                  "encoding is not active if string doesn't contain nonprintable");
        is_deeply(insert_riap_stuffs_to_res([200,"OK","\0\0\0"], 1.2, undef, 0),
                  [200,"OK","\0\0\0",{"riap.v"=>1.2}],
                  "encoding is not active if given option encode=0");
    };
};

subtest "strip_riap_stuffs_from_res" => sub {
    is_deeply(strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.3}])->[0], 501,
              "unsupported version");

    subtest "v1.1" => sub {
        is_deeply(strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.1}]), [200,"OK",undef,{"riap.v"=>1.1}],
                  "pass, riap.* keys not stripped");
        is_deeply(strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.1, "riap.foo"=>1}])->[0], 200,
                  "pass, doesn't check riap.* keys");
    };

    subtest "v1.2" => sub {
        is_deeply(strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.2, "riap.foo"=>1}])->[0], 501,
                  "unknown riap.* key");
        is_deeply(strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.2, "riap.result_encoding"=>"foo"}])->[0], 501,
                  "unknown riap.result_encoding value");
        is_deeply(strip_riap_stuffs_from_res([200,"OK","AAAA",{"riap.v"=>1.2, "riap.result_encoding"=>"base64"}]), [200,"OK","\0\0\0",{}],
                  "base64 decoding of result");
    };
};

subtest "decode_args_in_riap_req" => sub {
    subtest "v1.1" => sub {
        is_deeply(decode_args_in_riap_req({args=>{"a:base64"=>"AAAA", b=>"\0"}}),
                  {args=>{"a:base64"=>"AAAA", b=>"\0"}},
                  "decoding not active when version=1.1");
        is_deeply(decode_args_in_riap_req({v=>1.2, args=>{"a:base64"=>"AAAA", b=>"\0"}}),
                  {v=>1.2, args=>{"a"=>"\0\0\0", b=>"\0"}},
                  "decoding active when version=1.2");
    };
};

done_testing;
