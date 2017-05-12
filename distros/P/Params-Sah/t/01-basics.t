#!perl

use 5.010;
use strict;
use warnings;

use Params::Sah qw(gen_validator);
use Test::Exception;
use Test::More 0.98;
use Test::Warnings qw(warning);

# XXX differentiate carp and warn?

subtest "opt:on_invalid=carp" => sub {
    my $v = gen_validator({on_invalid=>'carp'}, "str*", "int");
    isnt(warning { $v->([]) }, '');
    is  (warning { $v->(["name"]) }, '');
    is  (warning { $v->(["name", 10]) }, '');
    isnt(warning { $v->(["name", "x"]) }, '');
} if 0; # disabled for now, always produces ARRAY(0x....)?

subtest "opt:on_invalid=warn" => sub {
    my $v = gen_validator({on_invalid=>'warn'}, "str*", "int");
    isnt(warning { $v->([]) }, '');
    is  (warning { $v->(["name"]) }, '');
    is  (warning { $v->(["name", 10]) }, '');
    isnt(warning { $v->(["name", "x"]) }, '');
} if 0; # disabled for now, always produces ARRAY(0x....)?

# XXX differentiate croak and die?

subtest "opt:named=0 opt:on_invalid=croak (default)" => sub {
    my $v = gen_validator("str*", "int");
    dies_ok  { $v->([]) };
    lives_ok { $v->(["name"]) };
    lives_ok { $v->(["name", 10]) };
    dies_ok  { $v->(["name", "x"]) };
};

subtest "opt:on_invalid=die" => sub {
    my $v = gen_validator("str*", "int");
    dies_ok  { $v->([]) };
    lives_ok { $v->(["name"]) };
    lives_ok { $v->(["name", 10]) };
    dies_ok  { $v->(["name", "x"]) };
};

subtest "opt:named=1" => sub {
    my $v = gen_validator({named=>1}, name=>"str*", age=>"int");
    dies_ok  { $v->({}) };
    lives_ok { $v->({name=>"name"}) };
    lives_ok { $v->({name=>"name", age=>10}) };
    dies_ok  { $v->({name=>"name", age=>"x"}) };
};

subtest "opt:on_invalid=bool" => sub {
    my $v = gen_validator({named=>1, on_invalid=>"bool"}, name=>"str*", age=>"int");
    is($v->({}), 0);
    is($v->({name=>"name"}), 1);
    is($v->({name=>"name", age=>10}), 1);
    is($v->({name=>"name", age=>"x"}), 0);
};

subtest "opt:on_invalid=str" => sub {
    my $v = gen_validator({named=>1, on_invalid=>"str"}, name=>"str*", age=>"int");
    isnt($v->({}), '');
    is($v->({name=>"name"}), '');
    is($v->({name=>"name", age=>10}), '');
    isnt($v->({name=>"name", age=>"x"}), '');
};

# XXX: test invalid on_invalid value

# XXX: test opt:on_invalid=die
# XXX: test opt:on_invalid=warn
# XXX: test opt:on_invalid=carp

DONE_TESTING:
done_testing;
