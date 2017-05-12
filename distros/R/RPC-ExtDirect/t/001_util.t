use strict;
use warnings;

use Carp;
use Test::More tests => 70;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Util;
use RPC::ExtDirect::Util::Accessor;

# Simple accessors

package Foo;

sub new {
    my ($class, %params) = @_;

    return bless {%params}, $class;
}

sub bleh {
    return RPC::ExtDirect::Util::get_caller_info($_[1]);
}

# This one is to test existing sub handling
sub fred {}

RPC::ExtDirect::Util::Accessor::mk_accessors( simple => ['bar', 'baz'] );

package main;

my $foo = Foo->new( bar => 'baz' );

my $res = eval { $foo->bar() };

is $@,   '',    "Simple getter didn't die";
is $res, 'baz', "Simple getter value match";

$res = eval { $foo->has_bar() };

is $@,   '', "Simple accessor 1 predicate didn't die";
is $res, 1,  "Simple accessor 1 predicate match";

$res = eval { $foo->has_baz() };

is $@,   '', "Simple accessor 2 predicate didn't die";
is $res, !1, "Simple accessor 2 predicate match";

$res = eval { $foo->bar('qux'); };

is $@,          '',    "Simple setter didn't die";
is $res,        $foo,  "Simple setter return the object";
is $foo->{bar}, 'qux', "Simple setter value match";

$res = eval { $foo->bar() };

is $res, 'qux', "Simple getter after setter value match";

# Existing methods w/o overwrite

eval {
    RPC::ExtDirect::Util::Accessor::mk_accessors(
        class  => 'Foo',
        simple => ['fred'],
    )
};

my $regex = qr/^Accessor fred already exists in class Foo/;

like $@, $regex, "Existing method w/o overwrite died";

# Existing methods w/o overwrite but w/ ignore

eval {
    RPC::ExtDirect::Util::Accessor->mk_accessor(
        class  => 'Foo',
        simple => 'fred',
        ignore => 1,
    )
};

is $@, '', "Existing method w/o ovr w/ ignore didn't die";

$foo->fred('frob');

is $foo->fred(), undef, "Existing method w/o ovr w/ ignore didn't ovr";

# Existing methods w/ overwrite

eval {
    RPC::ExtDirect::Util::Accessor->mk_accessors(
        class     => 'Foo',
        simple    => ['fred'],
        overwrite => 1,
    );
};

is $@, '', "Existing method w/ overwrite didn't die";

$foo->fred('blerg');

is $foo->fred(), 'blerg', "Existing method overwritten";

# Complex accessors

package Complex;

our @ISA = qw/ Foo /;

RPC::ExtDirect::Util::Accessor::mk_accessors(
    complex => [{
        setter   => 'bar_baz',
        fallback => 'bar',
    }, {
        setter   => 'baz_baz',
        fallback => 'bar_baz',
    }]
);

package main;

my $baz = Complex->new( bar_baz => 'bleh' );

$res = eval { $baz->bar_baz() };

is $@,   '',     "Complex getter w/ specific didn't die";
is $res, 'bleh', "Complex getter w/ specific value match";

$res = eval { $baz->has_bar_baz() };

is $@,   '', "Complex accessor 1 predicate didn't die";
is $res, 1,  "Complex accessor 1 predicate match";

$res = eval { $baz->has_baz_baz() };

is $@,   '', "Complex accessor 2 predicate didn't die";
is $res, !1, "Complex accessor 2 predicate match";

$res = eval { $baz->bar_baz('mumble') };

is $@,              '',       "Complex setter w/ specific didn't die";
is $res,            $baz,     "Complex setter w/ specific return the object";
is $baz->{bar_baz}, 'mumble', "Complex setter w/ specific specific object value";
is $baz->{bar},     undef,    "Complex setter w/ specific default object value";

$baz = Complex->new( bar => 'bloom' );

$res = eval { $baz->bar_baz() };

is $@,   '',      "Complex getter w/ default didn't die";
is $res, 'bloom', "Complex getter w/ default value match";

$res = eval { $baz->bar_baz('croffle') };

is $@,              '',        "Complex setter didn't die";
is $res,            $baz,      "Complex setter w/ default return the object";
is $baz->{bar_baz}, 'croffle', "Complex setter w/ default specific object value";
is $baz->{bar},     'bloom',   "Complex setter w/ default default object value";

$res = eval { $baz->bar_baz() };

is $@,   '',        "Complex getter after setter didn't die";
is $res, 'croffle', "Complex getter after setter value match";

$res = eval { $baz->bar() };

is $@,   '',      "Complex getter after setter default didn't die";
is $res, 'bloom', "Complex getter after setter default value match";

# Caller info retrieval

my $info = $foo->bleh(1);

is $info, "Foo->bleh", "caller info";

# die() message cleaning

eval { die "foo bar" };

