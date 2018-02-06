use strict;
use warnings;
use Test::More 'tests' => 5;
use Ref::Util::XS ':all';

use constant FORMAT_REFS_WORK => ("$]" >= 5.007);

# FIXME: plain regular expressions, blessed regular expressions

my $plain_formatref = do {
    format FH1 =
.
    *FH1{'FORMAT'};
};

my $blessed_formatref = !FORMAT_REFS_WORK ? undef : bless do {
    format FH2 =
.
    *FH2{'FORMAT'};
}, 'FormatRef';

my $evil_blessed_formatref = !FORMAT_REFS_WORK ? undef : bless do {
    format FH3 =
.
    *FH3{'FORMAT'};
}, '0';

my ( $var_for_globref, $var_for_blessed_globref, $var_for_evil_globref );
my $plain_scalar = 'string';
my $var_for_scalarref = 'stringy';
my $blessed_scalarref = bless \$var_for_scalarref, 'ScalarRef';

my %all;
{;
    # globref causes this warning
    no warnings qw<once>;

    %all = (
        'plain_scalarref' => \$plain_scalar,
        'plain_scalarref_vstring' => \v1.2.3,
        'plain_arrayref'  => [],
        'plain_hashref'   => +{},
        'plain_coderef'   => sub {'plain_code'},
        #'plain_regexpref' => qr{plain},
        'plain_globref'   => \*::var_for_globref,
        'plain_formatref' => $plain_formatref,
        'plain_refref'    => \\$plain_scalar,
        'plain_refref_sub' =>  \sub{},

        'blessed_scalarref' => $blessed_scalarref,
        'blessed_scalarref_vstring' => bless( \ do { my $x = v1.2.3 }, 'ScalarRef' ),
        'blessed_arrayref'  => bless( [], 'ArrayRef' ),
        'blessed_hashref'   => bless( +{}, 'HashRef' ),
        'blessed_coderef'   => bless( sub {'blessed_code'}, 'CodeRef' ),
        #'blessed_regexp'    => bless( qr{blessed}, 'BlessedRegexp' ),
        'blessed_globref'   => bless( \*::var_for_blessed_globref, 'GlobRef' ),
        'blessed_formatref' => $blessed_formatref,
        'blessed_refref'    => bless( \\$blessed_scalarref, 'RefRef' ),
        'blessed_refref_sub' => bless( \sub {}, 'RefRef' ),

        'evil_blessed_scalarref' => bless( \ do { my $x = 'evil' }, '0' ),
        'evil_blessed_scalarref_vstring' => bless( \ do { my $x = v1.2.3 }, '0' ),
        'evil_blessed_arrayref'  => bless( [], '0' ),
        'evil_blessed_hashref'   => bless( +{}, '0' ),
        'evil_blessed_coderef'   => bless( sub {'blessed_code'}, '0' ),
        #'evil_blessed_regexp'    => bless( qr{evil}, '0' ),
        'evil_blessed_globref'   => bless( \*::var_for_evil_globref, '0' ),
        'evil_blessed_formatref' => $evil_blessed_formatref,
        'evil_blessed_refref'    => bless( \\do { my $x = 'evil' }, '0' ),
        'evil_blessed_refref_sub' => bless( \sub {}, '0' ),
    );
}

my ( %plain, %blessed );
foreach my $key ( keys %all ) {
    if (!FORMAT_REFS_WORK && $key =~ /formatref/) {
        delete $all{$key};
    }
    else {
        $key =~ /^plain_/  and $plain{$key}   = $all{$key};
        $key =~ /blessed_/ and $blessed{$key} = $all{$key};
    }
}

my @all_keys     = sort keys %all;
my @plain_keys   = sort keys %plain;
my @blessed_keys = sort keys %blessed;

subtest 'non-refs' => sub {
    foreach my $value ( 0, 1, 'string', '', undef, '0', '0e0' ) {
        # better string representation for test output
        my $rep = defined $value ? $value eq '' ? q{''} : $value : '(undef)';

        for my $name (grep /^is_/, @Ref::Util::XS::EXPORT_OK) {
            next if !FORMAT_REFS_WORK && $name =~ /formatref/;
            my $func = do { no strict 'refs'; \&{"Ref::Util::XS::$name"} };
            ok( !$func->($value), "$name($rep) is false" );
        }
    }

    done_testing();
};

