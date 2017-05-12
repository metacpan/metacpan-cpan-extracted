#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Bash qw(parse_cmdline join_wordbreak_words);
use Complete::Getopt::Long;
use Monkey::Patch::Action qw(patch_package);
use Perinci::Examples qw();
use Perinci::Sub::Complete qw(complete_cli_arg);
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Test::More 0.98;

my $meta0 = normalize_function_metadata({
    v => 1.1,
    args => {
        arg1 => {schema=>"str"},
    },
});

my $meta = normalize_function_metadata(
    $Perinci::Examples::SPEC{test_completion});

# note that the way arg name and aliases are translated to option name (e.g.
# 'body_len.max' -> 'body-len-max', 'help' -> 'help-arg') should be tested in
# Perinci::Sub::Args::Argv.

test_complete(
    name        => 'arg name (no dash)',
    args        => {meta=>$meta0},
    comp_line0  => 'CMD ^',
    result      => [qw(--arg1 --help -? -h)],
);
test_complete(
    name        => 'arg name 2 (dash)',
    args        => {meta=>$meta},
    comp_line0  => 'CMD -^',
    result      => {words=>
                        [qw(--a1 --a2 --a3 --arg0 --f0 --f1 --h1 --h2 --help
                            --i0 --i1 --i2 --s1 --s1b --s2 --s3 -? -h)],
                    esc_mode=>'option'},
);
test_complete(
    name        => 'arg name 3 (sole completion)',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --a1^',
    result      => {words=>
                        [qw(--a1)],
                    esc_mode=>'option'},
);
test_complete(
    name        => 'arg name 3 (unknown option)',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --foo^',
    result      => {words=>
                        [qw()],
                    esc_mode=>'option'},
);

test_complete(
    name        => 'arg value (schema)',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --s1 ^',
    result      => {words=>['apple','apricot','banana','grape','grapefruit','green grape','red date','red grape'], static=>1},
);
test_complete(
    name        => 'arg value (schema) #2',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --s1 ap^',
    result      => {words=>[qw(apple apricot)], static=>0}, # static is 0 here because word is not zero-length
);
test_complete(
    name        => 'arg value (spec "completion")',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --s2 a^',
    result      => {words=>["aa".."az"], static=>0},
);
test_complete(
    name        => 'arg value, pos',
    args        => {meta=>$meta},
    comp_line0  => 'CMD ^',
    result      => {static=>1, words=>[sort(
        qw(--a1 --a2 --a3 --arg0 --f0 --f1 --h1 --h2 --help --i0 --i1
           --i2 --s1 --s1b --s2 --s3 -? -h),
        1..99)]},
);
test_complete(
    name        => 'arg value, pos + greedy',
    args        => {meta=>$meta},
    comp_line0  => 'CMD 2 ^',
    result      => {static=>1, words=>[
        qw(--a1 --a2 --a3 --arg0 --f0 --f1 --h1 --h2 --help --i0 --i1
           --i2 --s1 --s1b --s2 --s3 -? -h),
        'apple', 'apricot', 'banana', 'grape', 'grapefruit', 'green grape',
        'red date', 'red grape']},
);

test_complete(
    name        => 'arg value, hash, keys from schema',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --h1 ^',
    result      => {static=>0, path_sep=>"=", esc_mode=>"none", words=>[qw/k1= k2= k3= k4=/]},
);
test_complete(
    name        => 'arg value, hash, keys from schema, specified keys wont be mentioned again',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --h1 k1=v1 --h1 ^',
    result      => {static=>0, path_sep=>"=", esc_mode=>"none", words=>[qw/k2= k3= k4=/]},
);
test_complete(
    name        => 'arg value, hash, keys from index_completion property',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --h2 ^',
    result      => {static=>1, path_sep=>"=", esc_mode=>"none", words=>[qw/k1= k2= k3= k4= k5= k6=/]},
);
test_complete(
    name        => 'arg value, hash, values from element_completion property',
    args        => {meta=>$meta},
    comp_line0  => 'CMD --h1 k1=^',
    result      => {static=>0, words=>[qw/k1=ak1 k1=bk1 k1=ck1 k1=dk1 k1=ek1/]},
);

