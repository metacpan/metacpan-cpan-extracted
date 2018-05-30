#
use strict;
use warnings;
use Test2::V0;

my %testType = (
    Class => sub {
        my ( $testName, $testParams ) = @_;
        my $prefix    = "__MAFT::Class::";
        my $className = $prefix . $testName;

        my $body    = $testParams->{body} // '';
        my $extends = '';

        if ( ref($body) eq 'CODE' ) {
            $body = $body->( $testName, $testParams );
        }

        if ( $testParams->{extends} ) {
            my @extList =
              ref( $testParams->{extends} )
              ? @{ $testParams->{extends} }
              : ( $testParams->{extends} );
            $extends =
              "extends qw<" . join( " ", map { $prefix . $_ } @extList ) . ">;";
        }

        my $rc = eval <<CLASS;
package $className;

use Moo;
$extends

$body

1;
CLASS
        die $@ if $@;
        return $className;
    },
    Role => sub {
        my ( $testName, $testParams ) = @_;
        my $prefix    = "__MAFT::Role::";
        my $roleName  = $prefix . $testName;
        my $className = "__MAFT::RoleClass::" . $testName;

        my $body = $testParams->{body} // '';
        my $with = '';

        if ( $testParams->{extends} ) {
            my @extList =
              ref( $testParams->{extends} )
              ? @{ $testParams->{extends} }
              : ( $testParams->{extends} );
            $with =
              "with qw<" . join( " ", map { $prefix . $_ } @extList ) . ">;";
        }

        my $code = <<ROLE;
package ${roleName};

use Moo::Role;
$with

$body

1;
ROLE
        my $rc = eval $code;
        die $@ if $@;

        $rc = eval <<CLASS;
package ${className};

use Moo;
with qw<${roleName}>;

1;
CLASS
        die $@ if $@;
        return $className;
    },
);

