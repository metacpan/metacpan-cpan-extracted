#
use strict;
use warnings;
use Test2::V0;
use Test::Moose;

package Simple;
use Moose;
use MooseX::AttributeFilter;

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

package OldValue;
use Moose;
use MooseX::AttributeFilter;

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

package Laziness;
use Moose;
use MooseX::AttributeFilter;

has lz => (
    is      => 'rw',
    lazy    => 1,
    default => 'defVal',
    filter  => sub {
        my $this = shift;
        return "lazy_or_not($_[0])";
    },
);

package Triggering;
use Moose;
use MooseX::AttributeFilter;

has tattr => (
    is      => 'rw',
    trigger => sub { shift->_trigger_tattr(@_) } ,
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

#package Coercing;
#use Moose;
#use MooseX::AttributeFilter;
#
#has cattr => (
#    is     => 'rw',
#    coerce => sub { $_[0] + 1 },
#    filter => sub {
#        my $this = shift;
#        return -$_[0];
#    },
#);

package Child::NoFilter;
use Moose;
extends qw<OldValue>;

package NoFilter;
use Moose;

has attr => (
    is     => 'rw',
#    filter => sub {
#        my $this = shift;
#        return "filtered($_[0])";
#    },
);

has no_flt => ( is => 'rw', );

package Child::Override;
use Moose;
extends qw<NoFilter>;
use MooseX::AttributeFilter;

has '+attr' => ();

has '+no_flt' => (
    traits => ['MooseX::AttributeFilter::Trait::Attribute'], ## TODO: shouldn't need this
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

package Complex;
use Moose;
use MooseX::AttributeFilter;

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

package Typed;
use Moose;
use MooseX::AttributeFilter;
use Scalar::Util qw<looks_like_number>;

has typed => (
    is  => 'rw',
    isa => 'Num',
    filter => sub {
        my $this = shift;
        my $val  = $_[0];
        $val =~ s/^prefix//;
        return $val;
    }
);

package main;

my $M = '(mutable)';

with_immutable {

    subtest "Simple $M" => sub {
        plan 3;

        my $o = Simple->new;
        $o->f_anonymous("value");
        like( $o->f_anonymous, "anonymous(value)", "simple anonymous" );
        $o->f_default("value");
        like( $o->f_default, "default(value)", "simple default" );
        $o->f_named("value");
        like( $o->f_named, "named(value)", "simple named" );
    };

    subtest "OldValue $M" => sub {
        plan 3;

        my $o = OldValue->new( attr => 'init' );
        like( $o->oldValue, "construction stage", "construction stage" );
        $o->attr("postinit");
        like( $o->oldValue, "init", "old value preserved" );

        $o = OldValue->new;
        $o->attr("first");
        ok( !defined $o->oldValue, "old value undefined for the first write" );
    };

    subtest "Laziness $M", sub {
        plan 1;
        
        my $o = Laziness->new;
        like( $o->lz, "lazy_or_not(defVal)", "lazy init" );
    };

    subtest "Triggering $M", sub {
        plan 2;

        my $o = Triggering->new( tattr => "init" );
        todo "this doesn't work yet if mutable" => sub {
            like( $o->trig_arg, "_filter_tattr(init)", "triggered from constructor" );
        };
        $o->tattr("set");
        like( $o->trig_arg, "_filter_tattr(set)", "triggered from write" );
    };

    #subtest "Coercing", sub {
    #    plan 1;
    #
    #    my $o = Coercing->new;
    #    $o->cattr(3.1415926);
    #    is( $o->cattr, -2.1415926, "coerce applied" );
    #};

    subtest "Child::NoFilter $M", sub {
        plan 2;
        my $o = Child::NoFilter->new( attr => "construction" );
        $o->attr("set");
        like( $o->attr,     "set",          "attribute set" );
        like( $o->oldValue, "construction", "old value preserved" );
    };

    subtest "NoFilter $M", sub {
        plan 1;

        # Check if accidental filter applying happens.

        my $o = NoFilter->new;
        $o->attr("value");
        like( $o->attr, "value",
            "we don't install filter if not requested by class" );
    };

    subtest "Override No Filter $M", sub {
        plan 3;

        my $o = Child::Override->new;
        $o->attr("abc");

        todo "MooX::AttributeFilter seems to be unsure about this" => sub {
            # This is unintended side effect. Not sure if it worth fixing...
            like( $o->attr, "filtered(abc)", "O'RLY?" );
        };
        $o->no_flt("123");
        like( $o->no_flt, "no_flt(123)", "unfiltered attribute upgrade" );
        $o->myAttr("3.1415926");
        like( $o->myAttr, "myAttr(3.1415926)", "own filtered attribute" );
    };

    subtest "Complex $M" => sub {
        plan 6;

        my $o = Complex->new;
        $o->af(1);
        is( $o->af, 12, "other attributes involved" );

        my @prog = ( 1, 1, 1, 2, 1, 3, 4, 7, 1, 8 );
        use List::Util qw<pairs>;

        my $step = 0;
        foreach my $pair ( pairs @prog ) {
            $o->progressive( $pair->[0] );
            is( $o->progressive, $pair->[1], "progressive step #" . ++$step );
        }
    };

    subtest "Type Check $M", sub {

        my $o = Typed->new;
        eval {
            $o->typed(123);
            is( $o->typed, 123, "simple num" );
            $o->typed("prefix10");
            is( $o->typed, 10, "prefix removed" );
        };
        ok( !$@, "passed" );
        eval { $o->typed("bad!"); };
        like( $@, qr/type constraint/, "bad value handled" );
    };
    
    $M = '(immutable)';
}
qw(
    Simple
    OldValue
    Laziness
    Triggering
    Child::NoFilter
    NoFilter
    Child::Override
    Complex
    Typed
);

done_testing;

__END__
