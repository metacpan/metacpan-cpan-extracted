use strict;
use warnings;

use Test::More tests => 75;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Util;
use RPC::ExtDirect;

# Dummy subs to use as the referent and the hook
sub foo  {}
sub hook {}

# A shortcut for brevity
*p_attr = *RPC::ExtDirect::Util::parse_attribute;

# This should not be even remotely possible, but magic happens on Christmas
eval { p_attr('foo', *foo, \&foo, 'blerg') };
like $@, qr/^Method attribute is not ExtDirect/, 'Attribute check';

# Unparseable attribute *can* happen, easily enough
eval { p_attr('foo', *foo, \&foo, 'ExtDirect', 'bleh blah') };
like $@, qr/^Malformed ExtDirect attribute/, 'Attribute data check';

# ... unless it's a completely empty attribute, which is acceptable
eval { p_attr('foo', *foo, \&foo, 'ExtDirect', '') };
is $@, '', 'Empty string attribute data';

# *Theoretically* this should not be possible too, but who knows
eval { p_attr('foo', sub {}, sub {}, 'ExtDirect', []) };
like $@, qr/^Can't resolve symbol/, 'Symbol name resolution';

# UNIVERSAL::ExtDirect should be able to rethrow aref exceptions (duh!)
eval {
    UNIVERSAL::ExtDirect('foo', *foo, \&foo, 'ExtDirect', ['len', 1, 'metadata', {len => 0}])
};
like $@, qr/Method.*?cannot accept 0 arguments/, 'Arrayref exceptions';

# The rest is automated
my $tests = eval do { local $/; <DATA> } or die "Can't eval DATA: '$@'";

my @run_only = @ARGV;

TEST:
for my $test ( @$tests ) {
    my $name  = $test->{name};
    my $input = $test->{input};
    my $xcpt  = $test->{xcpt};
    my $want  = $test->{want};

    # This is fixed
    $want->{package} = 'bar';
    $want->{method}  = 'foo';

    next TEST if @run_only && !grep { lc $name eq lc $_ } @run_only;

    my $have = eval {
        p_attr('bar', *foo, \&foo, 'ExtDirect', $input, 'CHECK', 'foo.pm', 42)
    };

    if ( $xcpt ) {
        like $@, $xcpt, "$name: exception matches";
    }
    else {
        is      $@,    '',    "$name: did not die";
        is_deep $have, $want, "$name: result matches";
    }
}

