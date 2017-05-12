## no critic (Moose::RequireCleanNamespace, ErrorHandling::RequireCheckingReturnValueOfEval)
use strict;
use warnings;

use Benchmark qw( cmpthese );

use DateTime;
use Moose::Util::TypeConstraints qw( class_type find_type_constraint );
use MooseX::Params::Validate;
use Params::CheckCompiler ();
use Specio::Declare;
use Specio::Library::Builtins;
use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;
use Type::Params ();
use Types::Standard qw( ArrayRef Dict InstanceOf Int Optional slurpy );

my $dt = DateTime->new( year => 2016 );

{
    my $pcc_moose = Params::CheckCompiler::validation_for(
        params => {
            foo => { type => find_type_constraint('Int') },
            bar => { type => find_type_constraint('ArrayRef') },
            baz => { type => class_type('DateTime'), optional => 1 },
        }
    );

    sub pcc_moose {
        return $pcc_moose->(@_);
    }
}

{
    is(
        dies {
            pcc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_moose( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_moose(
                foo => 42, bar => [ 1, 2, 3 ],
                baz => { year => 2016 }
            );
        }
    );
}

sub call_pcc_moose_lives {
    pcc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pcc_moose( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pcc_moose_dies {
    eval {
        pcc_moose( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
    };
}

{
    my $pcc_tt = Params::CheckCompiler::validation_for(
        params => {
            foo => { type => Int },
            bar => { type => ArrayRef },
            baz => { type => InstanceOf ['DateTime'], optional => 1 },
        }
    );

    sub pcc_tt {
        return $pcc_tt->(@_);
    }
}

{
    is(
        dies {
            pcc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_tt( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
        }
    );
}

sub call_pcc_tt_lives {
    pcc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pcc_tt( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pcc_tt_dies {
    eval { pcc_tt( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } ) };
}

{
    my $pcc_specio = Params::CheckCompiler::validation_for(
        params => {
            foo => { type => t('Int') },
            bar => { type => t('ArrayRef') },
            baz => { type => object_isa_type('DateTime'), optional => 1 },
        }
    );

    sub pcc_specio {
        return $pcc_specio->(@_);
    }
}

{
    is(
        dies {
            pcc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
        },
        undef,
    );
    is(
        dies {
            pcc_specio( foo => 42, bar => [ 1, 2, 3 ] );
        },
        undef,
    );
    ok(
        dies {
            pcc_specio(
                foo => 42, bar => [ 1, 2, 3 ],
                baz => { year => 2016 }
            );
        }
    );
}

sub call_pcc_specio_lives {
    pcc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => $dt );
    pcc_specio( foo => 42, bar => [ 1, 2, 3 ] );
}

sub call_pcc_specio_dies {
    eval {
        pcc_specio( foo => 42, bar => [ 1, 2, 3 ], baz => { year => 2016 } );
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
    my $tp = Type::Params::compile(
        slurpy Dict [
            foo => Int,
            bar => ArrayRef,
            baz => Optional [ InstanceOf ['DateTime'] ],
        ]
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

done_testing();

cmpthese(
    100000, {
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
