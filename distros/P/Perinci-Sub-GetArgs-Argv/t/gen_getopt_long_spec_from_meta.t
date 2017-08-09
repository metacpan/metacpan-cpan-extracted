#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Clean::JSON;
use Perinci::Sub::GetArgs::Argv qw(
                                      gen_getopt_long_spec_from_meta
                              );
use Test::More 0.98;

my $meta = {
    v => 1.1,
    args => {
        str_arg1   => {schema=>'str'},
        'ary.arg1' => {schema=>[array => of => 'str']},
        float1     => {schema=>'float', cmdline_aliases=>{f=>{}}},
        int1       => {schema=>'int', cmdline_aliases=>{set_zero=>{schema=>'bool', code=>sub{}}}},
        bool1      => {schema=>'bool'},
        help       => {schema=>['bool', is=>1]},
        hash1      => {schema=>'hash', meta=>{v=>1.1, args=>{a=>{schema=>'str'}}}},
        ary1       => {schema=>'array', element_meta=>{v=>1.1, args=>{a=>{schema=>'str'}}}},
        with_foo   => {schema=>'bool'}, # demo negation form with-foo -> without-foo
        buf1       => {schema=>'buf'},

        # demo conversion of plural -> singular option name
        strings    => {schema=>['array', of=>'str'], 'x.name.is_plural'=> 1},
        some_data  => {schema=>['hash' , of=>'str'], 'x.name.is_plural'=> 1, 'x.name.singular'=>'a_datum'},

        # demo option being treated as simple when coercible from simple type.
        # in this case, the option does not become --incl-mouse=s@ but still the
        # single --incl-mice=s
        incl_mice  => {schema=>['array', of=>'str', 'x.perl.coerce_rules'=>['str_comma_sep']], 'x.name.is_plural'=> 1, 'x.name.singular'=>'incl_mouse'},
    },
};

# TODO: test per_arg_json=0
# TODO: test per_arg_yaml=0
# TODO: test conflicts
# TODO: --nonsimple has --nonsimple-json and --nonsimple-yaml
my $res = gen_getopt_long_spec_from_meta(
    meta=>$meta,
    per_arg_json=>1,
    per_arg_yaml=>1,
    common_opts=>{
        help    => {getopt=>'help|h|?' , handler=>sub {}},
        version => {getopt=>'version|v', handler=>sub {}},
        verbose => {getopt=>'verbose!' , handler=>sub {}},
        format  => {getopt=>'format=s' , handler=>sub {}},
        fmtopts => {getopt=>'format-options=s', handler=>sub {}},
    },
);

my $cleanser = Data::Clean::JSON->get_cleanser;
$cleanser->clean_in_place($res);

# strip parsed to keep things short
{
    my $sms = $res->[3]{'func.specmeta'};
    for (keys %$sms) {
        $sms->{$_}{parsed} = 'PARSED' if $sms->{$_}{parsed};
    }
}

# due to random hash ordering, sometimes 'f=s' is processed first (and thus
# 'float1=s' becomes CIRCULAR) and sometimes it's the other way around. so we
# just change 'CIRCULAR' to 'CODE' here.
{
    my $res = $res->[2];
    for (keys %$res) {
        $res->{$_} = 'CODE' if $res->{$_} eq 'CIRCULAR';
    }
}

