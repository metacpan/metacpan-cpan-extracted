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

has lz => (
    is      => 'rw',
    lazy    => 1,
    default => 'defVal',
    filter  => sub {
        my $this = shift;
        return "lazy_or_not($_[0])";
    },
); 
CODE
            test => sub {
                my $class = shift;
                plan 1;

                my $o = $class->new;
                like( $o->lz, "lazy_or_not(defVal)", "lazy init" );
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
);

package main;

foreach my $type ( keys %testType ) {
    subtest $type => sub {
        my $generator = shift;
        foreach my $test (@testData) {
            my $skipReason = $test->[1]->{skipFor}{$type} || '';
            my $testName = $test->[0];
            if ($skipReason) {
                subtest $testName => sub { skip_all($skipReason); };
            }
            else {
                my $className = $generator->( $testName, $test->[1] );
                subtest $testName => $test->[1]->{test},
                  $className, $skipReason;
            }
        }
      },
      $testType{$type};
}

done_testing;

__END__