my @testData = (
    [
        Simple => {
            test => sub {
                my $class = shift;
                plan 3;

                my $o = $class->new;
                $o->f_anonymous("value");
                like( $o->f_anonymous, "anonymous(value)", "simple anonymous" );
                $o->f_default("value");
                like( $o->f_default, "default(value)", "simple default" );
                $o->f_named("value");
                like( $o->f_named, "named(value)", "simple named" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has f_anonymous => (
    is     => 'rw',
    filter => sub {
        my $this = shift;
        return "anonymous($_[0])";
    },
);

has f_default => (
    is     => 'rw',
    filter => 1,
);

has f_named => (
    is     => 'rw',
    filter => 'namedFilter',
);

sub _filter_f_default {
    my $this = shift;
    return "default($_[0])";
}

sub namedFilter {
    my $this = shift;
    return "named($_[0])";
}
CODE
        },
    ],
    [
        OldValue => {
            test => sub {
                my $class = shift;
                plan 3;

                my $o = $class->new( attr => 'init' );
                like( $o->oldValue, "construction stage",
                    "construction stage" );
                $o->attr("postinit");
                like( $o->oldValue, "init", "old value preserved" );

                $o = $class->new;
                $o->attr("first");
                ok( !defined $o->oldValue,
                    "old value undefined for the first write" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has attr => (
    is     => 'rw',
    filter => sub {
        my $this = shift;
        if ( @_ == 1 ) {
            $this->oldValue("construction stage");
        }
        else {
            $this->oldValue( $_[1] );
        }
        return $_[0];
    },
);

has oldValue => ( is => 'rw', );
CODE
        },
    ],
    [
        Laziness => {
            body => <<'CODE',
use MooX::AttributeFilter;

# To record number of arguments of filter sub
has args => (
    is => 'rw',
);

has lz_default => (
    is      => 'rw',
    lazy    => 1,
    default => 'defVal',
    filter  => 'lzFilter',
);

has lz_builder => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initLzBuilder',
    filter  => 'lzFilter',
);

sub lzFilter {
    my $this = shift;
    $this->args(scalar @_);
    return "lazy_or_not($_[0])";
}

sub initLzBuilder {
    return "builtVal";
}
CODE
            test => sub {
                my $class = shift;
                plan 5;

                my $o = $class->new;
                like( $o->lz_default, "lazy_or_not(defVal)",
                    "lazy init with default" );
                is($o->args, 1, "lazy init filter has 1 arg");
                $o->lz_default("3.1415926");
                like( $o->lz_default, "lazy_or_not(3.1415926)",
                    "lazy attribute set ok" );
                is($o->args, 2, "lazy argument set filter has 2 args");
                like( $o->lz_builder, "lazy_or_not(builtVal)",
                    "lazy init with builder" );
            },
        }
    ],
    [
        Triggering => {
            test => sub {
                my $class = shift;
                plan 2;

                my $o = $class->new( tattr => "init" );
                like( $o->trig_arg, "_filter_tattr(init)",
                    "triggered from constructor" );
                $o->tattr("set");
                like( $o->trig_arg, "_filter_tattr(set)",
                    "triggered from write" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has tattr => (
    is      => 'rw',
    trigger => 1,
    filter  => 1,
);

has trig_arg => ( is => 'rw' );

sub _trigger_tattr {
    my $this = shift;
    $this->trig_arg( $_[0] );
}

sub _filter_tattr {
    my $this = shift;
    return "_filter_tattr($_[0])";
}
CODE
        },
    ],
    [
        Coercing => {
            test => sub {
                my $class = shift;
                plan 1;

                my $o = $class->new;
                $o->cattr(3.1415926);
                is( $o->cattr, -2.1415926, "coerce applied" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has cattr => (
    is     => 'rw',
    coerce => sub { $_[0] + 1 },
    filter => sub {
        my $this = shift;
        return -$_[0];
    },
);
CODE
        },
    ],
    [
        'Child::NoFilter' => {
            test => sub {
                my $class = shift;
                plan 2;
                my $o = $class->new( attr => "construction" );
                $o->attr("set");
                like( $o->attr,     "set",          "attribute set" );
                like( $o->oldValue, "construction", "old value preserved" );
            },
            extends => 'OldValue',
        },
    ],
    [
        NoFilter => {
            test => sub {
                my $class = shift;
                plan 1;

                # Check if accidental filter applying happens.

                my $o = $class->new;
                $o->attr("value");
                like( $o->attr, "value",
                    "we don't install filter if not requested by class" );
            },
            body => <<'CODE',
has attr => (
    is     => 'rw',
    filter => sub {
        my $this = shift;
        return "filtered($_[0])";
    },
);

has no_flt => ( is => 'rw', );
CODE
        },
    ],
    [
        'Child::Override' => {
            skipFor => {
                Role => 'Attribute modification doesn\'t play well for roles',
            },
            test => sub {
                my $class = shift;
                plan 3;

                my $o = $class->new;
                $o->attr("abc");

                # This is unintended side effect. Not sure if it worth fixing...
                like( $o->attr, "filtered(abc)", "O'RLY?" );
                $o->no_flt("123");
                like( $o->no_flt, "no_flt(123)",
                    "unfiltered attribute upgrade" );
                $o->myAttr("3.1415926");
                like( $o->myAttr, "myAttr(3.1415926)",
                    "own filtered attribute" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has '+attr' => ();

has '+no_flt' => (
    filter => sub {
        my $this = shift;

        return "no_flt($_[0])";
    },
);

has myAttr => (
    is     => 'rw',
    filter => sub {
        my $this = shift;
        return "myAttr($_[0])";
    },
);
CODE
            extends => 'NoFilter',
        },
    ],
    [
        Complex => {
            test => sub {
                my $class = shift;
                plan 6;

                my $o = $class->new;
                $o->af(1);
                is( $o->af, 12, "other attributes involved" );

                my @prog = ( 1, 1, 1, 2, 1, 3, 4, 7, 1, 8 );
                use List::Util qw<pairs>;

                my $step = 0;
                foreach my $pair ( pairs @prog ) {
                    $o->progressive( $pair->[0] );
                    is( $o->progressive, $pair->[1],
                        "progressive step #" . ++$step );
                }
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has a1 => (
    is      => 'rw',
    default => 10,
);

has a2 => (
    is      => 'rw',
    default => 2,
);

has af => (
    is     => 'rw',
    filter => 'filterAF',
);

has progressive => (
    is     => 'rw',
    filter => sub {
        my $this = shift;
        return $_[0] + ( $_[1] || 0 );
    },
);

sub filterAF {
    my $this = shift;
    return $_[0] * $this->a1 + $this->a2;
}
CODE
        },
    ],
    [
        Typed => {
            test => sub {
                my $class = shift;

                my $o = $class->new;
                eval {
                    $o->typed(123);
                    is( $o->typed, 123, "simple num" );
                    $o->typed("prefix10");
                    is( $o->typed, 10, "prefix removed" );
                };
                ok( !$@, "passed" );
                eval { $o->typed("bad!"); };
                like( $@, qr/Bad typed value 'bad!'/, "bad value handled" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;
use Scalar::Util qw<looks_like_number>;

has typed => (
    is  => 'rw',
    isa => sub {
        die "Bad typed value '$_[0]'" unless looks_like_number( $_[0] );
    },
    filter => sub {
        my $this = shift;
        my $val  = $_[0];
        $val =~ s/^prefix//;
        return $val;
    }
);

CODE
        },
    ],
    [
        DefaultVal => {
            test => sub {
                my $class = shift;

                my $o = $class->new;
                is( $o->defAttr, "filtered(3.1415926)",
                    "default passed through filter" );
            },
            body => <<'CODE',
use MooX::AttributeFilter;

has defAttr => (
    is => 'rw',
    default => 3.1415926,
    filter => sub {
        my $this = shift;
        return "filtered($_[0])";
    },
);
CODE
        },
    ],
);

#push @testData, generateCallOrder;
# Data for order tests

eval { require Types::Standard; };
my $noTypes = !!$@;

sub _skip_if_noTypes {
    return $noTypes ? "Types::Standard required for this test" : "";
}

sub _check_callOrder_second {
    my ( $class, $testParams, $obj, $word ) = @_;

    my $order = $class->getOrder;
    is( $class->getOrder->[1], $word, "$word was called second" );
}

my @mooOpts = (
    [
        isa_simple => {
            body_opt  => 'isa => StrMatch[qr/^filtered\(.*\)$/]',
            body_head => 'use Types::Standard qw<StrMatch>;',
            skip      => \&_skip_if_noTypes,
        },
    ],
    [
        isa_inline => {
            body_opt => 'isa => sub {push @callOrder, "isa"; return 1;}',
            check    => sub { _check_callOrder_second( @_, 'isa' ) },
        },
    ],
    [
        isa_coderef => {
            body_opt => 'isa => \&isaSub',
            body     => 'sub isaSub {push @callOrder, "isa"; return 1;}',
            check    => sub { _check_callOrder_second( @_, 'isa' ) },
        },
    ],
    [
        types_coerce => {
            body_opt =>
q|    isa => (StrMatch[qr/^filtered\(.*\)/])->where(sub{push @callOrder, "coerce"; $_[0]}),
    coerce => 1|,
            body_head => 'use Types::Standard qw<StrMatch Str>;',
            skip      => \&_skip_if_noTypes,
            check     => sub { _check_callOrder_second( @_, 'coerce' ) },
        }
    ],
    [
        coerce_inline => {
            body_opt => 'coerce => sub { push @callOrder, "coerce"; $_[0]}',
            check    => sub { _check_callOrder_second( @_, 'coerce' ) },
        },
    ],
);

my @filterOpts = (
    [
        no_filter => {},
    ],
    [
        filter_bool => {
            body_opt => 'filter => 1',
            body =>
'sub _filter_attr {push @callOrder, "filter";return "filtered($_[1])"}',
        },
    ],
    [
        filter_inline => {
            body_opt =>
'filter => sub {push @callOrder, "filter"; return "filtered($_[1])";}',
        }
    ],
    [
        filter_named => {
            body_opt => "filter => 'filterAttr'",
            body =>
'sub filterAttr {push @callOrder, "filter"; return "filtered($_[1])";}',
        },
    ],
);

sub _order_test_with_filter {
    my ( $class, $testParams ) = @_;
    $class->resetOrder;
    my $obj;
    eval { $obj = $class->new( attr => "3.1415926" ); };
    diag("Error while creating a object:\n", $@) if $@;
    ok( !$@, "new finishes normally" );
    is( $obj->attr, "filtered(3.1415926)",
        "value passed the filter with constructor" );
    is( $class->getOrder->[0],
        'filter', "filter was called first with constructor" );

    $class->resetOrder;
    eval { $obj->attr("12345"); };
    ok( !$@, "attribute setter finishes normally" );
    is( $obj->attr, "filtered(12345)", "value passed the filter with setter" );
    is( $class->getOrder->[0], 'filter',
        "filter was called first with setter" );

    foreach my $check ( @{ $testParams->{checks} } ) {
        $check->( @_, $obj );
    }
}

sub _order_test_without_filter {
    my $class = shift;

    my $obj;
    eval { $obj = $class->new( attr => "3.1415926" ); };
  SKIP: {
        skip("Object creation failed, this was probably expected: $@") if $@;
        is( $obj->attr, "3.1415926", "not filtered" );
    }
}

foreach my $mooOpt (@mooOpts) {
    my ( $mooName, $mooParams ) = @$mooOpt;
    foreach my $filterOpt (@filterOpts) {
        my ( $filterName, $filterParams ) = @$filterOpt;

        my $testName = "CallOrder::${mooName}::${filterName}";

        my $testBody = q|
use MooX::AttributeFilter;
|
          . ( $mooParams->{body_head}    || '' ) . "\n"
          . ( $filterParams->{body_head} || '' ) . q|
our @callOrder;

has attr => (
    is => 'rw',
|
          . ( $mooParams->{body_opt}    || '' ) . ",\n"
          . ( $filterParams->{body_opt} || '' ) . q|,
);
|
          . ( $mooParams->{body}    || '' ) . "\n"
          . ( $filterParams->{body} || '' ) . q|
          
sub resetOrder {
    @callOrder = ();
}

sub getOrder {
    return \@callOrder;
}
1;|;

        my $skip = ( $mooParams->{skip} && $mooParams->{skip}->() )
          || ( $filterParams->{skip} && $filterParams->{skip}->() );

        my @subChecks;
        push @subChecks, $mooParams->{check}    if $mooParams->{check};
        push @subChecks, $filterParams->{check} if $filterParams->{check};

        my $testEntry = [
            $testName => {
                body => $testBody,
                test => (
                    defined $filterParams->{body_opt}
                    ? \&_order_test_with_filter
                    : \&_order_test_without_filter
                ),
                skip   => $skip,
                checks => \@subChecks,
            }
        ];

        push @testData, $testEntry;
    }
}

# Run all tests.
foreach my $type ( keys %testType ) {
    subtest $type => sub {
        my $generator = shift;
        foreach my $test (@testData) {
            my $skipReason =
              $test->[1]{skipFor}{$type} || $test->[1]{skip} || '';
            my $testName = $test->[0];
            if ($skipReason) {
                subtest $testName => sub { skip_all($skipReason); };
            }
            else {
                my $className = $generator->( $testName, $test->[1] );
                subtest $testName => $test->[1]->{test},
                  $className, $test->[1];
            }
        }
      },
      $testType{$type};
}

done_testing;

__END__
