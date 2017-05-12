use strict;
use warnings;
use Test::More;
use Panda::URI qw/encode_uri_component decode_uri_component/;

ok(encode_uri_component("hello world") eq "hello%20world");
ok(encode_uri_component("http://ya.ru") eq "http%3A%2F%2Fya.ru");
ok(encode_uri_component("hello guy! how ru? пиздец нах") eq "hello%20guy%21%20how%20ru%3F%20%D0%BF%D0%B8%D0%B7%D0%B4%D0%B5%D1%86%20%D0%BD%D0%B0%D1%85");
ok(encode_uri_component("hello world", 1) eq "hello+world");
ok(decode_uri_component("hello%20world") eq "hello world");
ok(decode_uri_component("hello+world") eq "hello world");
ok(decode_uri_component("http%3A%2F%2Fya.ru") eq "http://ya.ru");
ok(decode_uri_component("hello%20guy%21%20how%20ru%3F%20%D0%BF%D0%B8%D0%B7%D0%B4%D0%B5%D1%86%20%D0%BD%D0%B0%D1%85") eq "hello guy! how ru? пиздец нах");

done_testing();