subtest 'plain references only work on is_plain functions' => sub {
    # each %plain should fail each test of the %blessed
    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        ok(
            !is_blessed_ref($value),
            "is_blessed_ref($plain_type) is false",
        );

        ok(
            !is_blessed_scalarref($value),
            "is_blessed_scalarref($plain_type) is false",
        );

        ok(
            !is_blessed_arrayref($value),
            "is_blessed_arrayref($plain_type) is false",
        );

        ok(
            !is_blessed_hashref($value),
            "is_blessed_hashref($plain_type) is false",
        );

        ok(
            !is_blessed_coderef($value),
            "is_blessed_coderef($plain_type) is false",
        );

        ok(
            !is_blessed_globref($value),
            "is_blessed_coderef($plain_type) is false",
        );

        ok(
            !is_blessed_formatref($value),
            "is_blessed_formatref($plain_type) is false",
        ) if FORMAT_REFS_WORK;

        ok(
            !is_blessed_refref($value),
            "is_blessed_refref($plain_type) is false",
        );
    }

    done_testing();
};

subtest 'plain references' => sub {
    # each should fail everything except their own
    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        ok(
            is_plain_ref($value),
            "is_plain_ref($plain_type) is true",
        );

        ok(
            is_ref($value),
            "is_ref($plain_type) is true",
        );

        #ok(
        #    is_any_ref($value),
        #    "is_any_ref($plain_type) is true",
        #);
    }

    # FIXME: each "is_scalarref" should also be "is_any_scalarref"
    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type =~ /plain_scalarref/ ) {
            ok(
                is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is true",
            );

            ok(
                is_scalarref($value),
                "is_scalarref($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is false",
            );

            ok(
                !is_scalarref($value),
                "is_scalarref($plain_type) is false",
            );
        }
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type eq 'plain_arrayref' ) {
            ok(
                is_plain_arrayref($value),
                "is_plain_arrayref($plain_type) is true",
            );

            ok(
                is_arrayref($value),
                "is_arrayref($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_arrayref($value),
                "is_plain_arrayref($plain_type) is false",
            );

            ok(
                !is_arrayref($value),
                "is_arrayref($plain_type) is false",
            );
        }
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type eq 'plain_hashref' ) {
            ok(
                is_plain_hashref($value),
                "is_plain_hashref($plain_type) is true",
            );

            ok(
                is_hashref($value),
                "is_hashref($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_hashref($value),
                "is_plain_hashref($plain_type) is false",
            );

            ok(
                !is_hashref($value),
                "is_hashref($plain_type) is false",
            );
        }
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type eq 'plain_coderef' ) {
            ok(
                is_plain_coderef($value),
                "is_plain_coderef($plain_type) is true",
            );

            ok(
                is_coderef($value),
                "is_coderef($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_coderef($value),
                "is_plain_coderef($plain_type) is false",
            );

            ok(
                !is_coderef($value),
                "is_coderef($plain_type) is false",
            );
        }
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type eq 'plain_globref' ) {
            ok(
                is_plain_globref($value),
                "is_plain_globref($plain_type) is true",
            );

            ok(
                is_globref($value),
                "is_globref($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_globref($value),
                "is_plain_globref($plain_type) is false",
            );

            ok(
                !is_globref($value),
                "is_globref($plain_type) is false",
            );
        }
    }

    if (FORMAT_REFS_WORK) {
        foreach my $plain_type (@plain_keys) {
            my $value = $plain{$plain_type};

            if ( $plain_type eq 'plain_formatref' ) {
                ok(
                    is_plain_formatref($value),
                    "is_plain_formatref($plain_type) is true",
                );

                ok(
                    is_formatref($value),
                    "is_formatref($plain_type) is true",
                );
            } else {
                ok(
                    !is_plain_formatref($value),
                    "is_plain_formatref($plain_type) is false",
                );

                ok(
                    !is_formatref($value),
                    "is_formatref($plain_type) is false",
                );
            }
        }
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        if ( $plain_type =~ /plain_refref/ ) {
            ok(
                is_plain_refref($value),
                "is_plain_refref($plain_type) is true",
            );

            ok(
                is_refref($value),
                "is_refref($plain_type) is true",
            );
        } else {
            ok(
                !is_plain_refref($value),
                "is_plain_refref($plain_type) is false",
            );

            ok(
                !is_refref($value),
                "is_refref($plain_type) is false",
            );
        }
    }

    done_testing();
};

