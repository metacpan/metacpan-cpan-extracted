#!perl -T

use Test::More;

my $regexp_tests = [
    {
        input   => {
            regexp  => '',
        },
        output  => undef,
        message => 'empty regexp'
    },
    {
        input   => {
            regexp  => { regexp => qr/(a)(.+?)(\1)/ },
        },
        output  => undef,
        message => 'regexp is a hashref'
    },
    {
        input   => {
            regexp  => [ qr/(a)(.+?)(\1)/ ],
        },
        output  => undef,
        message => 'regexp is an arrayref'
    },
    {
        input   => {
            regexp  => qr/(a)(.+?)(\1)/,
        },
        output  => {
            regexp  => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))'
        },
        message => 'regexp is a regexp object'
    },
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
        },
        output  => {
            regexp  => '(?sm:(a)(.+?)(\1))'
        },
        message => 'regexp is a scalar'
    },
    {
        input   => {
            regexp      => qr/(a)(.+?)(\1)/,
            modifier    => 's'
        },
        output  => {
            regexp  => '(?s:(a)(.+?)(\1))'
        },
        message => 'regexp is a regexp object and modifier is set'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            modifier    => 's'
        },
        output  => {
            regexp  => '(?s:(a)(.+?)(\1))'
        },
        message => 'regexp is a scalar and modifier is set'
    },
];

my $replacement_tests = [
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
        },
        output  => {
            replacement => undef
        },
        message => 'empty replacement'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            replacement => [ 'foo' ],
        },
        output  => undef,
        message => 'replacement is an arrayref'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            replacement => { bar => 'foo' },
        },
        output  => undef,
        message => 'replacement is a hashref'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            replacement => 'foo'
        },
        output  => {
            replacement => 'foo'
        },
        message => 'replacement is a scalar'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            replacement => sub { return 'foo'; }
        },
        output  => {
            replacement => 'foo'
        },
        message => 'replacement is a coderef'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            replacement => sub { return 'foo'; },
            store       => 'bar'
        },
        output  => {
            replacement => sprintf( "\x01%d\x01", 1 )
        },
        message => 'replacement is a coderef and store is set'
    },
    {
        input   => {
            regexp          => '(a)(.+?)(\1)',
            replacement     => sub { return 'foo'; },
            store           => 'bar',
            restore_pattern => 'baz'
        },
        output  => {
            replacement     => 'foo'
        },
        message => 'replacement is a coderef and store and restore_pattern are set'
    },
];

my $store_tests = [
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
        },
        output  => {
            store => undef
        },
        message => 'store is undefined'
    },
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
            store   => '',
        },
        output  => {
            store => ''
        },
        message => 'store is empty'
    },
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
            store   => { regexp => qr/(a)(.+?)(\1)/ },
        },
        output  => undef,
        message => 'store is a hashref'
    },
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
            store  => [ qr/(a)(.+?)(\1)/ ],
        },
        output  => undef,
        message => 'store is an arrayref'
    },
    {
        input   => {
            regexp  => qr/(a)(.+?)(\1)/,
            store   => sub { return 'foo'; }
        },
        output  => {
            store   => 'foo'
        },
        message => 'store is a coderef'
    },
    {
        input   => {
            regexp  => '(a)(.+?)(\1)',
            store   => 'bar'
        },
        output  => {
            store => 'bar'
        },
        message => 'store is a scalar'
    }
];

my $modifier_tests = [
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            modifier    => { regexp => qr/(a)(.+?)(\1)/ },
        },
        output  => undef,
        message => 'modifier is a hashref'
    },
    {
        input   => {
            regexp      => '(a)(.+?)(\1)',
            modifier    => \'xsm',
        },
        output  => undef,
        message => 'modifier is a scalarref'
    },
    {
        input   => {
            regexp => '(a)(.+?)(\1)',
        },
        output  => {
            regexp => '(?sm:(a)(.+?)(\1))'
        },
        message => 'modifier is undefined and regexp is a scalar'
    },
    {
        input   => {
            regexp => qr/(a)(.+?)(\1)/,
        },
        output  => {
            regexp => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))'
        },
        message => 'modifier is undefined and regexp is a regexp object'
    },
];

my $restore_pattern_tests = [
    {
        input   => {
            regexp  => '(a)(.+?)(\1)'
        },
        output  => {
            restore_pattern => ( $] < 5.013006 ) ? '(?-xism:\x01(\d+)\x01)' : '(?^:\x01(\d+)\x01)'
        },
        message => 'restore_pattern is undefined'
    },
    {
        input   => {
            regexp          => '(a)(.+?)(\1)',
            restore_pattern => { regexp => qr/(a)(.+?)(\1)/ },
        },
        output  => undef,
        message => 'restore_pattern is a hashref'
    },
    {
        input   => {
            regexp          => '(a)(.+?)(\1)',
            restore_pattern => [ qr/(a)(.+?)(\1)/ ],
        },
        output  => undef,
        message => 'restore_pattern is an arrayref'
    },
    {
        input   => {
            regexp          => '(a)(.+?)(\1)',
            restore_pattern => qr/(a)(.+?)(\1)/,
        },
        output  => {
            restore_pattern => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))'
        },
        message => 'restore_pattern is a regexp object'
    },
    {
        input   => {
            regexp          => '(a)(.+?)(\1)',
            restore_pattern => '(a)(.+?)(\1)',
        },
        output  => {
            restore_pattern => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))'
        },
        message => 'restore_pattern is a scalar'
    },
];

SKIP: {
    my $not = 1;

    foreach ( @$regexp_tests, @$replacement_tests, @$store_tests, @$modifier_tests, @$restore_pattern_tests ) {
        $not += 1;
        $not += scalar( keys( %{$_->{output}} ) ) if ( $_->{output} );
    }

    eval( 'use Regexp::RegGrp::Data' );
    skip( 'Regexp::RegGrp::Data not installed!', $not ) if ( $@ );

    plan tests => $not;

    my $data = Regexp::RegGrp::Data->new();

    ok( ! $data, 'Regexp::RegGrp::Data->new() without args' );

    foreach my $test ( @$regexp_tests, @$store_tests, @$replacement_tests, @$modifier_tests, @$restore_pattern_tests ) {
        $data = Regexp::RegGrp::Data->new( $test->{input} );

        ok(
            ! ( $data xor $test->{output} ),
            'Data object ' . ( $test->{output} ? '' : 'not ' ) . 'created' . ( $test->{message} ? ' - ' . $test->{message} : '' )
        );

        if ( $test->{output} ) {
            foreach my $accessor ( keys( %{$test->{output}} ) ) {
                if ( defined( $test->{output}->{$accessor} ) ) {
                    if ( ref( $data->$accessor() ) eq 'CODE' ) {
                        my $args;
                        $args = { store_index => 1 } if ( $accessor eq 'replacement' );
                        cmp_ok(
                            $data->$accessor()->( $args ), 'eq', $test->{output}->{$accessor},
                            'Field "' . $accessor . '" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                        );
                    }
                    else {
                        cmp_ok(
                            $data->$accessor(), 'eq', $test->{output}->{$accessor},
                            'Field "' . $accessor . '" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                        );
                    }
                }
                else {
                    ok(
                        ! $data->$accessor(),
                        'Field "' . $accessor . '" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                    );
                }
            }
        }
    }

}
