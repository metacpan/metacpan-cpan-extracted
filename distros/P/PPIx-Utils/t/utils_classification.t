# Tests from Perl::Critic::Utils t/05_utils.t

use strict;
use warnings;

use Carp 'confess';
use PPI::Document;
use PPIx::Utils::Classification ':all';
use Test::More;

test_is_assignment_operator();
test_is_hash_key();
test_is_perl_builtin();
test_is_perl_global();
test_is_subroutine_name();
test_is_function_call();
test_is_unchecked_call();

sub make_doc {
    my $code = shift;
    return PPI::Document->new(ref $code ? $code : \$code);
}

sub test_is_assignment_operator {
    for ( qw( = **= += -= .= *= /= %= x= &= |= ^= <<= >>= &&= ||= //= ) ) {
        is( is_assignment_operator($_), 1, "$_ is an assignment operator" );
    }

    for ( qw( == != =~ >= <= + - * / % x bogus= ) ) {
        is( !!is_assignment_operator($_), q{}, "$_ is not an assignment operator" );
    }

    return;
}

sub test_is_hash_key {
    my $code = 'sub foo { return $h1{bar}, $h2->{baz}, $h3->{ nuts() } }';
    my $doc = PPI::Document->new(\$code);
    my @words = @{$doc->find('PPI::Token::Word')};
    my @expect = (
        ['sub', undef],
        ['foo', undef],
        ['return', undef],
        ['bar', 1],
        ['baz', 1],
        ['nuts', undef],
    );
    is(scalar @words, scalar @expect, 'is_hash_key count');

    for my $i (0 .. $#expect) {
        is($words[$i], $expect[$i][0], 'is_hash_key word');
        is( !!is_hash_key($words[$i]), !!$expect[$i][1], 'is_hash_key boolean' );
    }

    return;
}

sub test_is_perl_builtin {
    ok(  is_perl_builtin('print'),  'Is perl builtin function'     );
    ok( !is_perl_builtin('foobar'), 'Is not perl builtin function' );

    my $code = 'sub print {}';
    my $doc = make_doc( $code );
    my $sub = $doc->find_first('Statement::Sub');
    ok( is_perl_builtin($sub), 'Is perl builtin function (PPI)' );

    $code = 'sub foobar {}';
    $doc = make_doc( $code );
    $sub = $doc->find_first('Statement::Sub');
    ok( !is_perl_builtin($sub), 'Is not perl builtin function (PPI)' );

    return;
}

sub test_is_perl_global {
    ok(  is_perl_global('$OSNAME'), '$OSNAME is a perl global var'     );
    ok(  is_perl_global('*STDOUT'), '*STDOUT is a perl global var'     );
    ok( !is_perl_global('%FOOBAR'), '%FOOBAR is a not perl global var' );

    my $code = '$OSNAME';
    my $doc  = make_doc($code);
    my $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), '$OSNAME is perl a global var (PPI)' );

    $code = '*STDOUT';
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), '*STDOUT is perl a global var (PPI)' );

    $code = '%FOOBAR';
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( !is_perl_global($var), '%FOOBAR is not a perl global var (PPI)' );

    $code = q[$\\];
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), "$code is a perl global var (PPI)" );

    return;
}

sub test_is_subroutine_name {
    my $code = 'sub foo {}';
    my $doc  = make_doc( $code );
    my $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    ok( is_subroutine_name( $word ), 'Is a subroutine name');

    $code = '$bar = foo()';
    $doc  = make_doc( $code );
    $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    ok( !is_subroutine_name( $word ), 'Is not a subroutine name');

    return;
}

sub test_is_function_call {
    my $code = 'sub foo{}';
    my $doc = PPI::Document->new( \$code );
    my $words = $doc->find('PPI::Token::Word');
    is(scalar @{$words}, 2, 'count PPI::Token::Words');
    is((scalar grep {is_function_call($_)} @{$words}), 0, 'is_function_call');

    return;
}

