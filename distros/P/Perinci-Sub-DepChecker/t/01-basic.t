#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use File::Which;
use Perinci::Sub::DepChecker qw(
                                   check_deps
                                   dep_satisfy_rel
                                   list_mentioned_dep_clauses
                           );

sub test_check_deps {
    my %args = @_;
    my $name = $args{name};
    my $res = check_deps($args{deps});
    if ($args{met}) {
        ok(!$res, "$name met") or diag($res);
    } else {
        ok( $res, "$name unmet");
    }
}

sub deps_met {
    test_check_deps(deps=>$_[0], name=>$_[1], met=>1);
}

sub deps_unmet {
    test_check_deps(deps=>$_[0], name=>$_[1], met=>0);
}

deps_met   {}, "empty deps";

deps_unmet {xxx=>1}, "unknown type";

{
    local $ENV{A} = 1;
    local $ENV{B} = 0;
    local $ENV{C};
    deps_met   {env=>"A"}, "env A";
    deps_unmet {env=>"B"}, "env B";
    deps_unmet {env=>"C"}, "env C";
}

deps_met   {code=>sub{1}}, "sub 1";
deps_unmet {code=>sub{ }}, "sub 2";

deps_met   {exec=>$^X}, "exec 1";
deps_met   {exec=>$^X}, "exec 1";
deps_unmet {exec=>$^X."xxx"}, "exec 2";
subtest 'exec in PATH' => sub {
    plan skip_all => "currently only testing Unix (on Linux)"
        unless $^O eq 'linux';
    my ($perl_dir, $perl_name) = $^X =~ m!(.+)/(.+)!;
    plan skip_all => "currently only testing prog named 'perl'"
        unless $perl_name eq 'perl';
    local $ENV{PATH} = "$ENV{PATH}:$perl_dir";
    deps_met {exec=>$perl_name}, "perl (str)";

    # hash form
    deps_met {exec=>{name=>$perl_name}}, "perl (hash)";

    # min_version of perl
    deps_met   {exec=>{name=>'perl', min_version=>$]}}, "min_version 1";
    deps_unmet {exec=>{name=>'perl', min_version=>'9.999'}}, "min_version 2";

    # min_version of git
    subtest "min_version of git" => sub {
        plan skip_all => 'git is not available' unless which "git";
        deps_met   {exec=>{name=>'git', min_version=>1}}, "min_version 1"; # i'm assuming all git out there is >v1
        deps_unmet {exec=>{name=>'git', min_version=>'9.999'}}, "min_version 2";
    };
};

# perl's caching defeats this?
#my $d0 = {code=>sub {0}};
#my $d1 = {code=>sub {1}};

# still, something's strange, using this, if i enable dump() in check_all(),
# everything's ok. otherwise, "all 2b" fails.
#my $d0 = {xxx=>1};
#my $d1 = {};

deps_met   {all=>[]}, "all 0";
# example using $d0 & $d1
#deps_unmet {all=>[$d0]}, "all 1a";
#deps_met   {all=>[$d1]}, "all 1b";
deps_unmet {all=>[{xxx=>1}]}, "all 1a";
deps_met   {all=>[{}]}, "all 1b";
deps_unmet {all=>[{xxx=>1}, {xxx=>1}]}, "all 2a";
deps_unmet {all=>[{xxx=>1}, {}]}, "all 2b";
deps_unmet {all=>[{}, {xxx=>1}]}, "all 2c";
deps_met   {all=>[{}, {}]}, "all 2d";

deps_met   {all=>[]}, "all 0 again";
deps_unmet {all=>[{xxx=>1}]}, "all 1a again";

deps_met   {any=>[]}, "any 0";
deps_unmet {any=>[{xxx=>1}]}, "any 1a";
deps_met   {any=>[{}]}, "any 1b";
deps_unmet {any=>[{xxx=>1}, {xxx=>1}]}, "any 2a";
deps_met   {any=>[{xxx=>1}, {}]}, "any 2b";
deps_met   {any=>[{}, {xxx=>1}]}, "any 2c";
deps_met   {any=>[{}, {}]}, "any 2d";

deps_met   {none=>[]}, "none 0";
deps_met   {none=>[{xxx=>1}]}, "none 1a";
deps_unmet {none=>[{}]}, "none 1b";
deps_met   {none=>[{xxx=>1}, {xxx=>1}]}, "none 2a";
deps_unmet {none=>[{xxx=>1}, {}]}, "none 2b";
deps_unmet {none=>[{}, {xxx=>1}]}, "none 2c";
deps_unmet {none=>[{}, {}]}, "none 2d";

deps_unmet {any =>[{all=>[{xxx=>1}, {}, {xxx=>1}]},
                   {any=>[{xxx=>1}, {xxx=>1}, {xxx=>1}]}]},
    "complex boolean 1b";
deps_met   {none=>[{all=>[{xxx=>1}, {}, {xxx=>1}]},
                   {any=>[{xxx=>1}, {xxx=>1}, {xxx=>1}]}]},
    "complex boolean 1a";