my $expected_res = [
    200, "OK",
    {
        'help|h|?' => 'CODE',
        'version|v' => 'CODE',
        'verbose!' => 'CODE',
        'format=s' => 'CODE',
        'format-options=s' => 'CODE',

        'str-arg1=s' => 'CODE',
        'ary-arg1=s@' => 'CODE',
        'ary-arg1-json=s' => 'CODE',
        'ary-arg1-yaml=s' => 'CODE',
        'f=s' => 'CODE',
        'float1=s' => 'CODE',
        'int1=s' => 'CODE',
        'bool1' => 'CODE',
        'nobool1' => 'CODE',
        'no-bool1' => 'CODE',
        'set-zero' => 'CODE', # XXX should be 'set-zero'
        'help-arg' => 'CODE',
        'hash1=s' => 'CODE',
        'hash1-json=s' => 'CODE',
        'hash1-yaml=s' => 'CODE',
        'hash1-a=s' => 'CODE',
        'ary1=s' => 'CODE',
        'ary1-json=s' => 'CODE',
        'ary1-yaml=s' => 'CODE',
        'ary1-a=s' => 'CODE',
        'with-foo' => 'CODE',
        'without-foo' => 'CODE',
        'buf1=s' => 'CODE',
        'buf1-base64=s' => 'CODE',

        'string=s@' => 'CODE',
        'strings-json=s' => 'CODE',
        'strings-yaml=s' => 'CODE',
        'a-datum=s%' => 'CODE',
        'some-data-json=s' => 'CODE',
        'some-data-yaml=s' => 'CODE',

        'incl-mice=s' => 'CODE',
    },
    {
        'func.specmeta' => {
            'help|h|?' => {arg=>undef, common_opt=>'help', parsed=>'PARSED',},
            'version|v' => {arg=>undef, common_opt=>'version', parsed=>'PARSED',},
            'verbose!' => {arg=>undef, common_opt=>'verbose', parsed=>'PARSED',},
            'format=s' => {arg=>undef, common_opt=>'format', parsed=>'PARSED',},
            'format-options=s' => {arg=>undef, common_opt=>'fmtopts', parsed=>'PARSED',},
            'str-arg1=s' => {arg=>'str_arg1', fqarg=>'str_arg1', parsed=>'PARSED',},
            'ary-arg1=s@' => {arg=>'ary.arg1', fqarg=>'ary.arg1', parsed=>'PARSED',},
            'ary-arg1-json=s' => {arg=>'ary.arg1', fqarg=>'ary.arg1', is_json=>1, parsed=>'PARSED',},
            'ary-arg1-yaml=s' => {arg=>'ary.arg1', fqarg=>'ary.arg1', is_yaml=>1, parsed=>'PARSED',},
            'float1=s' => {arg=>'float1', fqarg=>'float1', parsed=>'PARSED', noncode_aliases=>['f=s'],},
            'f=s' => {is_alias=>1, alias=>'f', alias_for=>'float1=s', is_code=>0, arg=>'float1', fqarg=>'float1', parsed=>'PARSED',},
            'int1=s' => {arg=>'int1', fqarg=>'int1', parsed=>'PARSED', code_aliases=>['set-zero'],},
            'set-zero' => {is_alias=>1, alias=>'set_zero', alias_for=>'int1=s', is_code=>1, arg=>'int1', fqarg=>'int1', parsed=>'PARSED',},
            'bool1' => {arg=>'bool1', fqarg=>'bool1', parsed=>'PARSED', is_neg=>0, neg_opts=>['no-bool1','nobool1']},
            'nobool1' => {arg=>'bool1', fqarg=>'bool1', parsed=>'PARSED', is_neg=>1, pos_opts=>['bool1']},
            'no-bool1' => {arg=>'bool1', fqarg=>'bool1', parsed=>'PARSED', is_neg=>1, pos_opts=>['bool1']},
            'help-arg' => {arg=>'help', fqarg=>'help', parsed=>'PARSED',},
            'hash1=s' => {arg=>'hash1', fqarg=>'hash1', parsed=>'PARSED',},
            'hash1-json=s' => {arg=>'hash1', fqarg=>'hash1', is_json=>1, parsed=>'PARSED',},
            'hash1-yaml=s' => {arg=>'hash1', fqarg=>'hash1', is_yaml=>1, parsed=>'PARSED',},
            'hash1-a=s' => {arg=>'a', fqarg=>'hash1::a', parsed=>'PARSED',},
            'ary1=s' => {arg=>'ary1', fqarg=>'ary1', parsed=>'PARSED',},
            'ary1-json=s' => {arg=>'ary1', fqarg=>'ary1', is_json=>1, parsed=>'PARSED',},
            'ary1-yaml=s' => {arg=>'ary1', fqarg=>'ary1', is_yaml=>1, parsed=>'PARSED',},
            'ary1-a=s' => {arg=>'a', fqarg=>'ary1::a', parsed=>'PARSED',},
            'with-foo' => {arg=>'with_foo', fqarg=>'with_foo', parsed=>'PARSED', is_neg=>0, neg_opts=>['without-foo']},
            'without-foo' => {arg=>'with_foo', fqarg=>'with_foo', parsed=>'PARSED', is_neg=>1, pos_opts=>['with-foo']},
            'buf1=s' => {arg=>'buf1', fqarg=>'buf1', parsed=>'PARSED'},
            'buf1-base64=s' => {arg=>'buf1', fqarg=>'buf1', parsed=>'PARSED', is_base64=>1},

            'string=s@' => {arg=>'strings', fqarg=>'strings', parsed=>'PARSED'},
            'strings-json=s' => {arg=>'strings', fqarg=>'strings', parsed=>'PARSED', is_json=>1},
            'strings-yaml=s' => {arg=>'strings', fqarg=>'strings', parsed=>'PARSED', is_yaml=>1},
            'a-datum=s%' => {arg=>'some_data', fqarg=>'some_data', parsed=>'PARSED'},
            'some-data-json=s' => {arg=>'some_data', fqarg=>'some_data', parsed=>'PARSED', is_json=>1},
            'some-data-yaml=s' => {arg=>'some_data', fqarg=>'some_data', parsed=>'PARSED', is_yaml=>1},

            'incl-mice=s' => {arg=>'incl_mice', fqarg=>'incl_mice', parsed=>'PARSED'},
        },
        'func.opts' => [
            '--a-datum',
            '--ary-arg1',
            '--ary-arg1-json',
            '--ary-arg1-yaml',
            '--ary1',
            '--ary1-a',
            '--ary1-json',
            '--ary1-yaml',
            '--bool1',
            '--buf1',
            '--buf1-base64',
            '--float1',
            '--format',
            '--format-options',
            '--hash1',
            '--hash1-a',
            '--hash1-json',
            '--hash1-yaml',
            '--help',
            '--help-arg',
            '--incl-mice',
            '--int1',
            '--no-bool1',
            '--no-verbose',
            '--nobool1',
            '--noverbose',
            '--set-zero',
            '--some-data-json',
            '--some-data-yaml',
            '--str-arg1',
            '--string',
            '--strings-json',
            '--strings-yaml',
            '--verbose',
            '--version',
            '--with-foo',
            '--without-foo',
            '-?',
            '-f',
            '-h',
            '-v',
        ],
        'func.common_opts' => [
            '--format',
            '--format-options',
            '--help',
            '--no-verbose',
            '--noverbose',
            '--verbose',
            '--version',
            '-?',
            '-h',
            '-v',
        ],
        'func.func_opts' => [
            '--a-datum',
            '--ary-arg1',
            '--ary-arg1-json',
            '--ary-arg1-yaml',
            '--ary1',
            '--ary1-a',
            '--ary1-json',
            '--ary1-yaml',
            '--bool1',
            '--buf1',
            '--buf1-base64',
            '--float1',
            '--hash1',
            '--hash1-a',
            '--hash1-json',
            '--hash1-yaml',
            '--help-arg',
            '--incl-mice',
            '--int1',
            '--no-bool1',
            '--nobool1',
            '--set-zero',
            '--some-data-json',
            '--some-data-yaml',
            '--str-arg1',
            '--string',
            '--strings-json',
            '--strings-yaml',
            '--with-foo',
            '--without-foo',
            '-f',
        ],
        'func.opts_by_arg' => {
            'ary.arg1' => [
                '--ary-arg1',
                '--ary-arg1-json',
                '--ary-arg1-yaml',
            ],
            'bool1' => [
                '--bool1',
                '--no-bool1',
                '--nobool1',
            ],
            'float1' => [
                '--float1',
                '-f',
            ],
            'help' => [
                '--help-arg',
            ],
            'int1' => [
                '--int1',
                '--set-zero',
            ],
            'str_arg1' => [
                '--str-arg1',
            ],
            'hash1' => [
                '--hash1',
                '--hash1-json',
                '--hash1-yaml',
            ],
            'hash1::a' => [
                '--hash1-a',
            ],
            'ary1' => [
                '--ary1',
                '--ary1-json',
                '--ary1-yaml',
            ],
            'ary1::a' => [
                '--ary1-a',
            ],
            'with_foo' => [
                '--with-foo',
                '--without-foo',
            ],
            'buf1' => [
                '--buf1',
                '--buf1-base64',
            ],

            'strings' => [
                '--string',
                '--strings-json',
                '--strings-yaml',
            ],
            'some_data' => [
                '--a-datum',
                '--some-data-json',
                '--some-data-yaml',
            ],
            'incl_mice' => [
                '--incl-mice',
            ],
        },
        'func.opts_by_common' => {
            'format-options=s' => [
                '--format-options',
            ],
            'format=s' => [
                '--format',
            ],
            'help|h|?' => [
                '--help',
                '-?',
                '-h',
            ],
            'verbose!' => [
                '--no-verbose',
                '--noverbose',
                '--verbose',
            ],
            'version|v' => [
                '--version',
                '-v',
            ]
        },
    },
];

is_deeply($res, $expected_res)
    or diag explain $res;

DONE_TESTING:
done_testing;
