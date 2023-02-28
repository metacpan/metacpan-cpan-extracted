#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Test::More 0.98;

use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Sub::GetArgs::Argv qw(
                                      get_args_from_argv
                              );

my $meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>'str', req=>1, pos=>0},
        arg2 => {schema=>['str'=>{}], req=>1, pos=>1},
        arg3 => {schema=>'str'},
        arg4 => {schema=>'array'},
        arg5 => {schema=>'hash'},
    },
};

test_getargs(meta=>$meta, argv=>[qw/--arg1 1 --arg2 2/],
           args=>{arg1=>1, arg2=>2},
           name=>"optional missing = ok");
test_getargs(meta=>$meta, argv=>[qw/--arg1 1 --arg2 2 --arg3 3/],
           args=>{arg1=>1, arg2=>2, arg3=>3},
           name=>"optional given = ok");
test_getargs(meta=>$meta, argv=>[qw/1 2/],
             args=>{arg1=>1, arg2=>2},
             remaining_argv=>[],
             name=>"arg_pos");
test_getargs(meta=>$meta, argv=>[qw/1 2 --arg3 3/],
             args=>{arg1=>1, arg2=>2, arg3=>3},
             remaining_argv=>[],
             name=>"mixed arg_pos with opts (1)");
test_getargs(meta=>$meta, argv=>[qw/1 --arg2 2/],
             args=>{arg1=>1, arg2=>2},
             remaining_argv=>[],
             name=>"mixed arg_pos with opts (2)");
test_getargs(meta=>$meta, argv=>[qw/--arg1 1 2/], error=>1,
           name=>"mixed arg_pos with opts (clash)");
test_getargs(meta=>$meta, argv=>[qw/--arg1 1 --arg2 2 3/], error=>1,
           name=>"extra args given = fails (1)");
test_getargs(meta=>$meta, argv=>[qw/1 2 3/], error=>1,
           name=>"extra args given = fails (2)");

test_getargs(meta=>$meta, argv=>[qw/--foo bar/], error=>1,
           name=>"unknown args given = fails");

test_getargs(meta=>$meta, argv=>['--arg1', '{"foo":0}',
                               '--arg2', '',
                               '--arg5', '{"foo":0}'],
           args=>{arg1=>'{"foo":0}', arg2=>'', arg5=>'{"foo":0}'},
           name=>"json parsing now not done");

subtest yaml => sub {
    plan skip_all => 'YAML modules not available'
        unless ((eval { require YAML::XS; 1 }) || (eval { require YAML::Old; 1 }));

    test_getargs(meta=>$meta, argv=>['--arg1', '{foo: 0}',
                                     '--arg2', '',
                                     '--arg5', '{foo: 0}'],
                 args=>{arg1=>'{foo: 0}', arg2=>'', arg5=>'{foo: 0}'},
                 name=>"yaml parsing now not done");
};

subtest "nonscalar argv" => sub {
    plan skip_all => 'YAML modules not available'
        unless ((eval { require YAML::XS; 1 }) || (eval { require YAML::Old; 1 }));

    my $meta = {
        v => 1.1,
        args => {
            arg1 => {schema=>'hash', req=>1, pos=>0},
        },
    };
    test_getargs(meta=>$meta, argv=>['[foo]'],
                 per_arg_json=>1, per_arg_yaml=>1,
                 args=>{arg1=>['foo']},
                 name=>"nonscalar argv, yaml/json parsing");

    $meta = {
        v => 1.1,
        args => {
            arg1 => {schema=>'array', req=>1, pos=>0, slurpy=>1},
        },
    };
    test_getargs(meta=>$meta, argv=>['[foo]'],
                 per_arg_json=>1, per_arg_yaml=>1,
                 args=>{arg1=>[['foo']]},
                 name=>"nonscalar argv, yaml/json parsing, slurpy");
};

