## no critic (Moose::RequireCleanNamespace, ErrorHandling::RequireCheckingReturnValueOfEval)
use strict;
use warnings;

use Benchmark qw( cmpthese );

use DateTime;
use Moose::Util::TypeConstraints qw( class_type find_type_constraint );
use MooseX::Params::Validate;
use Params::Validate qw( validate_pos SCALAR ARRAYREF );
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
        params => [
            { type => find_type_constraint('Int') },
            { type => find_type_constraint('ArrayRef') },
            { type => class_type('DateTime'), optional => 1 },
        ],
    );

    sub pvc_moose {
        return $pvc_moose->(@_);
    }
}

{
    is(
        dies {
            pvc_moose( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_moose( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_moose(
                42,
                [ 1, 2, 3 ],
                { year => 2016 }
            );
        }
    );
}

sub call_pvc_moose_lives {
    pvc_moose( 42, [ 1, 2, 3 ], $dt );
    pvc_moose( 42, [ 1, 2, 3 ] );
}

sub call_pvc_moose_dies {
    eval { pvc_moose( 42, [ 1, 2, 3 ], { year => 2016 } ); };
}

{
    my $pvc_tt = Params::ValidationCompiler::validation_for(
        params => [
            { type => Int },
            { type => ArrayRef },
            { type => InstanceOf ['DateTime'], optional => 1 },
        ],
    );

    sub pvc_tt {
        return $pvc_tt->(@_);
    }
}

{
    is(
        dies {
            pvc_tt( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_tt( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_tt( 42, [ 1, 2, 3 ], { year => 2016 } );
        }
    );
}

sub call_pvc_tt_lives {
    pvc_tt( 42, [ 1, 2, 3 ], $dt );
    pvc_tt( 42, [ 1, 2, 3 ] );
}

sub call_pvc_tt_dies {
    eval { pvc_tt( 42, [ 1, 2, 3 ], { year => 2016 } ) };
}

{
    my $pvc_specio = Params::ValidationCompiler::validation_for(
        params => [
            { type => t('Int') },
            { type => t('ArrayRef') },
            { type => object_isa_type('DateTime'), optional => 1 },
        ],
    );

    sub pvc_specio {
        return $pvc_specio->(@_);
    }
}

{
    is(
        dies {
            pvc_specio( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pvc_specio( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pvc_specio(
                42, [ 1, 2, 3 ],
                { year => 2016 }
            );
        }
    );
}

sub call_pvc_specio_lives {
    pvc_specio( 42, [ 1, 2, 3 ], $dt );
    pvc_specio( 42, [ 1, 2, 3 ] );
}

sub call_pvc_specio_dies {
    eval { pvc_specio( 42, [ 1, 2, 3 ], { year => 2016 } ); };
}

{
    my @spec = (
        { isa => find_type_constraint('Int') },
        { isa => find_type_constraint('ArrayRef') },
        { isa => class_type('DateTime'), optional => 1 },
    );

    sub mxpv {
        return pos_validated_list( \@_, @spec );
    }
}

{
    is(
        dies {
            mxpv( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            mxpv( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            mxpv( 42, [ 1, 2, 3 ], { year => 2016 } );
        }
    );
}

sub call_mxpv_lives {
    mxpv( 42, [ 1, 2, 3 ], $dt );
    mxpv( 42, [ 1, 2, 3 ] );
}

sub call_mxpv_dies {
    eval { mxpv( 42, [ 1, 2, 3 ], { year => 2016 } ) };
}

{
    my $tp = Type::Params::compile(
        Int,
        ArrayRef,
        Optional [ InstanceOf ['DateTime'] ],
    );

    sub tp {
        return $tp->(@_);
    }
}

{
    is(
        dies {
            tp( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            tp( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            tp( 42, [ 1, 2, 3 ], { year => 2016 } );
        }
    );
}

sub call_tp_lives {
    tp( 42, [ 1, 2, 3 ], $dt );
    tp( 42, [ 1, 2, 3 ] );
}

sub call_tp_dies {
    eval { tp( 42, [ 1, 2, 3 ], { year => 2016 } ) };
}

sub pv {
    return validate_pos(
        @_,
        {
            type  => SCALAR,
            regex => qr/^\d+$/a,
        },
        { type => ARRAYREF },
        { isa  => 'DateTime', optional => 1 },
    );
}

{
    is(
        dies {
            pv( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pv( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pv( 42, [ 1, 2, 3 ], { year => 2016 } );
        }
    );
}

sub call_pv_lives {
    pv( 42, [ 1, 2, 3 ], $dt );
    pv( 42, [ 1, 2, 3 ] );
}

sub call_pv_dies {
    eval { pv( 42, [ 1, 2, 3 ], { year => 2016 } ) };
}

done_testing();

cmpthese(
    500000, {
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