sub test_is_unchecked_call {
    my @trials = (
        # just an obvious failure to check the return value
        {
            code => q[ open( $fh, $mode, $filename ); ],
            pass => 1,
        },
        # check the value with a trailing conditional
        {
            code => q[ open( $fh, $mode, $filename ) or confess 'unable to open'; ],
            pass => 0,
        },
        # assign the return value to a variable (and assume that it's checked later)
        {
            code => q[ my $error = open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        # the system call is in a conditional
        {
            code => q[ return $EMPTY if not open my $fh, '<', $file; ],
            pass => 0,
        },
        # open call in list context, checked with 'not'
        {
            code => q[ return $EMPTY if not ( open my $fh, '<', $file ); ],
            pass => 0,
        },
        # just putting the system call in a list context doesn't mean the return value is checked
        {
            code => q[ ( open my $fh, '<', $file ); ],
            pass => 1,
        },

        # Check Fatal.
        {
            code => q[ use Fatal qw< open >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use Fatal qw< open >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },

        # Check Fatal::Exception.
        {
            code => q[ use Fatal::Exception 'Exception::System' => qw< open close >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use Fatal::Exception 'Exception::System' => qw< open close >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },

        # Check autodie.
        {
            code => q[ use autodie; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use autodie qw< :io >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use autodie qw< :system >; ( open my $fh, '<', $file ); ],
            pass => 1,
        },
        {
            code => q[ use autodie qw< :system :file >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },
    );

    foreach my $trial ( @trials ) {
        my $code = $trial->{'code'};
        my $doc = make_doc( $code );
        my $statement = $doc->find_first( sub { $_[1] eq 'open' } );
        if ( $trial->{'pass'} ) {
            ok( is_unchecked_call( $statement ), qq<is_unchecked_call returns true for "$code".> );
        } else {
            ok( ! is_unchecked_call( $statement ), qq<is_unchecked_call returns false for "$code".> );
        }
    }

    return;
}

# Tests from Perl::Critic::Utils::PPI t/05_utils_ppi.t

use PPI::Document qw< >;
use PPI::Statement::Break qw< >;
use PPI::Statement::Compound qw< >;
use PPI::Statement::Data qw< >;
use PPI::Statement::End qw< >;
use PPI::Statement::Expression qw< >;
use PPI::Statement::Include qw< >;
use PPI::Statement::Null qw< >;
use PPI::Statement::Package qw< >;
use PPI::Statement::Scheduled qw< >;
use PPI::Statement::Sub qw< >;
use PPI::Statement::Unknown qw< >;
use PPI::Statement::UnmatchedBrace qw< >;
use PPI::Statement::Variable qw< >;
use PPI::Statement qw< >;
use PPI::Token::Word qw< >;

my @ppi_statement_classes = qw{
    PPI::Statement
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
            PPI::Statement::Scheduled
        PPI::Statement::Compound
        PPI::Statement::Break
        PPI::Statement::Data
        PPI::Statement::End
        PPI::Statement::Expression
            PPI::Statement::Variable
        PPI::Statement::Null
        PPI::Statement::UnmatchedBrace
        PPI::Statement::Unknown
};

my %instances = map { $_ => $_->new() } @ppi_statement_classes;
$instances{'PPI::Token::Word'} = PPI::Token::Word->new('foo');

#-----------------------------------------------------------------------------
#  is_ppi_expression_or_generic_statement tests

{
    ok(
        ! is_ppi_expression_or_generic_statement( undef ),
        'is_ppi_expression_or_generic_statement( undef )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_expression_or_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::End )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_generic_statement tests

{
    ok(
        ! is_ppi_generic_statement( undef ),
        'is_ppi_generic_statement( undef )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_generic_statement( PPI::Statement::End )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_statement_subclass tests

{
    ok(
        ! is_ppi_statement_subclass( undef ),
        'is_ppi_statement_subclass( undef )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Token::Word'} ),
        'is_ppi_statement_subclass( PPI::Token::Word )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Statement'} ),
        'is_ppi_statement_subclass( PPI::Statement )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Package'} ),
        'is_ppi_statement_subclass( PPI::Statement::Package )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Include'} ),
        'is_ppi_statement_subclass( PPI::Statement::Include )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_statement_subclass( PPI::Statement::Sub )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_statement_subclass( PPI::Statement::Scheduled )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_statement_subclass( PPI::Statement::Compound )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Break'} ),
        'is_ppi_statement_subclass( PPI::Statement::Break )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Data'} ),
        'is_ppi_statement_subclass( PPI::Statement::Data )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::End'} ),
        'is_ppi_statement_subclass( PPI::Statement::End )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_statement_subclass( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_statement_subclass( PPI::Statement::Variable )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Null'} ),
        'is_ppi_statement_subclass( PPI::Statement::Null )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_statement_subclass( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_statement_subclass( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_subroutine_declaration() tests

{
    my $test = sub {
        my ($code, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $doc->first_element();
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            ! ! is_subroutine_declaration( $input ),
            ! ! $result,
            "is_subroutine_declaration(): $name"
        );

        return;
    };

    $test->('sub {};'        => 1);
    $test->('sub {}'         => 1);
    $test->('{}'             => 0);
    $test->(undef,              0);
    $test->('{ sub foo {} }' => 0);
    $test->('sub foo;'       => 1);
}

#-----------------------------------------------------------------------------
#  is_in_subroutine() tests

{
    my $test = sub {
        my ($code, $transform, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $transform->($doc);
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            ! ! is_in_subroutine( $input ),
            ! ! $result,
            "is_in_subroutine(): $name"
        );

        return;
    };

    $test->(undef, sub {}, 0);

    $test->('my $foo = 42', sub {}, 0);

    $test->(
        'sub foo { my $foo = 42 }',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        'sub { my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        '{ my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        0,
    );
}

done_testing;
