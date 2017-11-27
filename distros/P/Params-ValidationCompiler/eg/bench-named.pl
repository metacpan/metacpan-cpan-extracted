## no critic (Moose::RequireCleanNamespace, ErrorHandling::RequireCheckingReturnValueOfEval)
use strict;
use warnings;

use Benchmark qw( cmpthese );

use DateTime;
use Moose::Util::TypeConstraints qw( class_type find_type_constraint );
use MooseX::Params::Validate;
use Params::Validate qw( validate SCALAR ARRAYREF );
use Params::ValidationCompiler ();
use Specio::Declare;
use Specio::Library::Builtins;
use Test2::V0;
use Test2::Plugin::DieOnFail;
use Type::Params ();
use Types::Standard qw( ArrayRef Dict InstanceOf Int Optional slurpy );

my $dt = DateTime->new( year => 2016 );

{
    my $pvc_moose = Params::ValidationCompiler::validation_for(
        params => {
            foo => { type => find_type_constraint('Int') },
            bar => { type => find_type_constraint('ArrayRef') },
            baz => { type => class_type('DateTime'), optional => 1 },
        }
    );

    sub pvc_moose {
        return $pvc_moose->(@_);
    }
}

{
    is(
        dies {
            pvc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_moose( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_moose(
                foo => 42, bar => [ 1, 2, 3 ],
                baz => { year => 2016 }
            );
        }
    );
}

sub call_pvc_moose_lives {
    pvc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pvc_moose( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pvc_moose_dies {
    eval {
        pvc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
    };
}

{
    my $pvc_tt = Params::ValidationCompiler::validation_for(
        params => {
            foo => { type => Int },
            bar => { type => ArrayRef },
            baz => { type => InstanceOf ['DateTime'], optional => 1 },
        }
    );

    sub pvc_tt {
        return $pvc_tt->(@_);
    }
}

{
    is(
        dies {
            pvc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_tt( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
        }
    );
}

sub call_pvc_tt_lives {
    pvc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pvc_tt( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pvc_tt_dies {
    eval { pvc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } ) };
}

{
    my $pvc_specio = Params::ValidationCompiler::validation_for(
        params => {
            foo => { type => t('Int') },
            bar => { type => t('ArrayRef') },
            baz => { type => object_isa_type('DateTime'), optional => 1 },
        }
    );

    sub pvc_specio {
        return $pvc_specio->(@_);
    }
}

{
    is(
        dies {
            pvc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_specio( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_specio(
                foo => 42, bar => [ 1, 2, 3 ],
                baz => { year => 2016 }
            );
        }
    );
}

sub call_pvc_specio_lives {
    pvc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pvc_specio( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pvc_specio_dies {
    eval {
        pvc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
    };
}

{
    my %spec = (
        foo => { isa => find_type_constraint('Int') },
        bar => { isa => find_type_constraint('ArrayRef') },
        baz => { isa => class_type('DateTime'), optional => 1 },
    );

    sub mxpv {
        return validated_hash( \@_, %spec );
    }
}

{
    is(
        dies {
            mxpv( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            mxpv( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            mxpv( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
        }
    );
}

sub call_mxpv_lives {
    mxpv( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    mxpv( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_mxpv_dies {
    eval { mxpv( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } ) };
}

{
    my $tp = Type::Params::compile_named(
        foo => Int,
        bar => ArrayRef,
        baz => Optional [ InstanceOf ['DateTime'] ],
    );

    sub tp {
        return $tp->(@_);
    }
}

{
    is(
        dies {
            tp( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            tp( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            tp( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
        }
    );
}

sub call_tp_lives {
    tp( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    tp( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_tp_dies {
    eval { tp( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } ) };
}

sub pv {
    validate(
        @_,
        {
            foo => {
                type  => SCALAR,
                regex => qr/^\d+$/a,
            },
            bar => { type => ARRAYREF },
            baz => {
                isa      => 'DateTime',
                optional => 1,
            },
        },
    );
}

{
    is(
        dies {
            pv( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pv( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pv( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
        }
    );
}

sub call_pv_lives {
    pv( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pv( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pv_dies {
    eval { pv( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } ) };
}

done_testing();

cmpthese(
    100000, {
        pvc_moose_lives  => \&call_pvc_moose_lives,
        pvc_tt_lives     => \&call_pvc_tt_lives,
        pvc_specio_lives => \&call_pvc_specio_lives,
        mxpv_lives       => \&call_mxpv_lives,
        tp_lives         => \&call_tp_lives,
        pv_lives         => \&call_pv_lives,
    }
);

print "\n" or die $!;

cmpthese(
    50000, {
        pvc_moose_dies  => \&call_pvc_moose_dies,
        pvc_tt_dies     => \&call_pvc_tt_dies,
        pvc_specio_dies => \&call_pvc_specio_dies,
        mxpv_dies       => \&call_mxpv_dies,
        tp_dies         => \&call_tp_dies,
        pv_dies         => \&call_pv_dies,
    },
);