{
    my $extra  = 0;
    my $extra2 = 0;
    test_getargs(meta=>$meta, argv=>[qw/--arg1 1 --arg2 2 --extra --extra2 6/],
                 common_opts=>{extra=>{getopt=>'extra', handler=>sub{$extra=5}},
                               extra2=>{getopt=>"extra2=s", handler=>sub{$extra2=$_[1]}}},
                 args=>{arg1=>1, arg2=>2},
                 posttest=>sub {
                     is($extra , 5, "extra is parsed");
                     is($extra2, 6, "extra2 is parsed");
                 },
                 name=>"opt: common_opts",
             );
    $extra = 0;
    test_getargs(meta=>$meta, argv=>[qw/ --arg1 1 --arg2 2 --arg1-arg 3 --arg2-arg 4/],
                 common_opts=>{arg1=>{getopt=>"arg1=s", handler=>sub{$extra=$_[1]}},
                               arg2=>{getopt=>"--arg2=s", handler=>sub{$extra2=$_[1]}}},
                 args=>{arg1=>3, arg2=>4},
                 posttest=>sub {
                     is($extra , 1, "arg1 is processed");
                     is($extra2, 2, "arg2 is processed");
                 },
                 name=>"opt: common_opts (clash with arg)",
             );
}

$meta = {
    v=>1.1,
    args=>{arg1=>{schema=>'str*'}},
};

test_getargs(meta=>$meta,
             argv=>[qw/--arg1 1 --arg2 2/],
             strict=>1, # the default
             error=>1,
             name=>"opt: strict=1",
         );
test_getargs(meta=>$meta,
             argv=>[qw/--arg1 1 --arg2 2/],
             strict=>0,
             args=>{arg1=>1},
             name=>"opt: strict=0",
       );

$meta = {
    v=>1.1,
    args=>{arg1=>{schema=>'str*', req=>1, pos=>0}},
};