subtest 'dep_satisfy_rel' => sub {
    my $c_no       = {b=>1};
    my $c_must     = {a=>1};
    my $c_must_not = {none=>[{a=>1}]};
    my $c_might    = {any=>[{a=>1}, {b=>1}]};
    my $c_imp      = {all=>[{a=>1}, {none=>[{a=>1}]}]};

    is(dep_satisfy_rel(a => {}), "");
    is(dep_satisfy_rel(a => $c_no), "");
    is(dep_satisfy_rel(a => $c_must), "must");

    is(dep_satisfy_rel(a => {all=>[]}), "");
    is(dep_satisfy_rel(a => {all=>[$c_no]}), "");
    is(dep_satisfy_rel(a => {all=>[$c_might]}), "might");
    is(dep_satisfy_rel(a => {all=>[$c_must]}), "must");
    is(dep_satisfy_rel(a => {all=>[$c_must_not]}), "must not");
    is(dep_satisfy_rel(a => {all=>[$c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[{}, {}]}), "");
    is(dep_satisfy_rel(a => {all=>[{}, $c_might]}), "might");
    is(dep_satisfy_rel(a => {all=>[{}, $c_must]}), "must");
    is(dep_satisfy_rel(a => {all=>[{}, $c_must_not]}), "must not");
    is(dep_satisfy_rel(a => {all=>[{}, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[$c_might, $c_might]}), "might");
    is(dep_satisfy_rel(a => {all=>[$c_might, $c_must]}), "must");
    is(dep_satisfy_rel(a => {all=>[$c_might, $c_must_not]}), "must not");
    is(dep_satisfy_rel(a => {all=>[$c_might, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[$c_must, $c_must]}), "must");
    is(dep_satisfy_rel(a => {all=>[$c_must, $c_must_not]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[$c_must, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[$c_must_not, $c_must_not]}),"must not");
    is(dep_satisfy_rel(a => {all=>[$c_must_not, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {all=>[$c_imp, $c_imp]}), "impossible");

    is(dep_satisfy_rel(a => {any=>[]}), "");
    is(dep_satisfy_rel(a => {any=>[$c_no]}), "");
    is(dep_satisfy_rel(a => {any=>[$c_might]}), "might");
    is(dep_satisfy_rel(a => {any=>[$c_must]}), "must");
    is(dep_satisfy_rel(a => {any=>[$c_must_not]}), "must not");
    is(dep_satisfy_rel(a => {any=>[$c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {any=>[{}, {}]}), "");
    is(dep_satisfy_rel(a => {any=>[{}, $c_might]}), "might");
    is(dep_satisfy_rel(a => {any=>[{}, $c_must]}), "might");
    is(dep_satisfy_rel(a => {any=>[{}, $c_must_not]}), "might");
    is(dep_satisfy_rel(a => {any=>[{}, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {any=>[$c_might, $c_might]}), "might");
    is(dep_satisfy_rel(a => {any=>[$c_might, $c_must]}), "might");
    is(dep_satisfy_rel(a => {any=>[$c_might, $c_must_not]}), "might");
    is(dep_satisfy_rel(a => {any=>[$c_might, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {any=>[$c_must, $c_must]}), "must");
    is(dep_satisfy_rel(a => {any=>[$c_must, $c_must_not]}), "might");
    is(dep_satisfy_rel(a => {any=>[$c_must, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {any=>[$c_must_not, $c_must_not]}),"must not");
    is(dep_satisfy_rel(a => {any=>[$c_must_not, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {any=>[$c_imp, $c_imp]}), "impossible");

    is(dep_satisfy_rel(a => {none=>[]}), "");
    is(dep_satisfy_rel(a => {none=>[$c_no]}), "");
    is(dep_satisfy_rel(a => {none=>[$c_might]}), "might");
    is(dep_satisfy_rel(a => {none=>[$c_must]}), "must not");
    is(dep_satisfy_rel(a => {none=>[$c_must_not]}), "must");
    is(dep_satisfy_rel(a => {none=>[$c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[{}, {}]}), "");
    is(dep_satisfy_rel(a => {none=>[{}, $c_might]}), "might");
    is(dep_satisfy_rel(a => {none=>[{}, $c_must]}), "must not");
    is(dep_satisfy_rel(a => {none=>[{}, $c_must_not]}), "must");
    is(dep_satisfy_rel(a => {none=>[{}, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[$c_might, $c_might]}), "might");
    is(dep_satisfy_rel(a => {none=>[$c_might, $c_must]}), "must not");
    is(dep_satisfy_rel(a => {none=>[$c_might, $c_must_not]}), "must");
    is(dep_satisfy_rel(a => {none=>[$c_might, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[$c_must, $c_must]}), "must not");
    is(dep_satisfy_rel(a => {none=>[$c_must, $c_must_not]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[$c_must, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[$c_must_not, $c_must_not]}), "must");
    is(dep_satisfy_rel(a => {none=>[$c_must_not, $c_imp]}), "impossible");
    is(dep_satisfy_rel(a => {none=>[$c_imp, $c_imp]}), "impossible");

    is(dep_satisfy_rel(a => {a=>1, b=>1}), "must", "all dep searched");
};

is_deeply(list_mentioned_dep_clauses({any=>[{a=>1}, {a=>1, b=>2}]}),
          [qw/any a b/],
          "list_mentioned_dep_clauses");

subtest "dep: pkg & func" => sub {
    eval { require Perinci::Access };
    plan skip_all => 'Perinci::Access not available' if $@;
    eval { require Perinci::Examples };
    plan skip_all => 'Perinci::Examples not available' if $@;
    deps_met   {pkg =>'/Perinci/Examples/'}, "pkg";
    deps_unmet {pkg =>'/Perinci/Examples'}, "not pkg";
    deps_unmet {pkg =>'/Foo'}, "pkg not found";
    deps_met   {func=>'/Perinci/Examples/gen_array'}, "func";
    deps_unmet {func=>'/Perinci/Examples/'}, "not func";
    deps_unmet {func=>'/Perinci/Examples/foo'}, "func not found";
};

DONE_TESTING:
done_testing();
