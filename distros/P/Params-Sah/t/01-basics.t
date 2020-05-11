#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;
use Test::Warnings qw(warning);

use Params::Sah qw(gen_validator);

# XXX differentiate carp and warn?

subtest "opt:disable=1" => sub {
    my $v = gen_validator({disable=>1}, "int");
    lives_ok { $v->(["x"]) };
};

subtest "opt:backend=Data::Sah::Tiny" => sub {
    test_needs "Data::Sah::Tiny";

    subtest "default value" => sub {
        my $v = gen_validator({backend=>"Data::Sah::Tiny"}, [int => default=>2]);
        my @args = (undef);
        $v->(\@args);
        is_deeply(\@args, [2]);
    };
};

subtest schemas => sub {
    my ($v, @args);

    subtest "default value" => sub {
        $v = gen_validator([int => default=>2]);
        @args = (undef);
        $v->(\@args);
        is_deeply(\@args, [2]);
    };

    subtest "coercion" => sub {
        $v = gen_validator([array => 'x.perl.coerce_rules'=>['From_str::comma_sep']]);
        @args = ("a, b, c");
        $v->(\@args);
        is_deeply(\@args, [['a','b','c']]);
    };
};

subtest "opt:allow_extra, \$OPT_ALLOW_EXTRA" => sub {
    my $v;

    subtest positional => sub {
        $v = gen_validator({}, "int", "int");
        lives_ok { $v->([1,1]) };
        lives_ok { $v->([1,undef]) };
        dies_ok  { $v->([1,1,1]) };

        $v = gen_validator({allow_extra=>1}, "int", "int");
        lives_ok { $v->([1,1]) };
        lives_ok { $v->([1,1,1]) };
        dies_ok  { $v->(["x",1]) };

        {
            local $Params::Sah::OPT_ALLOW_EXTRA=1;
            $v = gen_validator("int", "int");
            lives_ok { $v->([1,1]) };
            lives_ok { $v->([1,1,1]) };
            dies_ok  { $v->(["x",1]) };
        }
    };
    subtest named => sub {
        $v = gen_validator({named=>1}, foo=>"int", bar=>"int");
        lives_ok { $v->({foo=>1,bar=>1}) };
        lives_ok { $v->({foo=>1,bar=>undef}) };
        dies_ok  { $v->({foo=>1,bar=>1,baz=>1}) };

        $v = gen_validator({named=>1, allow_extra=>1}, foo=>"int", bar=>"int");
        lives_ok { $v->({foo=>1,bar=>1}) };
        lives_ok { $v->({foo=>1,bar=>undef}) };
        lives_ok { $v->({foo=>1,bar=>1,baz=>1}) };
        dies_ok  { $v->({foo=>"x",bar=>1,baz=>1}) };

        {
            local $Params::Sah::OPT_ALLOW_EXTRA=1;
            $v = gen_validator({named=>1}, foo=>"int", bar=>"int");
            lives_ok { $v->({foo=>1,bar=>1}) };
            lives_ok { $v->({foo=>1,bar=>undef}) };
            lives_ok { $v->({foo=>1,bar=>1,baz=>1}) };
            dies_ok  { $v->({foo=>"x",bar=>1,baz=>1}) };
        }
    };
};

subtest '$OPT_DISABLE=1' => sub {
    local $Params::Sah::OPT_DISABLE = 1;
    my $v = gen_validator("int");
    lives_ok { $v->(["x"]) };
};

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

subtest "opt:named=0 opt:optional_params opt:on_invalid=croak (default)" => sub {
    my $v = gen_validator({optional_params=>[1]}, "str*", "int");
    dies_ok  { $v->([]) };
    lives_ok { $v->(["name"]) };
    lives_ok { $v->(["name", 10]) };
    dies_ok  { $v->(["name", "x"]) };
};

subtest "opt:on_invalid=die opt:optional_params" => sub {
    my $v = gen_validator({optional_params=>[1]}, "str*", "int");
    dies_ok  { $v->([]) };
    lives_ok { $v->(["name"]) };
    lives_ok { $v->(["name", 10]) };
    dies_ok  { $v->(["name", "x"]) };
};

subtest "opt:named=1 opt:optional_params" => sub {
    my $v = gen_validator({named=>1, optional_params=>["age"]}, name=>"str*", age=>"int");
    dies_ok  { $v->({}) };
    lives_ok { $v->({name=>"name"}) };
    lives_ok { $v->({name=>"name", age=>10}) };
    dies_ok  { $v->({name=>"name", age=>"x"}) };
};

subtest '$OPT_NAMED=1' => sub {
    local $Params::Sah::OPT_NAMED = 1;
    my $v = gen_validator(name=>"str*", age=>"int");
    lives_ok { $v->({name=>"name", age=>undef}) };
};

subtest "opt:on_invalid=return opt:invalid_detail=0 opt:optional_params" => sub {
    my $v = gen_validator({named=>1, on_invalid=>"return", optional_params=>["age"]}, name=>"str*", age=>"int");
    is($v->({}), 0);
    is($v->({name=>"name"}), 1);
    is($v->({name=>"name", age=>10}), 1);
    is($v->({name=>"name", age=>"x"}), 0);
};

subtest "opt:on_invalid=return opt:invalid_detail=1 opt:optional_params" => sub {
    my $v = gen_validator({named=>1, on_invalid=>"return", optional_params=>["age"]}, name=>"str*", age=>"int");
    ok(!$v->({}));
    ok($v->({name=>"name"}));
    ok($v->({name=>"name", age=>10}));
    ok($v->({name=>"name", age=>undef}));
    ok(!$v->({name=>"name", age=>"x"}));
};

subtest "unknown options -> dies" => sub {
    dies_ok { gen_validator({foo=>1}, "int") };
};

subtest "opt:on_invalid invalid -> dies" => sub {
    dies_ok { gen_validator({on_invalid=>"foo"}, "int") };
};

# XXX: test opt:on_invalid=die
# XXX: test opt:on_invalid=warn
# XXX: test opt:on_invalid=carp

DONE_TESTING:
done_testing;