test_getargs(meta=>$meta,
             argv=>[qw//],
             args=>{},
             name=>"missing required args",
             posttest => sub {
                 my $res = shift;
                 is_deeply($res->[3]{'func.missing_args'}, ['arg1']);
             },
         );

$meta = {
    v => 1.1,
    args => {
        foo_bar_baz => {schema=>'int'},
    },
};
test_getargs(name=>"underscore becomes dash (1)",
             meta=>$meta, argv=>[qw/--foo_bar_baz 2/],
             error=>1,
       );
test_getargs(name=>"underscore becomes dash (2)",
             meta=>$meta, argv=>[qw/--foo-bar_baz 2/],
             error=>1,
         );
test_getargs(name=>"underscore becomes dash (3)",
             meta=>$meta, argv=>[qw/--foo-bar-baz 2/],
             args=>{foo_bar_baz=>2},
       );

$meta = {
    v => 1.1,
    args => {
        foo => {schema=>'hash'},
    },
};
subtest "per_arg_yaml" => sub {
    plan skip_all => 'YAML modules not available'
        unless ((eval { require YAML::XS; 1 }) || (eval { require YAML::Old; 1 }));

    test_getargs(meta=>$meta, argv=>[qw/--foo-yaml ~/],
                 error=>1,
                 name=>"per_arg_yaml=0");
    test_getargs(meta=>$meta, argv=>[qw/--foo-yaml ~/], per_arg_yaml=>1,
                 args=>{foo=>undef},
                 name=>"per_arg_yaml=1");
};

test_getargs(meta=>$meta, argv=>[qw/--foo-json null/],
             error=>1,
             name=>"per_arg_json=0");
test_getargs(meta=>$meta, argv=>[qw/--foo-json null/], per_arg_json=>1,
             args=>{foo=>undef},
             name=>"per_arg_json=1");

{
    local @ARGV = (qw/--foo 2/);
    test_getargs(meta=>$meta,
                 args=>{foo=>2},
                 name=>"argv defaults to \@ARGV");
}

# test bool, one-letter arg, cmdline_aliases

$meta = {
    v => 1.1,
    args => {
        b => {schema=>'bool'},
        b2 => {schema=>'bool'},
        s => {schema=>'str'},
        s2 => {schema=>'str',
               cmdline_aliases=>{
                   S=>{},
                   S_foo=>{schema=>[bool=>{is=>1}],
                           code=>sub{$_[0]{s2} = 'foo'}},
               }
           },
    },
};
test_getargs(meta=>$meta, argv=>[qw/-b -s blah/],
             args=>{b=>1, s=>"blah"},
             name=>"one-letter args get -X as well as --X");
test_getargs(meta=>$meta, argv=>[qw/--nob2/],
             args=>{b2=>0},
             name=>"bool args with length > 1 get --XXX as well as --noXXX");
test_getargs(meta=>$meta, argv=>[qw/-S blah/],
             args=>{s2=>"blah"},
             name=>"cmdline_aliases: S");
test_getargs(meta=>$meta, argv=>[qw/--S-foo/], # XXX S-foo not yet provided?
             args=>{s2=>"foo"},
             name=>"cmdline_aliases: S_foo");

subtest "cmdline_aliases: bool alias with code does not get --noX" => sub {
    my $meta = {
        v => 1.1,
        args => {
            true => {
                schema=>'bool',
                cmdline_aliases => {
                    false => {
                        code => sub { ${$_[0]}{true} = 0 },
                    },
                },
            },
        },
    };
    test_getargs(meta=>$meta, argv=>[qw/--true/]);
    test_getargs(meta=>$meta, argv=>[qw/--notrue/]);
    test_getargs(meta=>$meta, argv=>[qw/--false/]);
    test_getargs(meta=>$meta, argv=>[qw/--nofalse/], error=>1);
};

# test handling of array of scalar, --foo 1 --foo 2

$meta = {
    v => 1.1,
    args => {
        ai => {schema=>[array => {of=>'int'}]},
        as => {schema=>[array => {of=>'str*'}], cmdline_aliases=>{S=>{}}},
    },
};
test_getargs(meta=>$meta, argv=>[qw/--ai 1/],
             args=>{ai=>[1]},
             name=>"array of scalar (int, 1)");
test_getargs(meta=>$meta, argv=>[qw/--ai 1 --ai 1/],
             args=>{ai=>[1, 1]},
             name=>"array of scalar (int, 2)");
test_getargs(meta=>$meta, argv=>[qw/--as x/],
             args=>{as=>['x']},
             name=>"array of scalar (str, 1)");
test_getargs(meta=>$meta, argv=>['--as', '[x]', '--as', '', '--as', '"y"'],
             args=>{as=>['[x]', '', '"y"']},
             name=>"array of scalar (str, 2)");
test_getargs(meta=>$meta, argv=>[qw/-S x/],
             args=>{as=>['x']},
             name=>"array of scalar (str, one-letter alias, 1)");
test_getargs(meta=>$meta, argv=>['-S', '[x]', '-S', '', '-S', '"y"'],
             args=>{as=>['[x]', '', '"y"']},
             name=>"array of scalar (str, one-letter alias, 2)");
#test_getargs(meta=>$meta, argv=>['--ai', '1,2,3'],
#             args=>{ai=>[1,2,3]},
#             name=>"array of scalar (int, comma-separated)");

subtest "hash of scalar (--foo k1=v1 --foo k2=v2)" => sub {
    my $meta = {
        v => 1.1,
        args => {
            hi => {schema=>[hash => {of=>'int'} ]},
            hs => {schema=>[hash => {of=>'str*'}], cmdline_aliases=>{S=>{}}},
        },
    };
    test_getargs(meta=>$meta, argv=>[qw/--hs 1/],
                 status=>500,
                 name=>"invalid pair syntax");
    test_getargs(meta=>$meta, argv=>[qw/--hi k1=1/],
                 args=>{hi=>{k1=>1}},
                 name=>"int, 1");
    test_getargs(meta=>$meta, argv=>[qw/--hi k1=1 --hi k2=2/],
                 args=>{hi=>{k1=>1, k2=>2}},
                 name=>"int, 2");
    test_getargs(meta=>$meta, argv=>[qw/--hs k1=x/],
                 args=>{hs=>{k1=>"x"}},
                 name=>"str, 1");
    test_getargs(meta=>$meta, argv=>[qw/--hs k1=x --hs k2=y/],
                 args=>{hs=>{k1=>"x", k2=>"y"}},
                 name=>"str, 2");
    test_getargs(meta=>$meta, argv=>[qw/-S k1=x/],
                 args=>{hs=>{k1=>"x"}},
                 name=>"str, one-letter alias, 1");
};

# test dot

$meta = {
    v => 1.1,
    args => {
        "foo.bar" => {schema=>'int'},
    },
};
test_getargs(meta=>$meta, argv=>[qw/--foo-bar 2/],
             args=>{'foo.bar' => 2},
             name=>"with.dot accepted via --with-dot");

# test option: allow_extra_elems

my $argv = ['a'];
$meta = {
    v => 1.1,
    args => {
        a => {schema=>'str*'},
    },
};
test_getargs(meta=>$meta, argv=>$argv,
             error=>1,
             name=>"allow_extra_elems=>0");
test_getargs(meta=>$meta, argv=>$argv,
             allow_extra_elems => 1,
             args=>{},
             posttest=>sub{
                 is_deeply($argv,['a'],'argv');
             },
             name=>"allow_extra_elems=>1");

# test option: on_missing_required_args

$meta = {
    v => 1.1,
    args => {
        a => {schema=>'str*', req=>1},
        b => {schema=>'str*'},
    },
};
test_getargs(meta=>$meta, argv=>[qw//],
             args=>{},
             posttest=>sub {
                 my $res = shift;
                 is_deeply($res->[3]{'func.missing_args'}, ['a']);
             },
             name=>"without on_missing_required_args hook",
         );
test_getargs(meta=>$meta, argv=>[qw//],
             args=>{},
             on_missing_required_args => sub {1},
             posttest=>sub {
                 my $res = shift;
                 is_deeply($res->[3]{'func.missing_args'}, []);
             },
             name=>"returning 1 from on_missing_required_args hook",
         );

test_getargs(meta=>$meta, argv=>[qw//],
             args=>{a=>'v1'},
             on_missing_required_args => sub {
                 my %args = @_;
                 my $arg  = $args{arg};
                 my $args = $args{args};
                 my $spec = $args{spec};

                 if ($arg eq 'a') {
                     $args->{$arg} = 'v1';
                 } else {
                     $args->{$arg} = 'v2';
                 }
                 0;
             },
             name=>"arg values set by on_missing_required_args hook");

# since 0.21+, we enable Go::L configuration: bundling

$meta = {
    v => 1.1,
    args => {
        arg => {schema=>'str', cmdline_aliases=>{X=>{}}},
    },
};
test_getargs(meta=>$meta, argv=>[qw/-X=foo/],
             args=>{arg => '=foo'},
             name=>"Go::L configuration: bundling");

{
    my @arg;
    my @pos;
    my $meta = {
        v => 1.1,
        args => {
            arg => {
                schema => ['array*' => of => 'str*'],
                cmdline_aliases   => { A => {} },
                cmdline_on_getopt => sub {
                    push @arg, {@_};
                },
            },
            foo => { schema => 'bool' },
            pos => {
                schema => ['array*' => of => 'str*'],
                pos    => 0,
                slurpy => 1,
                cmdline_on_getopt => sub {
                    push @pos, {@_};
                },
            },
        },
    };
    test_getargs(
        name => 'cmdline_on_getopt (basics)',
        meta => $meta,
        argv => [qw/--arg 1 --foo -A 2/],
        posttest => sub {
            my $res = shift;
            is_deeply(\@arg, [
                {arg=>'arg', fqarg=>'arg', args=>$res->[2], opt=>'arg', value=>1},
                {arg=>'arg', fqarg=>'arg', args=>$res->[2], opt=>'arg', value=>2},
            ]) or diag explain \@arg;
        },
    );
    @pos = ();
    test_getargs(
        name => 'cmdline_on_getopt for arg with pos, feed opts',
        meta => $meta,
        argv => [qw/--pos 1/],
        posttest => sub {
            my $res = shift;
            is_deeply(\@pos, [
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>'pos', value=>1},
            ]) or diag explain \@pos;
        },
    );
    @pos = ();
    test_getargs(
        name => 'cmdline_on_getopt for arg with pos, feed arg',
        meta => $meta,
        argv => [qw/1/],
        posttest => sub {
            my $res = shift;
            is_deeply(\@pos, [
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>undef, value=>1},
            ]) or diag explain \@pos;
        },
    );

    # from now on, pos becomes slurpy
    $meta->{args}{pos}{slurpy} = 1;

    @pos = ();
    test_getargs(
        name => 'cmdline_on_getopt for arg with pos + slurpy, feed opts',
        meta => $meta,
        argv => [qw/--pos 1 --pos 2/],
        posttest => sub {
            my $res = shift;
            is_deeply(\@pos, [
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>'pos', value=>1},
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>'pos', value=>2},
            ]) or diag explain \@pos;
        },
    );
    @pos = ();
    test_getargs(
        name => 'cmdline_on_getopt for arg with pos + slurpy, feed args',
        meta => $meta,
        argv => [qw/1 2/],
        posttest => sub {
            my $res = shift;
            is_deeply(\@pos, [
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>undef, value=>1},
                {arg=>'pos', fqarg=>'pos', args=>$res->[2], opt=>undef, value=>2},
            ]) or diag explain \@pos;
        },
    );
}

