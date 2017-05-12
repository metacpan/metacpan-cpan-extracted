## no critic (Moose::RequireCleanNamespace, ErrorHandling::RequireCheckingReturnValueOfEval)
use strict;
use warnings;

use Benchmark qw( cmpthese );

use DateTime;
use Moose::Util::TypeConstraints qw( class_type find_type_constraint );
use MooseX::Params::Validate;
use Params::ValidationCompiler ();
use Specio::Declare;
use Specio::Library::Builtins;
use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;
use Type::Params ();
use Types::Standard qw( ArrayRef Dict InstanceOf Int Optional slurpy );

my $dt = DateTime->new( year => 2016 );

{
    my $pcc_moose = Params::ValidationCompiler::validation_for(
        params => [
            { type => find_type_constraint('Int') },
            { type => find_type_constraint('ArrayRef') },
            { type => class_type('DateTime'), optional => 1 },
        ],
    );

    sub pcc_moose {
        return $pcc_moose->(@_);
    }
}

{
    is(
        dies {
            pcc_moose( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_moose( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_moose(
                42,
                [ 1, 2, 3 ],
                { year => 2016 }
            );
        }
    );
}

sub call_pcc_moose_lives {
    pcc_moose( 42, [ 1, 2, 3 ], $dt );
    pcc_moose( 42, [ 1, 2, 3 ] );
}

sub call_pcc_moose_dies {
    eval { pcc_moose( 42, [ 1, 2, 3 ], { year => 2016 } ); };
}

{
    my $pcc_tt = Params::ValidationCompiler::validation_for(
        params => [
            { type => Int },
            { type => ArrayRef },
            { type => InstanceOf ['DateTime'], optional => 1 },
        ],
    );

    sub pcc_tt {
        return $pcc_tt->(@_);
    }
}

{
    is(
        dies {
            pcc_tt( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_tt( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_tt( 42, [ 1, 2, 3 ], { year => 2016 } );
        }
    );
}

sub call_pcc_tt_lives {
    pcc_tt( 42, [ 1, 2, 3 ], $dt );
    pcc_tt( 42, [ 1, 2, 3 ] );
}

sub call_pcc_tt_dies {
    eval { pcc_tt( 42, [ 1, 2, 3 ], { year => 2016 } ) };
}

{
    my $pcc_specio = Params::ValidationCompiler::validation_for(
        params => [
            { type => t('Int') },
            { type => t('ArrayRef') },
            { type => object_isa_type('DateTime'), optional => 1 },
        ],
    );

    sub pcc_specio {
        return $pcc_specio->(@_);
    }
}

{
    is(
        dies {
            pcc_specio( 42, [ 1, 2, 3 ], $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_specio( 42, [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_specio(
                42, [ 1, 2, 3 ],
                { year => 2016 }
            );
        }
    );
}

sub call_pcc_specio_lives {
    pcc_specio( 42, [ 1, 2, 3 ], $dt );
    pcc_specio( 42, [ 1, 2, 3 ] );
}

sub call_pcc_specio_dies {
    eval { pcc_specio( 42, [ 1, 2, 3 ], { year => 2016 } ); };
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
    my $tp = Type::Params::validation_for(
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

done_testing();

cmpthese(
    500000, {
        pcc_moose_lives  => \&call_pcc_moose_lives,
        pcc_tt_lives     => \&call_pcc_tt_lives,
        pcc_specio_lives => \&call_pcc_specio_lives,
        mxpv_lives       => \&call_mxpv_lives,
        tp_lives         => \&call_tp_lives,
    }
);

print "\n" or die $!;

cmpthese(
    50000, {
        pcc_moose_dies  => \&call_pcc_moose_dies,
        pcc_tt_dies     => \&call_pcc_tt_dies,
        pcc_specio_dies => \&call_pcc_specio_dies,
        mxpv_dies       => \&call_mxpv_dies,
        tp_dies         => \&call_tp_dies,
    },
);
