#!perl

use 5.010001;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Sub::ValidateArgs qw(gen_args_validator);
use Test::Exception;
use Test::More 0.98;

our %SPEC;

$SPEC{foo} = {
    v => 1.1,
    args => {
        a1 => {
            schema => 'int*',
            req => 1,
            pos => 0,
        },
        a2 => {
            schema => [array => of=>'int*'],
            default => [1],
            pos => 1,
            greedy => 1,
        },
    },
};
sub foo {
    state $validator = gen_args_validator();
    my %args = @_;
    if (my $err = $validator->(\%args)) { return $err }
    [200, "OK"];
}

$SPEC{foo_result_naked} = do {
    my $meta = clone $SPEC{foo};
    $meta->{result_naked} = 1;
    $meta;
};
sub foo_result_naked {
    state $validator = gen_args_validator();
    my %args = @_;
    if (my $err = $validator->(\%args)) { return $err }
    "OK";
}

$SPEC{foo_die} = $SPEC{foo};
sub foo_die {
    state $validator = gen_args_validator(die => 1);
    my %args = @_;
    $validator->(\%args);
    [200, "OK"];
}

$SPEC{foo_args_as_hashref} = do {
    my $meta = clone $SPEC{foo};
    $meta->{args_as} = 'hashref';
    $meta;
};
sub foo_args_as_hashref {
    state $validator = gen_args_validator();
    my $args = shift;
    if (my $err = $validator->($args)) { return $err }
    [200, "OK"];
}

$SPEC{foo_args_as_array} = do {
    my $meta = clone $SPEC{foo};
    $meta->{args_as} = 'array';
    $meta;
};
sub foo_args_as_array {
    state $validator = gen_args_validator();
    my @args = @_;
    if (my $err = $validator->(\@args)) { return $err }
    [200, "OK"];
}

$SPEC{foo_args_as_arrayref} = do {
    my $meta = clone $SPEC{foo};
    $meta->{args_as} = 'arrayref';
    $meta;
};
sub foo_args_as_arrayref {
    state $validator = gen_args_validator();
    my $args = shift;
    if (my $err = $validator->($args)) { return $err }
    [200, "OK"];
}

$SPEC{bar} = {
    v => 1.1,
    args => {
        a1 => {
            schema => 'int*',
            req => 1,
            pos => 0,
        },
        a2 => {
            schema => 'int',
            default => 2,
            pos => 1,
        },
    },
    args_as => 'array',
};
sub bar {
    state $validator = gen_args_validator();
    my $args = [@_];
    if (my $err = $validator->($args)) { return $err }
    [200, "OK"];
}

subtest "basics" => sub {
    is_deeply(foo(),
              [400, "Missing required argument 'a1'"]);
    is_deeply(foo(bar=>undef),
              [400, "Unknown argument 'bar'"]);
    is_deeply(foo(a1=>1),
              [200, "OK"]);
    is_deeply(foo(a1=>"x"),
              [400, "Validation failed for argument 'a1': Not of type integer"]);
    is_deeply(foo(a1=>2, a2=>"x"),
              [400, "Validation failed for argument 'a2': Not of type array"]);
    is_deeply(foo(a1=>2, a2=>["x"]),
              [400, "Validation failed for argument 'a2': \@[0]: Not of type integer"]);
    is_deeply(foo(a1=>2, a2=>[]),
              [200, "OK"]);
};

subtest "opt:source=1" => sub {
    my $res = gen_args_validator(meta=>{v=>1.1}, source=>1);
    like($res, qr/sub/);
};

subtest "meta:result_naked=1" => sub {
    is_deeply(foo_result_naked(), "Missing required argument 'a1'");
    is_deeply(foo_result_naked(a1=>2), "OK");
};

subtest "meta:args_as=hashref" => sub {
    is_deeply(foo_args_as_hashref({}), [400, "Missing required argument 'a1'"]);
    is_deeply(foo_args_as_hashref({a1=>2}), [200, "OK"]);
};

subtest "meta:args_as=array" => sub {
    is_deeply(foo_args_as_array(), [400, "Wrong number of arguments (expected 1..2, got 0)"]);
    is_deeply(foo_args_as_array(2), [200, "OK"]);
    is_deeply(foo_args_as_array("x"), [400, "Validation failed for argument 'a1': Not of type integer"]);
    is_deeply(foo_args_as_array(2, 1), [200, "OK"]);
    is_deeply(foo_args_as_array(2, 1,2), [200, "OK"]);
    is_deeply(foo_args_as_array(2, 1,"x"), [400, "Validation failed for argument 'a2': \@[1]: Not of type integer"]);
    is_deeply(bar(1, 2, 3), [400, "Wrong number of arguments (expected 1..2, got 3)"]);
};

subtest "meta:args_as=arrayref" => sub {
    is_deeply(foo_args_as_arrayref([]), [400, "Wrong number of arguments (expected 1..2, got 0)"]);
    is_deeply(foo_args_as_arrayref([2]), [200, "OK"]);
    is_deeply(foo_args_as_arrayref(["x"]), [400, "Validation failed for argument 'a1': Not of type integer"]);
    is_deeply(foo_args_as_arrayref([2, 1]), [200, "OK"]);
    is_deeply(foo_args_as_arrayref([2, 1,2]), [200, "OK"]);
    is_deeply(foo_args_as_arrayref([2, 1,"x"]), [400, "Validation failed for argument 'a2': \@[1]: Not of type integer"]);
};

subtest "opt:die=1" => sub {
    dies_ok  { foo_die() };
    dies_ok  { foo_die(a1=>"x") };
    lives_ok { foo_die(a1=>2) };
};

done_testing;