{
    my $meta = {
        v => 1.1,
        args => {
            arg1 => {
                schema => 'str',
                cmdline_aliases => {
                    al1 => {
                        code => 'CODE',
                    },
                },
            },
        },
    };
    test_getargs(
        name   => 'error 501 (1)',
        meta   => $meta,
        argv   => [qw/--arg1 val/],
        status => 501,
    );
    test_getargs(
        name   => 'error 501 (2)',
        meta   => $meta,
        argv   => [qw/--al1 val/],
        status => 501,
    );
    test_getargs(
        name   => 'option: ignore_converted_code',
        meta   => $meta,
        ignore_converted_code => 1,
        argv   => [qw/--al1 val/],
        status => 200,
    );
}

subtest 'args option' => sub {
    my $meta = {
        v => 1.1,
        args => {
            a => {schema => 'str*', req=>1},
            b => {schema => 'str*'},
        },
    };

    test_getargs(
        meta       => $meta,
        argv       => [qw//],
        args       => {},
        name       => 'no preset args -> missing',
        posttest   => sub {
            my $res = shift;
            is_deeply($res->[3]{'func.missing_args'}, ['a']);
        },
    );
    test_getargs(
        meta       => $meta,
        argv       => [qw//],
        input_args => {a=>1},
        args       => {a=>1},
        name       => 'arg a is preset -> ok',
        posttest   => sub {
            my $res = shift;
            is_deeply($res->[3]{'func.missing_args'}, []);
        },
    );
    test_getargs(
        meta       => $meta,
        argv       => [qw//],
        input_args => {a=>1, b=>2, d=>4},
        args       => {a=>1, b=>2, d=>4},
        name       => 'unknown arg in input args is ok',
    );
    test_getargs(
        meta       => $meta,
        argv       => [qw/-a 10/],
        input_args => {a=>1, b=>2, d=>4},
        args       => {a=>10, b=>2, d=>4},
        name       => 'argv overrides input args',
    );
};

subtest 'arg submetadata' => sub {
    my $meta = {
        v => 1.1,
        args => {
            a => {schema => 'str*', req=>1},
            b => {schema => 'str*'},
            c => {
                schema => 'hash*',
                meta => {
                    v => 1.1,
                    args => {
                        a => {schema => 'str*'},
                        b => {schema => 'str*'},
                    },
                },
            },
        },
    };

    test_getargs(
        meta       => $meta,
        argv       => [qw/--a 1 --b 2 --c-a 3 --c-b 4/],
        args       => {a=>1, b=>2, c=>{a=>3, b=>4}},
    );
};

subtest 'arg element submetadata' => sub {
    my $meta = {
        v => 1.1,
        args => {
            a => {schema => 'str*', req=>1},
            b => {schema => 'str*'},
            c => {
                schema => 'array*',
                element_meta => {
                    v => 1.1,
                    args => {
                        a => {schema => 'str*'},
                        b => {schema => 'str*'},
                    },
                },
            },
        },
    };

    test_getargs(
        meta       => $meta,
        argv       => [qw/--a 1 --b 2 --c-a 3 --c-b 4/],
        args       => {a=>1, b=>2, c=>[{a=>3, b=>4}]},
    );
    test_getargs(
        meta       => $meta,
        argv       => [qw/--a 1 --b 2 --c-a 3 --c-a 4 --c-b 5/],
        args       => {a=>1, b=>2, c=>[{a=>3, b=>5}, {a=>4}]},
    );
};

subtest 'base64' => sub {
    my $meta = {
        v => 1.1,
        args => {
            data => {schema => 'buf*', req=>1},
        },
    };
    test_getargs(
        meta       => $meta,
        argv       => [qw/--data 123/],
        args       => {data=>"123"},
    );
    test_getargs(
        meta       => $meta,
        argv       => [qw/--data-base64 AAAA/],
        args       => {data=>"\0\0\0"},
    );
};

subtest 'arg spec prop: deps' => sub {
    my $meta = {
        v => 1.1,
        args => {
            a1 => {schema=>'str*'},
            a2 => {schema=>'str*', deps=>{arg=>'a1'}},
        },
    };

    test_getargs(
        name  => "a2 with a1 present -> ok",
        meta  => $meta,
        argv  => ['--a2', 2, '--a1', 1],
    );
    test_getargs(
        name  => "a1 without a2 present -> ok",
        meta  => $meta,
        argv  => ['--a1', 1],
    );
    test_getargs(
        name  => "a2 without a1 present -> error",
        meta  => $meta,
        argv  => ['--a2', 2],
        error => 1,
    );

    # XXX test unknown dep type
    # XXX test unknown arg
    # XXX test circular deps
};

DONE_TESTING:
done_testing;

sub test_getargs {
    my (%args) = @_;

    my $name = $args{name} // "getargs(".join(", ", @{$args{argv}}).")";

    subtest $name => sub {
        my $argv = clone($args{argv});
        my $res;
        my $input_args = { %{ $args{input_args} } } if $args{input_args};
        my %input_args = (argv=>$argv, meta=>$args{meta},
                          args=>$input_args);
        for (qw/strict
                common_opts
                per_arg_json per_arg_yaml
                allow_extra_elems on_missing_required_args
                ignore_converted_code/) {
            $input_args{$_} = $args{$_} if defined $args{$_};
        }
        #diag explain \%input_args;
        $res = get_args_from_argv(%input_args);
        if ($args{status}) {
            is($res->[0], $args{status}, "status")
                or diag explain $res;
            return if $args{status} != 200;
        }
        if ($args{error}) {
            isnt($res->[0], 200, "error (status != 200)");
        } else {
            is($res->[0], 200, "success (status == 200)")
                or diag explain $res;
        }
        if ($args{args}) {
            is_deeply($res->[2], $args{args}, "result")
                or diag explain $res;
        }
        if ($args{remaining_argv}) {
            is_deeply($argv, $args{remaining_argv}, "remaining argv")
                or diag explain $argv;
        }

        if ($args{posttest}) {
            $args{posttest}->($res);
        }

        done_testing();
    };
}