my $msg = RPC::ExtDirect::Util::clean_error_message($@);

is $msg, "foo bar", "die() message clean";

# croak() message cleaning

eval { croak "moo fred" };

$msg = RPC::ExtDirect::Util::clean_error_message($@);

is $msg, "moo fred", "croak() message clean";

# Package flags parsing

package Bar;

no warnings;

my @accessors = qw/ scalar_value empty_scalar
                    array_value empty_array
                    hash_value empty_hash/;

our $SCALAR_VALUE = 1;
our $EMPTY_SCALAR;

our @ARRAY_VALUE = qw/foo bar/;
our @EMPTY_ARRAY;

our %HASH_VALUE = ( foo => 'bar' );
our %EMPTY_HASH = ();

sub new {
    my $class = shift;

    return bless {@_}, $class;
}

RPC::ExtDirect::Util::Accessor::mk_accessors( simple => \@accessors );

package main;

my $tests = [{
    name   => 'scalar w/ value',
    regex  => qr/^.*?Bar::SCALAR_VALUE.*?scalar_value/ms,
    result => 1,
    flag   => {
        package => 'Bar',
        var     => 'SCALAR_VALUE',
        type    => 'scalar',
        setter  => 'scalar_value',
        default => 'foo',
    },
}, {
    name   => 'scalar w/o value',
    regex  => '', # Should be no warning
    result => 'bar',
    flag   => {
        package => 'Bar',
        var     => 'EMPTY_SCALAR',
        type    => 'scalar',
        setter  => 'empty_scalar',
        default => 'bar',
    },
}, {
    name   => 'array w/ values',
    regex  => qr/^.*Bar::ARRAY_VALUE.*?array_value/ms,
    result => [qw/ foo bar /],
    flag   => {
        package => 'Bar',
        var     => 'ARRAY_VALUE',
        type    => 'array',
        setter  => 'array_value',
        default => [qw/ baz qux /],
    },
}, {
    name   => 'empty array',
    regex  => '',
    result => [qw/ moo fuy /],
    flag   => {
        package => 'Bar',
        var     => 'EMPTY_ARRAY',
        type    => 'array',
        setter  => 'empty_array',
        default => [qw/ moo fuy /],
    },
}, {
    name   => 'empty array no default',
    regex  => '',
    result => undef,
    flag   => {
        package => 'Bar',
        var     => 'EMPTY_ARRAY',
        type    => 'array',
        setter  => 'empty_array',
    },
}, {
    name   => 'hash w/ values',
    regex  => qr/^.*Bar::HASH_VALUE.*?hash_value/ms,
    result => { foo => 'bar' },
    flag   => {
        package => 'Bar',
        var     => 'HASH_VALUE',
        type    => 'hash',
        setter  => 'hash_value',
        default => { baz => 'qux' },
    },
}, {
    name   => 'empty hash',
    regex  => '',
    result => { mymse => 'fumble' },
    flag   => {
        package => 'Bar',
        var     => 'EMPTY_HASH',
        type    => 'hash',
        setter  => 'empty_hash',
        default => { mymse => 'fumble' },
    },
}, {
    name   => 'empty hash no default',
    regex  => '',
    result => undef,
    flag   => {
        package => 'Bar',
        var     => 'EMPTY_HASH',
        type    => 'hash',
        setter  => 'empty_hash',
        default => undef,
    },
}];

our $warn_msg;

$SIG{__WARN__} = sub { $warn_msg = shift };

for my $test ( @$tests ) {
    my $name    = $test->{name};
    my $regex   = $test->{regex};
    my $result  = $test->{result};
    my $flag    = $test->{flag};
    my $type    = $flag->{type};
    my $field   = $flag->{setter};
    my $has_def = exists $flag->{default};
    
    my $obj = new Bar;
    
    $warn_msg = '';

    eval { RPC::ExtDirect::Util::parse_global_flags( [$flag], $obj ) };
    
    is $@, '', "Var $name didn't die";
    
    if ( $regex ) {
        like $warn_msg, $regex, "Var $name warning matches";
    }
    else {
        is $warn_msg, '', "Var $name warning empty";
    }
    
    my $value = $obj->$field();
    
    if ( $type eq 'scalar' ) {
        is ref($value), '', "Var $name type matches";
        is $value, $result, "Var $name value matches";
    }
    else {
        if ( defined $result ) {
            is ref($value), uc $type,  "Var $name type matches";
        }
        is_deep $value, $result, "Var $name value matches";
    }
    
    if ( !$has_def ) {
        my $predicate = "has_$field";
        
        is $obj->$predicate(), !1, "Var $name not defaulted";
    }
};

my $bar = Bar->new( scalar_value => 'fred' );

my $flag = $tests->[0]->{flag};

RPC::ExtDirect::Util::parse_global_flags( [ $flag ], $bar );

is $bar->scalar_value, 1, "Existing object value overwritten";

