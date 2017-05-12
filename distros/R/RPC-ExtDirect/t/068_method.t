# Method argument checking preparation

use strict;
use warnings;

use Test::More tests => 166;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;
use RPC::ExtDirect::API::Method;

my $tests = eval do { local $/; <DATA>; } or die "Can't eval DATA: '$@'";

my @run_only = @ARGV;

my $config = RPC::ExtDirect::Config->new();

TEST:
for my $test ( @$tests ) {
    my $name       = $test->{name};
    my $type       = $test->{type};
    my $method_arg = $test->{method};
    my $input      = $test->{input};
    my $out_type   = $test->{out_type} || 'array';
    my $out_ctx    = $test->{out_context} || { list => 1, scalar => 1 },
    my $output     = $test->{output};
    my $exception  = $test->{exception};
    my $warning    = $test->{warning};
    
    next TEST if @run_only && !grep { lc $name eq lc $_ } @run_only;
    
    my $have_warning;
    
    my $method = eval {
        local $SIG{__WARN__} = sub { $have_warning = shift };
        
        RPC::ExtDirect::API::Method->new(
            config => $config,
            %$method_arg,
        );
    };
    
    if ( $@ ) {
        if ( $exception ) {
            my $xcpt = 'ARRAY' eq ref $@ ? $@->[0] : $@;
            
            like $xcpt, $exception, "$name: new exception";
        }
        else {
            fail "$name: uncaught new exception: $@";
        }
        
        next TEST;
    }
    
    if ( $warning ) {
        like $have_warning, $warning, "$name: new warning";
    }
    
    if ( $type eq 'check' ) {
        my $result = eval { $method->check_method_arguments($input) };
        
        if ( $exception ) {
            my $xcpt = 'ARRAY' eq ref $@ ? $@->[0] : $@;
            
            like $xcpt, $exception, "$name: check exception";
        }
        else {
            is_deep $result, $output, "$name: check result";
        }
    }
    elsif ( $type eq 'prepare' ) {
        if ( $out_ctx->{list} ) {
            if ( $out_type eq 'hash' ) {
                my %have = $method->prepare_method_arguments(%$input);
                
                is_deep \%have, $output, "$name: prepare list output";
            }
            else {
                my @have = $method->prepare_method_arguments(%$input);
                
                is_deep \@have, $output, "$name: prepare list output";
            }
        }
        
        if ( $out_ctx->{scalar} ) {
            my $have = $method->prepare_method_arguments(%$input);
            
            if ( $out_type ) {
                is ref($have), uc $out_type, "$name: prepare ref type";
            }
            
            is_deep $have, $output, "$name: prepare scalar output";
        }
    }
    elsif ( $type eq 'check_meta' ) {
        my $result = eval { $method->check_method_metadata($input) };
        
        if ( $exception ) {
            my $xcpt = 'ARRAY' eq ref $@ ? $@->[0] : $@;
            
            like $xcpt, $exception, "$name: check_meta exception";
        }
        else {
            is_deep $result, $output, "$name: check_meta result";
        }
    }
    elsif ( $type eq 'prepare_meta' ) {
        my $prep_out = $method->prepare_method_metadata(%$input);
        
        is_deep $prep_out, $output, "$name: prepare_meta output";
    }
    else {
        BAIL_OUT "Unknown test type: $type";
    }
}

