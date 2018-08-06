use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( blessed );
use Specio::Library::Builtins;

for my $want_cxsa ( 0, 1 ) {
    next if $want_cxsa && !Params::ValidationCompiler::Compiler->HAS_CXSA;
    subtest(
        ( $want_cxsa ? 'with' : 'without' ) . ' Class::XSAccessor',
        sub { test_return_object($want_cxsa) },
    );
}

sub test_return_object {
    my $want_cxsa = shift;
    local $ENV{TEST_NAMED_ARGS_OBJECT_WITHOUT_CXSA} = !$want_cxsa;

    {
        my $sub = validation_for(
            params => {
                foo => 1,
                bar => {
                    type     => t('Int'),
                    optional => 1,
                },
            },
            return_object => 1,
        );

        my $ret = $sub->( foo => 42 );
        ok(
            blessed $ret,
            'returned value is a blessed object'
        );

        if ($want_cxsa) {
            like(
                blessed $ret,
                qr/XS/,
                'returned object class uses Class::XSAccessor'
            );
        }
        else {
            like(
                blessed $ret,
                qr/PP/,
                'returned object class uses pure Perl'
            );
        }

        is(
            $ret->foo,
            42,
            'returned object contains foo param'
        );

        is(
            $ret->bar,
            undef,
            'returned object has undef for bar param'
        );
    }

    {
        my $sub = validation_for(
            params => {
                foo => { getter => 'get_foo' },
                bar => {
                    type      => t('Int'),
                    optional  => 1,
                    predicate => 'has_bar',
                },
            },
            return_object => 1,
        );

        my $ret = $sub->( foo => 42 );
        is(
            $ret->get_foo,
            42,
            'getter name is used instead of param name'
        );

        ok(
            !$ret->has_bar,
            'predicated is created when requested'
        );
    }
}

done_testing();
