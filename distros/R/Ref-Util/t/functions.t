use strict;
use warnings;
use Test::More;

use constant NO_FORMAT_REFS => ($] < 5.008);

my @cases;
BEGIN {
    my $blessed_glob = do {
        no warnings 'once';
        my $glob = \*FOO;
        bless $glob;
    };

    my $format = do {
        format FH1 =
.
        *FH1{FORMAT};               # this yields undef on 5.6.x
    };

    my $blessed_format = NO_FORMAT_REFS ? undef : do {
        format FH2 =
.
        my $ref = *FH2{FORMAT};
        bless $ref;
    };

    push @cases, map [@$_, +{ map +($_ => 1), split ' ', $_->[1] }], (
        [\1,                         'plain scalar'],
        [[],                         'plain array'],
        [{},                         'plain hash'],
        [sub {},                     'plain code'],
        [\*STDIN,                    'plain glob'],
        [*STDOUT{'IO'},              'io'],
        [qr/^/,                      'regexp'],
        [bless(qr/^/, 'Surprise'),   'randomly-blessed regexp'],
        [\\1,                        'plain ref'],
        [$format,                    'plain format'],

        [do { bless \(my $x = 1) },  'blessed scalar'],
        [bless([]),                  'blessed array'],
        [bless({}),                  'blessed hash'],
        [bless(sub {}),              'blessed code'],
        [$blessed_glob,              'blessed glob'],
        [do { bless \\(my $x = 1) }, 'blessed ref'],
        [$blessed_format,            'blessed format'],
    );

    plan tests => 26 * @cases + 1;  # extra one is for use_ok() above
}

BEGIN {
    use_ok('Ref::Util');

    Ref::Util->import(qw<
        is_ref
        is_scalarref
        is_arrayref
        is_hashref
        is_coderef
        is_regexpref
        is_globref
        is_formatref
        is_ioref
        is_refref
        is_plain_ref
        is_plain_scalarref
        is_plain_arrayref
        is_plain_hashref
        is_plain_coderef
        is_plain_globref
        is_plain_formatref
        is_plain_refref
        is_blessed_ref
        is_blessed_scalarref
        is_blessed_arrayref
        is_blessed_hashref
        is_blessed_coderef
        is_blessed_globref
        is_blessed_formatref
        is_blessed_refref
    >);
}

for my $case (@cases) {
  SKIP:
    {
        my ($value, $desc, $tags) = @$case;
        skip "format references do not exist before Perl 5.8.0", 26
            if NO_FORMAT_REFS && $tags->{format};

        my %got = (
            is_ref               => is_ref($value),
            is_scalarref         => is_scalarref($value),
            is_arrayref          => is_arrayref($value),
            is_hashref           => is_hashref($value),
            is_coderef           => is_coderef($value),
            is_globref           => is_globref($value),
            is_formatref         => NO_FORMAT_REFS ? 0 : is_formatref($value),
            is_ioref             => is_ioref($value),
            is_regexpref         => is_regexpref($value),
            is_refref            => is_refref($value),
            is_plain_ref         => is_plain_ref($value),
            is_plain_scalarref   => is_plain_scalarref($value),
            is_plain_arrayref    => is_plain_arrayref($value),
            is_plain_hashref     => is_plain_hashref($value),
            is_plain_coderef     => is_plain_coderef($value),
            is_plain_globref     => is_plain_globref($value),
            is_plain_formatref   => NO_FORMAT_REFS ? 0 : is_plain_formatref($value),
            is_plain_refref      => is_plain_refref($value),
            is_blessed_ref       => is_blessed_ref($value),
            is_blessed_scalarref => is_blessed_scalarref($value),
            is_blessed_arrayref  => is_blessed_arrayref($value),
            is_blessed_hashref   => is_blessed_hashref($value),
            is_blessed_coderef   => is_blessed_coderef($value),
            is_blessed_globref   => is_blessed_globref($value),
            is_blessed_formatref => NO_FORMAT_REFS ? 0 : is_blessed_formatref($value),
            is_blessed_refref    => is_blessed_refref($value),
        );

        my %expected = (
            is_ref         => 1,
            is_plain_ref   => $tags->{plain},
            is_blessed_ref => $tags->{blessed} || $tags->{regexp} || $tags->{io},
            (map +("is_${_}ref" => $tags->{$_}),
             qw<scalar array hash code glob io regexp format ref>),
            (map +("is_plain_${_}ref" => $tags->{plain} && $tags->{$_}),
             qw<scalar array hash code glob format ref>),
            (map +("is_blessed_${_}ref" => $tags->{blessed} && $tags->{$_}),
             qw<scalar array hash code glob format ref>),
        );

        die "Oops, test bug" if keys(%got) != keys(%expected);

        for my $func (sort keys %expected) {
            if ($expected{$func}) {
                ok(  $got{$func}, "$func ($desc)" );
            }
            else {
                ok( !$got{$func}, "!$func ($desc)" );
            }
        }
    }
}