__DATA__
#line 120
[
    {
        name => 'Ordered passed {}',
        type => 'check',
        method => {
            len => 1,
        },
        input => { foo => 'bar' },
        exception => qr/expects ordered arguments in arrayref/,
    },
    {
        name => 'Ordered zero passed [0]',
        type => 'check',
        method => {
            len => 0,
        },
        input => [],
        output => 1,
    },
    {
        name => 'Ordered zero passed [1]',
        type => 'check',
        method => {
            len => 0,
        },
        input => [42],
        output => 1,
    },
    {
        name => 'Ordered 1 passed [0]',
        type => 'check',
        method => {
            len => 1,
        },
        input => [],
        exception => qr/requires 1 argument\(s\) but only 0 are provided/,
    },
    {
        name => 'Ordered 1 passed [1]',
        type => 'check',
        method => {
            len => 1,
        },
        input => [42],
        output => 1,
    },
    {
        name => 'Ordered 1 passed [2]',
        type => 'check',
        method => {
            len => 1,
        },
        input => [42, 39],
        output => 1,
    },
    {
        name => 'Ordered 3 passed [0]',
        type => 'check',
        method => {
            len => 3,
        },
        input => [],
        exception => qr/requires 3 argument\(s\) but only 0 are provided/,
    },
    {
        name => 'Ordered 3 passed [2]',
        type => 'check',
        method => {
            len => 3,
        },
        input => [111, 222],
        exception => qr/requires 3 argument\(s\) but only 2 are provided/,
    },
    {
        name => 'Ordered 3 passed [3]',
        type => 'check',
        method => {
            len => 3,
        },
        input => [111, 222, 333],
        output => 1,
    },
    {
        name => 'Ordered 3 passed [4]',
        type => 'check',
        method => {
            len => 3,
        },
        input => [111, 222, 333, 444],
        output => 1,
    },
    {
        name => 'Named passed []',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => [],
        exception => qr/expects named arguments in hashref/,
    },
    {
        name => 'Named strict passed empty {}',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => {},
        exception => qr/parameters: 'foo, bar'; these are missing: 'foo, bar'/,
    },
    {
        name => 'Named strict empty params, passed empty {}',
        type => 'check',
        method => {
            params => [],
        },
        input => {},
        output => 1,
    },
    {
        name => 'Named !strict empty params, passed empty {}',
        type => 'check',
        method => {
            params => [],
            strict => !1,
        },
        input => {},
        output => 1,
    },
    {
        name => 'Named strict empty params, passed non-empty {}',
        type => 'check',
        method => {
            params => [],
        },
        input => { foo => 'bar', fred => 'frob', },
        output => 1,
    },
    {
        name => 'Named strict empty params, passed non-empty {}',
        type => 'check',
        method => {
            params => [],
        },
        input => { foo => 'bar', fred => 'frob', },
        output => 1,
    },
    {
        name => 'Named !strict passed empty {}',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => {},
        exception => qr/parameters: 'foo, bar'; these are missing: 'foo, bar'/,
    },
    {
        name => 'Named strict not enough arguments',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => { foo => 'bar', },
        exception => qr/parameters: 'foo, bar'; these are missing: 'bar'/,
    },
    {
        name => 'Named !strict not enough arguments',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => { foo => 'bar', },
        exception => qr/parameters: 'foo, bar'; these are missing: 'bar'/,
    },
    {
        name => 'Named strict not enough required args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => { foo => 'bar', baz => 'blerg', fred => 'frob', },
        exception => qr/parameters: 'foo, bar'; these are missing: 'bar'/,
    },
    {
        name => 'Named !strict not enough required args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => { foo => 'bar', baz => 'blerg', fred => 'frob', },
        exception => qr/parameters: 'foo, bar'; these are missing: 'bar'/,
    },
    {
        name => 'Named strict enough args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => { foo => 'bar', bar => 'baz', },
        output => 1,
    },
    {
        name => 'Named !strict enough args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => { foo => 'bar', bar => 'baz', },
        output => 1,
    },
    {
        name => 'Named strict extra args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
        },
        input => { foo => 'bar', bar => 'baz', fred => 'frob', },
        output => 1,
    },
    {
        name => 'Named !strict extra args',
        type => 'check',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => { foo => 'bar', bar => 'baz', fred => 'frob', },
        output => 1,
    },
    {
        name => 'formHandler passed []',
        type => 'check',
        method => {
            formHandler => 1,
        },
        input => [],
        exception => qr/expects named arguments in hashref/,
    },
    {
        name => 'formHandler passed {}',
        type => 'check',
        method => {
            formHandler => 1,
        },
        input => {},
        output => 1,
    },
    {
        name => 'pollHandler passed []',
        type => 'check',
        method => {
            pollHandler => 1,
        },
        input => [],
        output => 1,
    },
    {
        name => 'pollHandler passed {}',
        type => 'check',
        method => {
            pollHandler => 1,
        },
        input => {},
        output => 1,
    },
    {
        name => 'Ordered zero no env_arg',
        type => 'prepare',
        method => {
            len => 0,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => [],
    },
    {
        name => 'Ordered zero env_arg',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => 0,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => ['env'],
    },
    {
        name => 'Ordered multi 1 no env_arg',
        type => 'prepare',
        method => {
            len => 1,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => [1],
    },
    {
        name => 'Ordered multi 1 env_arg front',
        type => 'prepare',
        method => {
            len => 1,
            env_arg => 0,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => ['env', 1],
    },
    {
        name => 'Ordered multi 1 env_arg back',
        type => 'prepare',
        method => {
            len => 1,
            env_arg => 99,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => [1, 'env'],
    },
    {
        name => 'Ordered multi 2 env_arg middle',
        type => 'prepare',
        method => {
            len => 2,
            env_arg => -1,
        },
        input => {
            env => 'env',
            input => [qw/ 1 2 3 /],
        },
        out_type => 'array',
        output => [1, 'env', 2],
    },
    {
        name => 'Named empty params strict no env',
        type => 'prepare',
        method => {
            params => [],
        },
        input => {
            env => 'env',
            input => { foo => 1, bar => 2, },
        },
        out_type => 'hash',
        output => { foo => 1, bar => 2, },
    },
    {
        name => 'Named empty params !strict no env',
        type => 'prepare',
        method => {
            params => [], strict => !1,
        },
        input => {
            env => 'env',
            input => { foo => 1, bar => 2, },
        },
        out_type => 'hash',
        output => { foo => 1, bar => 2, },
    },
    {
        name => 'Named strict no env',
        type => 'prepare',
        method => {
            params => [qw/ foo bar /],
        },
        input => {
            env => 'env',
            input => { foo => 1, bar => 2, baz => 3 },
        },
        out_type => 'hash',
        output => { foo => 1, bar => 2, },
    },
    {
        name => 'Named lazy no env',
        type => 'prepare',
        method => {
            params => [qw/ foo bar /],
            strict => !1,
        },
        input => {
            env => 'env',
            input => { foo => 1, bar => 2, baz => 3, },
        },
        out_type => 'hash',
        output => { foo => 1, bar => 2, baz => 3, },
    },
    {
        name => 'Named lazy env',
        type => 'prepare',
        method => {
            params => [qw/ foo bar /],
            env_arg => 'env',
            strict => !1,
        },
        input => {
            env => 'env',
            input => { foo => 1, bar => 2, baz => 3, },
        },
        out_type => 'hash',
        output => { foo => 1, bar => 2, baz => 3, env => 'env' },
    },
    {
        name => 'formHandler no uploads no env',
        type => 'prepare',
        method => {
            formHandler => 1,
        },
        input => {
            env => 'env',

            # Test stripping of the standard Ext.Direct fields
            input => {
                action => 'Foo',
                method => 'bar',
                extAction => 'Foo',
                extMethod => 'bar',
                extTID => 1,
                extUpload => 'true',
                _uploads => 'foo',
                foo => 'bar',
            },
        },
        out_type => 'hash',
        output => { foo => 'bar' },
    },
    {
        name => 'formHandler no uploads w/ env',
        type => 'prepare',
        method => {
            formHandler => 1,
            env_arg => '_env',
        },
        input => {
            env => 'env',
            input => { foo => 'bar' },
        },
        out_type => 'hash',
        output => { foo => 'bar', _env => 'env' },
    },
    {
        name => 'formHandler decode_params',
        type => 'prepare',
        method => {
            formHandler => 1,
            decode_params => ['frobbe', 'guzzard'],
        },
        input => {
            input => { frobbe => '{"throbbe":["vita","voom"]}', },
        },
        out_type => 'hash',
        out_context => { list => 1 },
        output => {
            frobbe => { throbbe => ['vita', 'voom'] },
        },
    },
    {
        name => 'formHandler w/def uploads w/ env',
        type => 'prepare',
        method => {
            formHandler => 1,
            env_arg => 'env_',
        },
        input => {
            env => 'env',
            input => { foo => 'bar' },
            upload => [{ baz => 'qux' }],
        },
        out_type => 'hash',
        output => {
            env_ => 'env',
            foo => 'bar',
            file_uploads => [{ baz => 'qux' }],
        },
    },
    {
        name => 'formHandler w/cust uploads w/ env',
        type => 'prepare',
        method => {
            formHandler => 1,
            env_arg => 'env',
            upload_arg => 'files',
        },
        input => {
            env => 'env',
            input => { foo => 'bar', baz => 'bam', },
            upload => [{ baz => 'qux' }],
        },
        out_type => 'hash',
        output => {
            env => 'env',
            foo => 'bar',
            baz => 'bam',
            files => [{ baz => 'qux' }],
        },
    },
    {
        name => 'pollHandler no env',
        type => 'prepare',
        method => {
            pollHandler => 1,
        },
        input => { env => 'env', input => [qw/ foo bar /], },
        out_type => 'array',
        output => [],
    },
    {
        name => 'pollHandler w/ env',
        type => 'prepare',
        method => {
            pollHandler => 1,
            env_arg => 0,
        },
        input => { env => 'env', input => { foo => 'bar' }, },
        out_type => 'array',
        output => ['env'],
    },
    {
        name => 'Ordered meta passed {}',
        type => 'check_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => {},
        exception => qr/expects metadata in arrayref/,
    },
    {
        name => 'Ordered meta passed [0]',
        type => 'check_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => [],
        exception => qr/requires 1 metadata value/,
    },
    {
        name => 'Ordered meta passed [1]',
        type => 'check_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => [42],
        output => 1,
    },
    {
        name => 'Ordered meta passed [2]',
        type => 'check_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => [42, 43],
        output => 1,
    },
    {
        name => 'Named meta passed []',
        type => 'check_meta',
        method => {
            metadata => { params => ['foo'] },
        },
        input => [],
        exception => qr/expects metadata key\/value/,
    },
    {
        name => 'Named meta strict passed {}',
        type => 'check_meta',
        method => {
            metadata => { params => [] },
        },
        input => {},
        output => 1,
    },
    {
        name => 'Named meta default passed []',
        type => 'check_meta',
        method => {
            metadata => {},
        },
        input => [],
        exception => qr/expects metadata key\/value/,
    },
    {
        name => 'Named meta !strict passed {}',
        type => 'check_meta',
        method => {
            metadata => { params => [], },
        },
        input => {},
        output => 1,
        warning => qr/implies strict argument checking/,
    },
    {
        name => 'Named meta default passed {}',
        type => 'check_meta',
        method => {
            metadata => {},
        },
        input => {},
        output => 1,
    },
    {
        name => 'Named meta strict missing params',
        type => 'check_meta',
        method => {
            metadata => { params => ['foo'] },
        },
        input => {},
        exception => qr/requires.*?metadata keys: 'foo'/,
    },
    {
        name => 'Named meta !strict missing params',
        type => 'check_meta',
        method => {
            metadata => { params => ['foo'], strict => !1 },
        },
        input => {},
        exception => qr/requires.*?metadata keys: 'foo'/,
    },
    {
        name => 'Named meta strict enough params',
        type => 'check_meta',
        method => {
            metadata => { params => ['foo'] },
        },
        input => { foo => 'bar' },
        output => 1,
    },
    {
        name => 'Named meta !strict enough params',
        type => 'check_meta',
        method => {
            metadata => { params => ['foo'], strict => !1 },
        },
        input => { foo => 'bar' },
        output => 1,
    },
    {
        name => 'Named meta default passed params',
        type => 'check_meta',
        method => {
            metadata => {},
        },
        input => { foo => 'bar' },
        output => 1,
    },
    {
        name => 'Ordered meta 0 arguments',
        type => 'check',
        method => {
            len => 0, metadata => { len => 0 },
        },
        exception => qr/cannot accept 0 arguments/,
    },
    {
        name => 'Ordered meta missing arg position',
        type => 'check',
        method => {
            len => 0, metadata => { len => 1 },
        },
        exception => qr/metadata with no arg position/,
    },
    {
        name => 'Ordered meta [1] passed [1]',
        type => 'prepare_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => { metadata => [42] },
        output => [42],
    },
    {
        name => 'Ordered meta [1] passed [2]',
        type => 'prepare_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => { metadata => [42, 43] },
        output => [42],
    },
    {
        name => 'Ordered meta [1] passed [3]',
        type => 'prepare_meta',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => { metadata => [42, 43, 44] },
        output => [42],
    },
    {
        name => 'Ordered meta [2] passed [2]',
        type => 'prepare_meta',
        method => {
            len => 0,
            metadata => { len => 2, arg => -1, },
        },
        input => { metadata => [42, 43] },
        output => [42, 43],
    },
    {
        name => 'Ordered meta [2] passed [3]',
        type => 'prepare_meta',
        method => {
            len => 0,
            metadata => { len => 2, arg => -1, },
        },
        input => { metadata => [42, 43, 44] },
        output => [42, 43],
    },
    {
        name => 'Named meta strict 1',
        type => 'prepare_meta',
        method => {
            metadata => { params => ['foo'] },
        },
        input => { metadata => { foo => 'bar' } },
        output => { foo => 'bar' },
    },
    {
        name => 'Named meta strict 2',
        type => 'prepare_meta',
        method => {
            metadata => { params => [qw/ foo bar /] },
        },
        input => { metadata => { foo => 42, bar => 43, baz => 44 } },
        output => { foo => 42, bar => 43, },
    },
    {
        name => 'Named meta !strict 1',
        type => 'prepare_meta',
        method => {
            metadata => { params => ['foo'], strict => !1, },
        },
        input => { metadata => { foo => 42, bar => 43, baz => 44 } },
        output => { foo => 42, bar => 43, baz => 44 },
    },
    {
        name => 'Named meta !strict 2',
        type => 'prepare_meta',
        method => {
            metadata => { params => [], strict => !1, },
        },
        input => { metadata => { foo => 42, bar => 43, baz => 44 } },
        output => { foo => 42, bar => 43, baz => 44 },
    },
    {
        name => 'Named meta default empty',
        type => 'prepare_meta',
        method => {
            metadata => {},
        },
        input => {},
        output => undef,
    },
    {
        name => 'Named meta default !empty',
        type => 'prepare_meta',
        method => {
            metadata => {},
        },
        input => { metadata => { foo => 'bar', baz => 'qux' }, },
        output => { foo => 'bar', baz => 'qux' },
    },
    {
        name => 'Ordered meta input 1',
        type => 'prepare',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ [43] ],
    },
    {
        name => 'Ordered meta input 2',
        type => 'prepare',
        method => {
            len => 0,
            metadata => { len => 1, arg => -1, },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ [43] ],
    },
    {
        name => 'Ordered meta input 3',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => -1,
            metadata => { len => 1, arg => -1, },
        },
        input => {
            env => 'env', input => [42], metadata => [43, 44]
        },
        output => [ [43], 'env' ],
    },
    {
        name => 'Ordered meta input 4',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => 99,
            metadata => { len => 1, arg => 99, },
        },
        input => {
            env => 'env', input => [42], metadata => [43, 44]
        },
        output => [ 'env', [43] ],
    },
    {
        name => 'Ordered meta input 5',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => -1,
            metadata => { len => 1, arg => -2 },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ [43], 'env' ],
    },
    {
        name => 'Ordered meta input 6',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => -1,
            metadata => { len => 1, arg => 99, },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ 'env', [43] ],
    },
    {
        name => 'Ordered meta input 7',
        type => 'prepare',
        method => {
            len => 0,
            env_arg => 99,
            metadata => { len => 1, arg => -1, },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ [43], 'env' ],
    },
    {
        name => 'Ordered meta input 8',
        type => 'prepare',
        method => {
            len => 1,
            env_arg => -1,
            metadata => { len => 1, arg => -1 },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ 'env', [43], 42 ],
    },
    {
        name => 'Ordered meta input 9',
        type => 'prepare',
        method => {
            len => 1,
            env_arg => 99,
            metadata => { len => 1, arg => -1 },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ 42, [43], 'env' ],
    },
    {
        name => 'Ordered meta input 10',
        type => 'prepare',
        method => {
            len => 1,
            env_arg => 99,
            metadata => { len => 1, arg => 99 },
        },
        input => {
            env => 'env', input => [42], metadata => [43]
        },
        output => [ 42, 'env', [43] ],
    },
    {
        name => 'Ordered meta input 11',
        type => 'prepare',
        method => {
            len => 2,
            env_arg => 99,
            metadata => { len => 2, arg => -1 },
        },
        input => {
            env => 'env',
            input => ['foo', 'bar', 'baz'],
            metadata => [42, 43, 44],
        },
        output => [ 'foo', 'bar', [42, 43], 'env' ],
    },
    {
        name => 'Ordered meta input 12',
        type => 'prepare',
        method => {
            params => [],
            env_arg => '_env',
            metadata => { len => 2 },
        },
        input => {
            env => 'env',
            input => { foo => 'bar', baz => 'qux' },
            metadata => [42, 43, 44],
        },
        out_type => 'hash',
        output => {
            _env => 'env',
            foo => 'bar',
            baz => 'qux',
            metadata => [42, 43],
        },
    },
    {
        name => 'Ordered meta input 13',
        type => 'prepare',
        method => {
            formHandler => 1,
            metadata => { len => 1, },
        },
        input => {
            env => 'env',
            input => { fred => 'moo', blurg => 'frob' },
            metadata => [42, 43],
        },
        out_type => 'hash',
        output => {
            fred => 'moo',
            blurg => 'frob',
            metadata => [42],
        },
    },
    {
        name => 'Ordered meta input 14',
        type => 'prepare',
        method => {
            formHandler => 1,
            env_arg => '_e',
            metadata => { len => 1, arg => '_m', },
        },
        input => {
            env => 'env',
            input => { fred => 'moo', blurg => 'frob' },
            metadata => [42, 43],
        },
        out_type => 'hash',
        output => {
            _e => 'env',
            fred => 'moo',
            blurg => 'frob',
            _m => [42],
        },
    },
    {
        name => 'Named meta input 1', 
        type => 'prepare',
        method => {
            len => 1,
            env_arg => 99,
            metadata => { arg => 99, },
        },
        input => {
            env => 'env',
            input => [42, 43],
            metadata => { foo => 'bar', baz => 'qux' },
        },
        out_type => 'array',
        output => [42, 'env', { foo => 'bar', baz => 'qux' }, ],
    },
    {
        name => 'Named meta input 2',
        type => 'prepare',
        method => {
            len => 2,
            env_arg => 99,
            metadata => { params => ['foo'], arg => 99, },
        },
        input => {
            env => 'env',
            input => [42, 43],
            metadata => { foo => 'bar', baz => 'qux' },
        },
        out_type => 'array',
        output => [42, 43, 'env', { foo => 'bar' }, ],
    },
    {
        name => 'Named meta input 3',
        type => 'prepare',
        method => {
            len => 0,
            metadata => { params => ['foo'], strict => !1, arg => 99, },
        },
        input => {
            env => 'env',
            input => [42, 43],
            metadata => { foo => 'bar', baz => 'qux' },
        },
        out_type => 'array',
        output => [{ foo => 'bar', baz => 'qux' }]
    },
    {
        name => 'Named meta input 4',
        type => 'prepare',
        method => {
            params => ['fred', 'frob'],
            env_arg => '_env',
            metadata => { params => ['foo'], arg => '_m' },
        },
        input => {
            env => 'env',
            input => { fred => 'blerg', frob => 'blam', },
            metadata => { foo => 'bar', baz => 'qux' },
        },
        out_type => 'hash',
        output => {
            _env => 'env',
            fred => 'blerg',
            frob => 'blam',
            _m => { foo => 'bar' },
        },
    },
    {
        name => 'Named meta input 5',
        type => 'prepare',
        method => {
            formHandler => 1,
            env_arg => '_e',
            metadata => { params => ['foo'], arg => '_m', },
        },
        input => {
            env => 'env',
            input => { fred => 'moo', blurg => 'frob' },
            metadata => { foo => 'bar', baz => 'qux' },
        },
        out_type => 'hash',
        output => {
            _e => 'env',
            fred => 'moo',
            blurg => 'frob',
            _m => { foo => 'bar' },
        },
    },
];