subtest 'blessed references only work on is_blessed functions' => sub {
    # each %blessed should fail each test of the %plain
    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        ok(
            !is_plain_ref($value),
            "is_plain_ref($blessed_type) is false",
        );

        ok(
            !is_plain_scalarref($value),
            "is_plain_scalarref($blessed_type) is false",
        );

        ok(
            !is_plain_arrayref($value),
            "is_plain_arrayref($blessed_type) is false",
        );

        ok(
            !is_plain_hashref($value),
            "is_plain_hashref($blessed_type) is false",
        );

        ok(
            !is_plain_coderef($value),
            "is_plain_coderef($blessed_type) is false",
        );

        ok(
            !is_plain_globref($value),
            "is_plain_coderef($blessed_type) is false",
        );

        ok(
            !is_plain_formatref($value),
            "is_plain_formatref($blessed_type) is false",
        ) if FORMAT_REFS_WORK;

        ok(
            !is_plain_refref($value),
            "is_plain_refref($blessed_type) is false",
        );
    }

    done_testing();
};

subtest 'blessed references' => sub {
    # each should fail everything except their own
    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        ok(
            is_blessed_ref($value),
            "is_blessed_ref($blessed_type) is true",
        );

        ok(
            is_ref($value),
            "is_ref($blessed_type) is true",
        );

        #ok(
        #    is_any_ref($value),
        #    "is_any_ref($blessed_type) is true",
        #);
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_scalarref/ ) {
            ok(
                is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is true",
            );

            ok(
                is_scalarref($value),
                "is_scalarref($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is false",
            );

            ok(
                !is_scalarref($value),
                "is_scalarref($blessed_type) is false",
            );
        }
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_arrayref/ ) {
            ok(
                is_blessed_arrayref($value),
                "is_blessed_arrayref($blessed_type) is true",
            );

            ok(
                is_arrayref($value),
                "is_arrayref($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_arrayref($value),
                "is_blessed_arrayref($blessed_type) is false",
            );

            ok(
                !is_arrayref($value),
                "is_arrayref($blessed_type) is false",
            );
        }
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_hashref/ ) {
            ok(
                is_blessed_hashref($value),
                "is_blessed_hashref($blessed_type) is true",
            );

            ok(
                is_hashref($value),
                "is_hashref($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_hashref($value),
                "is_blessed_hashref($blessed_type) is false",
            );

            ok(
                !is_hashref($value),
                "is_hashref($blessed_type) is false",
            );
        }
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_coderef/ ) {
            ok(
                is_blessed_coderef($value),
                "is_blessed_coderef($blessed_type) is true",
            );

            ok(
                is_coderef($value),
                "is_coderef($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_coderef($value),
                "is_blessed_coderef($blessed_type) is false",
            );

            ok(
                !is_coderef($value),
                "is_coderef($blessed_type) is false",
            );
        }
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_globref/ ) {
            ok(
                is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is true",
            );

            ok(
                is_globref($value),
                "is_globref($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is false",
            );

            ok(
                !is_globref($value),
                "is_globref($blessed_type) is false",
            );
        }
    }

    if (FORMAT_REFS_WORK) {
        foreach my $blessed_type (@blessed_keys) {
            my $value = $blessed{$blessed_type};

            if ( $blessed_type =~ /blessed_formatref/ ) {
                ok(
                    is_blessed_formatref($value),
                    "is_blessed_formatref($blessed_type) is true",
                );

                ok(
                    is_formatref($value),
                    "is_formatref($blessed_type) is true",
                );
            } else {
                ok(
                    !is_blessed_formatref($value),
                    "is_blessed_formatref($blessed_type) is false",
                );

                ok(
                    !is_formatref($value),
                    "is_formatref($blessed_type) is false",
                );
            }
        }
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        if ( $blessed_type =~ /blessed_refref/ ) {
            ok(
                is_blessed_refref($value),
                "is_blessed_refref($blessed_type) is true",
            );

            ok(
                is_refref($value),
                "is_refref($blessed_type) is true",
            );
        } else {
            ok(
                !is_blessed_refref($value),
                "is_blessed_refref($blessed_type) is false",
            );

            ok(
                !is_refref($value),
                "is_refref($blessed_type) is false",
            );
        }
    }

    done_testing();
};
