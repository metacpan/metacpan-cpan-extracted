#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Perinci::Result::Format::Lite;

my $fmt = \&Perinci::Result::Format::Lite::format;

like($fmt->([200, "OK", {}], 'foo'), qr/\{\}/, "unknown format -> fallback to json-pretty");

subtest "format=text-simple" => sub {
    is($fmt->([200, "OK"], 'text-simple'), "");
    is($fmt->([200, "OK", "a"], 'text-simple'), "a\n", "newline appended");
    is($fmt->([200, "OK", "a\n"], 'text-simple'), "a\n", "newline already exists so not added");
    is($fmt->([404, "Not found", "a\n"], 'text-simple'), "ERROR 404: Not found\n", "error");

    # XXX test: hash -> 2-column table
    # XXX test: aos -> table
    # XXX test: aoaos -> table
    # XXX test: aohos -> table
    # XXX test: table_column_orders
};

subtest "format=text-pretty" => sub {
    like($fmt->([200, "OK", {a=>1}], 'text-pretty'), qr/key[ ]*\|[ ]*value.+a[ ]*\|[ ]*1/s, "hash");

    # XXX test: aos -> table
    # XXX test: aoaos -> table
    # XXX test: aohos -> table
    # XXX test: table_column_orders
};

subtest "format=json-pretty" => sub {
    like($fmt->([200, "OK", [1,2]], 'json-pretty'),
         qr/\[\s*
            200,\s*
            "OK",\s*
            \[\s*1,\s*2\s*\]
            (,\s*\{\})?
            \s*\]/sx);
};

# XXX test: opt:naked=1
# XXX test: opt:cleanse=0

subtest "meta:table.fields" => sub {
    like($fmt->(
        [200,
         "OK",
         [{a=>1}, {b=>2}, {c=>3}, {d=>4}],
         {
             'table.fields'=>[qw/a b c e/],
         },],
        "text-pretty"),
         qr/^\| \s* a \s* \| \s* b \s* \| \s* c \s* \| \s* d \s* \|$/mx);
};

subtest "meta:table.hide_unknown_fields" => sub {
    like($fmt->(
        [200,
         "OK",
         [{a=>1, e=>5}, {b=>2, f=>6}, {c=>3, d=>4}],
         {
             'table.fields'=>[qw/a b f g/],
             'table.hide_unknown_fields'=>1,
         },],
        "text-pretty"),
         qr/^\| \s* a \s* \| \s* b \s* \| \s* f \s* \| \s* g \s* \|$/mx);
};

subtest "meta:table.field_labels" => sub {
    like($fmt->(
        [200,
         "OK",
         [{apple=>1}, {baboon=>2}, {crossbow=>3}, {doritos=>4}],
         {
             'table.fields'=>[qw/apple baboon crossbow edamame/],
             'table.field_labels'=>['fruit', 'animal', undef, 'plant'],
         },],
        "text-pretty"),
         qr/^\| \s* fruit \s* \| \s* animal \s* \| \s* crossbow \s* \| \s* doritos \s* \|$/mx);
};

subtest "meta:table.field_units" => sub {
    like($fmt->(
        [200,
         "OK",
         [{a=>1}, {b=>2}, {c=>3}, {d=>4}],
         {
             'table.fields'=>[qw/a b c e/],
             'table.field_units'=>[qw/u1 u2 u3 u4/],
         },],
        "text-pretty"),
         qr/^\| \s* a \s\(u1\) \s* \| \s* b \s\(u2\) \s* \| \s* c \s\(u3\) \s* \| \s* d \s* \|$/mx);
};

subtest "meta:table.field_formats" => sub {
    like($fmt->(
        [200,
         "OK",
         [
             {a=>0, idx=>1, time=>1465744527, date=>1465744527},
             # XXX time=DateTime instance
             # XXX time=Time::Moment instance
         ],
         {
             'table.fields'=>[qw/idx time date b/],
             'table.field_formats'=>[undef, qw/iso8601_datetime iso8601_date/, 'foo'],
         },],
        "text-pretty"),
         qr/^\| \s* 1 \s* \| \s* 2016-06-12T15:15:27Z \s* \| \s* 2016-06-12 \s* \| \s* 0 \s* \|$/mx);
};

subtest "meta:table.default_field_format" => sub {
    test_needs 'Number::Format::BigFloat';

    like($fmt->(
        [200,
         "OK",
         [
             {date=>1465744527, num=>123, num2=>456, num3=>789},
             # XXX time=DateTime instance
             # XXX time=Time::Moment instance
         ],
         {
             'table.fields'=>[qw/date num num2/],
             'table.field_formats'=>['iso8601_date', [number=>{precision=>2}], undef],
             'table.default_field_format'=>[number=>{precision=>1}],
         },],
        "text-pretty"),
         qr/^\| \s* 2016-06-12 \s* \| \s* 123\.00 \s* \| \s* 456\.0 \s* \| \s* 789\.0 \s* \|$/mx);
};