test_complete(
    name        => 'custom completion (option value for function arg)',
    args        => {meta=>$meta0, completion=>sub{["a"]}},
    comp_line0  => 'CMD --arg1 ^',
    result      => [qw/a/],
);
test_complete(
    name        => 'custom completion (option value for common option)',
    args        => {meta=>$meta0, common_opts=>{c1=>{getopt=>'c1=s'}},
                    completion=>sub{["a"]}},
    comp_line0  => 'CMD --c1 ^',
    result      => [qw/a/],
);
test_complete(
    name        => 'custom completion (option value, unknown option)',
    args        => {meta=>$meta0, completion=>sub{["a"]}},
    comp_line0  => 'CMD --foo ^',
    result      => [qw/--arg1 --help -? -h a/],
);
test_complete(
    name        => 'custom completion (positional cli arg with no matching function arg)',
    args        => {meta=>$meta0, completion=>sub{["a"]}},
    comp_line0  => 'CMD ^',
    result      => [qw/--arg1 --help -? -h a/],
);
test_complete(
    name        => 'custom completion (positional cli arg for non-greedy arg)',
    args        => {meta=>$meta, completion=>sub{["a"]}},
    comp_line0  => 'CMD x^',
    result      => [qw/a/],
);
test_complete(
    name        => 'custom completion (positional cli arg for greedy arg)',
    args        => {meta=>$meta, completion=>sub{["a"]}},
    comp_line0  => 'CMD x y^',
    result      => [qw/a/],
);

subtest "args passed to completion routine" => sub {
    {
        local $meta->{args}{i1}{completion} = sub {
            my %args = @_;
            is($args{foo}, 10);
            is_deeply($args{args}{i2}, 20);
            [];
        };
        test_complete(
            name        => 'in arg completion property',
            args        => {
                meta => $meta,
                extras => {foo=>10},
            },
            comp_line0  => 'CMD --i2 20 --i1 ^',
            result      => {static=>0, words=>[]},
        );
    }
    {
        local $meta->{args}{a1}{element_completion} = sub {
            my %args = @_;
            is($args{foo}, 10);
            [];
        };
        test_complete(
            name        => 'in arg element_completion property',
            args        => {
                meta => $meta,
                extras => {foo=>10},
            },
            comp_line0  => 'CMD --a1 ^',
            result      => {static=>0, words=>[]},
        );
    }
    test_complete(
        name        => 'in custom completion',
        args        => {
            meta => $meta,
            completion => sub {
                my %args = @_;
                is($args{foo}, 10);
                [];
            },
            extras => {foo=>10},
        },
        comp_line0  => 'CMD x y^',
        result => [],
    );
};

DONE_TESTING:
done_testing;

sub test_complete {
    my (%args) = @_;

    subtest +($args{name} // $args{comp_line0}) => sub {

        # we don't want compgl's default completion completing
        # files/users/env/etc.
        my $handle = patch_package(
            'Complete::Getopt::Long', '_default_completion', 'replace', sub{[]},
        );

        # $args{comp_line0} contains comp_line with '^' indicating where
        # comp_point should be, the caret will be stripped. this is more
        # convenient than counting comp_point manually.
        my $comp_line  = $args{comp_line0};
        defined ($comp_line) or die "BUG: comp_line0 not defined";
        my $comp_point = index($comp_line, '^');
        $comp_point >= 0 or
            die "BUG: comp_line0 should contain ^ to indicate where comp_point is";
        $comp_line =~ s/\^//;

        my ($words, $cword) = @{ parse_cmdline($comp_line, $comp_point, {truncate_current_word=>1}) };
        ($words, $cword) = @{ join_wordbreak_words($words, $cword) };
        shift @$words; $cword--; # strip program name

        my $copts = {help => {getopt=>'help|h|?', handler=>sub{}}};

        my $res = complete_cli_arg(
            words=>$words, cword=>$cword, common_opts=>$copts,
            %{$args{args}});
        is_deeply($res, $args{result}, "result") or diag explain($res);

        done_testing();
    };
}