__DATA__
#line 65
[{
    name  => 'Empty arrayref attribute data',
    input => [],
    want  => {},
}, {
    name  => 'Empty string attribute data',
    input => '',
    want  => {},
}, {
    name  => 'Compatibility len',
    input => [42],
    want  => { len => 42, },
}, {
    name  => 'Compatibility len w/ generics',
    input => [42, foo => 'bar', baz => 'qux',],
    want  => { len => 42, foo => 'bar', baz => 'qux', },
}, {
    name  => 'len',
    input => [len => 42],
    want  => { len => 42, },
}, {
    name  => 'len w/ generics',
    input => [foo => 'bar', len => 42, baz => 'qux',],
    want  => { len => 42, foo => 'bar', baz => 'qux', },
}, {
    name  => 'len garbled',
    input => [len => 'foo'],
    xcpt  => qr/attribute 'len' should be followed by a number/,
}, {
    name  => 'len undef',
    input => [42, 'len'],
    xcpt  => qr/attribute 'len' should be followed by a number/,
}, {
    name  => 'params',
    input => [ params => [qw/ foo bar /], ],
    want  => { params => [qw/ foo bar /], },
}, {
    name  => 'params garbled',
    input => [ 'params' ],
    xcpt  => qr{attribute 'params' must be followed},
}, {
    name  => 'params no arrayref',
    input => [ params => {} ],
    xcpt  => qr{attribute 'params' must be followed},
}, {
    name  => 'formHandler',
    input => ['formHandler'],
    want  => { formHandler => 1, },
}, {
    name  => 'pollHandler',
    input => ['pollHandler'],
    want  => { pollHandler => 1, },
}, {
    name  => 'before hook NONE',
    input => [ before => 'NONE' ],
    want  => { before => 'NONE' },
}, {
    name  => 'before hook undef',
    input => [ before => undef, ],
    want  => { before => undef, },
}, {
    name  => 'before hook coderef',
    input => [ before => \&hook, ],
    want  => { before => \&hook, },
}, {
    name  => 'before hook garbled',
    input => [ before => 'foo', ],
    xcpt  => qr{attribute 'before' must be followed},
}, {
    name  => 'instead hook NONE',
    input => [ instead => 'NONE' ],
    want  => { instead => 'NONE' },
}, {
    name  => 'instead hook undef',
    input => [ instead => undef, ],
    want  => { instead => undef, },
}, {
    name  => 'instead hook coderef',
    input => [ instead => \&hook, ],
    want  => { instead => \&hook, },
}, {
    name  => 'instead hook garbled',
    input => [ instead => 'foo', ],
    xcpt  => qr{attribute 'instead' must be followed},
}, {
    name  => 'after hook NONE',
    input => [ before => 'NONE' ],
    want  => { before => 'NONE' },
}, {
    name  => 'after hook undef',
    input => [ after => undef, ],
    want  => { after => undef, },
}, {
    name  => 'after hook coderef',
    input => [ after => \&hook, ],
    want  => { after => \&hook, },
}, {
    name  => 'after hook garbled',
    input => [ after => 'foo', ],
    xcpt  => qr{attribute 'after' must be followed},
}, {
    name  => 'strict truthy',
    input => [ strict => 1, params => ['foo'], ],
    want  => { strict => 1, params => ['foo'], },
}, {
    name  => 'strict falsy',
    input => [ params => ['bar'], strict => !1, ],
    want  => { params => ['bar'], strict => !1, },
}, {
    name  => 'Compatibility len and params',
    input => [42, params => ['foo']],
    xcpt  => qr/attributes 'len' and 'params' are mutually exclusive/,
}, {
    name  => 'len and params',
    input => [len => 42, params => ['foo']],
    xcpt  => qr/attributes 'len' and 'params' are mutually exclusive/,
}, {
    name  => 'Compatibility len and formHandler',
    input => [42, 'formHandler'],
    xcpt  => qr/attributes 'len' and 'formHandler' are mutually exclusive/,
}, {
    name  => 'len and formHandler',
    input => ['formHandler', len => 42],
    xcpt  => qr/attributes 'formHandler' and 'len' are mutually exclusive/,
}, {
    name  => 'Compatibility len and pollHandler',
    input => [42, 'pollHandler'],
    xcpt  => qr/attributes 'len' and 'pollHandler' are mutually exclusive/,
}, {
    name  => 'len and pollHandler',
    input => ['pollHandler', len => 42],
    xcpt  => qr/attributes 'pollHandler' and 'len' are mutually exclusive/,
}, {
    name  => 'params and formHandler',
    input => ['formHandler', params => ['foo']],
    xcpt  => qr/attributes 'formHandler' and 'params' are mutually exclusive/,
}, {
    name  => 'params and pollHandler',
    input => [params => ['bar'], 'pollHandler'],
    xcpt  => qr/attributes 'params' and 'pollHandler' are mutually exclusive/,
}, {
    name  => 'formHandler and pollHandler',
    input => [qw/ formHandler pollHandler /],
    xcpt  => qr/attributes 'formHandler' and 'pollHandler'.*?exclusive/,
}, {
    name  => 'Compatibility len and strict',
    input => [42, strict => 1],
    xcpt  => qr/attribute 'strict' should be used with 'params'/,
}, {
    name  => 'len and strict',
    input => [strict => !1, len => 42],
    xcpt  => qr/attribute 'strict' should be used with 'params'/,
}, {
    name  => 'formHandler and strict',
    input => ['formHandler', strict => 1],
    xcpt  => qr/attribute 'strict' should be used with 'params'/,
}, {
    name  => 'pollHandler and strict',
    input => [strict => !1, 'pollHandler'],
    xcpt  => qr/attribute 'strict' should be used with 'params'/,
}, {
    name  => 'Compatibility len w/ hooks',
    input => [42, before => \&hook, instead => \&hook, after => \&hook,],
    want  => {len => 42, before => \&hook, instead => \&hook, after => \&hook},
}, {
    name  => 'len w/ hooks',
    input => [before => \&hook, instead => \&hook, after => \&hook, len => 42],
    want  => {len => 42, before => \&hook, instead => \&hook, after => \&hook},
}, {
    name  => 'params w/ hooks',
    input => [
        params => ['bar'], before => undef, after => undef, instead => undef
    ],
    want => {
        params => ['bar'], before => undef, after => undef, instead => undef
    },
}, {
    name  => 'formHandler w/ hooks',
    input => [
        'formHandler', instead => 'NONE', before => 'NONE', after => 'NONE',
    ],
    want  => {
        formHandler => 1, instead => 'NONE', before => 'NONE', after => 'NONE'
    },
}, {
    name  => 'pollHandler w/ hooks',
    input => [
        after => \&hook, instead => undef, before => 'NONE', 'pollHandler'
    ],
    want  => {
        pollHandler => 1, before => 'NONE', instead => undef, after => \&hook
    },
}]