subtest "meta:table.field_format_code" => sub {
    test_needs 'Number::Format::BigFloat';

    like($fmt->(
        [200,
         "OK",
         [
             {date=>1465744527, num=>123, num2=>456, num3=>789},
             # XXX time=DateTime instance
             # XXX time=Time::Moment instance
         ],
         {
             'table.fields'=>[qw/date num num2/],
             'table.field_formats'=>['iso8601_date', [number=>{precision=>2}], undef],
             'table.default_field_format'=>[number=>{precision=>1}],
             'table.field_format_code'=>sub { $_[0] eq 'num3' ? [number=>{precision=>3}] : undef},
         },],
        "text-pretty"),
         qr/^\| \s* 2016-06-12 \s* \| \s* 123\.00 \s* \| \s* 456\.0 \s* \| \s* 789\.000 \s* \|$/mx);
};

subtest "meta:table.field_aligns" => sub {
    is($fmt->(
        [200,
         "OK",
         [
             {a=>"x",    left=>"x"   , right=>"x"   , middle=>"x"   , number1=>"1"   , number2__=>"1"   , number3=>"1e2"},
             {a=>"xx",   left=>"xx"  , right=>"xx"  , middle=>"xx"  , number1=>"-10" , number2__=>"-10" , number3=>"1.2e-1"},
             {a=>"xxx",  left=>"xxx" , right=>"xxx" , middle=>"xxx" , number1=>"100" , number2__=>"1.2" , number3=>"1.23e3"},
             {a=>"xxxx", left=>"xxxx", right=>"xxxx", middle=>"xxxx", number1=>"1000", number2__=>"1.23", number3=>"12.34e3"},
         ],
         {
             'table.fields'      =>[qw/left right middle number1 number2__ number3 b/],
             'table.field_aligns'=>[qw/left right middle number  number    number  b/],
         },],
        "text-pretty"),
       join(
           "",
           "+------+-------+--------+---------+-----------+----------+------+\n",
           "| left | right | middle | number1 | number2__ | number3  | a    |\n",
           "+------+-------+--------+---------+-----------+----------+------+\n",
           "| x    |     x |   x    |       1 |      1    |     1e2  | x    |\n",
           "| xx   |    xx |   xx   |     -10 |    -10    |   1.2e-1 | xx   |\n",
           "| xxx  |   xxx |  xxx   |     100 |      1.2  |  1.23e3  | xxx  |\n",
           "| xxxx |  xxxx |  xxxx  |    1000 |      1.23 | 12.34e3  | xxxx |\n",
           "+------+-------+--------+---------+-----------+----------+------+\n",
       ),
   );
};

subtest "meta:table.default_field_align" => sub {
    is($fmt->(
        [200,
         "OK",
         [
             {a=>"x",    left=>"x"   ,},
             {a=>"xx",   left=>"xx"  ,},
             {a=>"xxx",  left=>"xxx" ,},
             {a=>"xxxx", left=>"xxxx",},
         ],
         {
             'table.fields'      =>[qw/left/],
             'table.field_aligns'=>[qw/left/],
             'table.default_field_align'=>'right',
         },],
        "text-pretty"),
       join(
           "",
           "+------+------+\n",
           "| left |    a |\n",
           "+------+------+\n",
           "| x    |    x |\n",
           "| xx   |   xx |\n",
           "| xxx  |  xxx |\n",
           "| xxxx | xxxx |\n",
           "+------+------+\n",
       ),
   );
};

subtest "meta:table.default_field_align" => sub {
    is($fmt->(
        [200,
         "OK",
         [
             {a=>"x",    b=>"x",    left=>"x"   ,},
             {a=>"xx",   b=>"xx",   left=>"xx"  ,},
             {a=>"xxx",  b=>"xxx",  left=>"xxx" ,},
             {a=>"xxxx", b=>"xxxx", left=>"xxxx",},
         ],
         {
             'table.fields'      =>[qw/left/],
             'table.field_aligns'=>[qw/left/],
             'table.default_field_align'=>'right',
             'table.field_align_code'=>sub { $_[0] eq 'b' ? 'center' : undef },
         },],
        "text-pretty"),
       join(
           "",
           "+------+------+------+\n",
           "| left |    a |  b   |\n",
           "+------+------+------+\n",
           "| x    |    x |  x   |\n",
           "| xx   |   xx |  xx  |\n",
           "| xxx  |  xxx | xxx  |\n",
           "| xxxx | xxxx | xxxx |\n",
           "+------+------+------+\n",
       ),
   );
};

subtest "meta:table.field_orders" => sub {
    like($fmt->(
        [200,
         "OK",
         [
             {a=>0, b=>1, c=>2, d=>3, e1=>4, e2=>5, e3=>6},
             # XXX time=DateTime instance
             # XXX time=Time::Moment instance
         ],
         {
             'table.field_orders'=>['a', 'b', 'c', qr/^e/ => sub { $_[0] cmp $_[1] }],
         },],
        "text-pretty"),
         qr/^\| \s* a \s* \| \s* b \s* \| \s* c \s* \| \s* e1 \s* \| \s* e2 \s* \| \s* e3 \s* \| \s* d \s* \|$/mx);
};

done_testing();
