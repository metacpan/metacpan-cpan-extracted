package Test::AssertTest;

use strict;
use warnings;

use Test::Unit::Lite;
use parent 'Test::Assert', 'Test::Unit::TestCase';

use Test::Assert ':all';

use Exception::Assertion;

use Class::Inspector;

{
    my @exports = qw(
        ASSERT
        assert_deep_equals
        assert_deep_not_equals
        assert_equals
        assert_false
        assert_isa
        assert_matches
        assert_not_equals
        assert_not_isa
        assert_not_matches
        assert_not_null
        assert_null
        assert_num_equals
        assert_num_not_equals
        assert_raises
        assert_str_equals
        assert_str_not_equals
        assert_test
        assert_true
        fail
    );

    my @exports_assert = grep { $_ ne 'fail' } @exports;

    sub test___api {
        assert_deep_equals(
            [ @exports, qw(
                import
                unimport
            ) ],
            [ grep { ! /^_/ } @{ Class::Inspector->functions('Test::Assert') } ]
        );
    };

    sub test___import_all {
        {
            package Test::AssertTest::ImportAll::Target;
            Test::Assert->import(':all');
        };
        assert_deep_equals(
            [ @exports ],
            [ sort keys %{*Test::AssertTest::ImportAll::Target::} ]
        );

        {
            package Test::AssertTest::ImportAll::Target;
            Test::Assert->unimport;
        };
        assert_deep_equals(
            [],
            [ sort keys %{*Test::AssertTest::ImportAll::Target::} ]
        );
    };

    sub test___import_assert {
        {
            package Test::AssertTest::ImportAssert::Target;
            Test::Assert->import(':assert');
        };
        assert_deep_equals(
            [ @exports_assert ],
            [ sort keys %{*Test::AssertTest::ImportAssert::Target::} ]
        );

        {
            package Test::AssertTest::ImportAssert::Target;
            Test::Assert->unimport;
        };
        assert_deep_equals(
            [],
            [ sort keys %{*Test::AssertTest::ImportAssert::Target::} ]
        );
    };
};

sub test_assert_fail {
    assert_raises( {message=>undef, reason=>undef}, sub { fail() } );
    assert_raises( {message=>undef, reason=>undef}, sub { Test::Assert->fail() } );
    assert_raises( {message=>'Message', reason=>undef}, sub { fail('Message') } );
    assert_raises( {message=>'Message', reason=>'foo'}, sub { fail('Message', 'foo') } );
};

sub test_assert_true_succeed {
    my $self = shift;
    $self->assert_true( 1 );
    Test::Assert->assert_true( 1 );
    assert_true( 1 );
    assert_true( 'string' );
};

sub test_assert_true_failed {
    assert_raises( {reason=>'Expected true value, got undef'}, sub { assert_true( undef ) } );
    assert_raises( {reason=>"Expected true value, got '0'"}, sub { assert_true( 0 ) } );
    assert_raises( {reason=>"Expected true value, got ''"}, sub { assert_true( '' ) } );
    assert_raises( {message=>'foo'}, sub { assert_true( undef, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_true() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_true( 1, 2, 3 ) }; die $@ } );
};

sub test_assert_false_succeed {
    my $self = shift;
    $self->assert_false( undef );
    Test::Assert->assert_false( undef );
    assert_false( undef );
    assert_false( 0 );
    assert_false( '' );
};

sub test_assert_false_failed {
    assert_raises( {reason=>"Expected false value, got '1'"}, sub { assert_false( 1 ) } );
    assert_raises( {reason=>"Expected false value, got 'string'"}, sub { assert_false( 'string' ) } );
    assert_raises( {message=>'foo'}, sub { assert_false( 1, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_false() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_false( 1, 2, 3 ) }; die $@ } );
};

sub test_assert_null_succeed {
    my $self = shift;
    $self->assert_null( undef );
    Test::Assert->assert_null( undef );
    assert_null( undef );
};

sub test_assert_null_failed {
    assert_raises( {reason=>"'0' is defined"}, sub { assert_null( 0 ) } );
    assert_raises( {reason=>"'1' is defined"}, sub { assert_null( 1 ) } );
    assert_raises( {reason=>"'' is defined"}, sub { assert_null( '' ) } );
    assert_raises( {reason=>"'string' is defined"}, sub { assert_null( 'string' ) } );
    assert_raises( qr/^(Exception::\w+: )?foo/, sub { assert_null( 0, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_null() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_null( 1, 2, 3 ) }; die $@ } );
};

sub test_assert_not_null_succeed {
    my $self = shift;
    $self->assert_not_null( 0 );
    Test::Assert->assert_not_null( 0 );
    assert_not_null( 0 );
    assert_not_null( 1 );
    assert_not_null( '' );
    assert_not_null( 'string' );
};

sub test_assert_not_null_failed {
    assert_raises( {reason=>'undef unexpected'}, sub { assert_not_null( undef ) } );
    assert_raises( {message=>'foo'}, sub { assert_not_null( undef, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_null() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_not_null( 1, 2, 3 ) }; die $@ } );
};

sub test_assert_equals_succeed {
    my $self = shift;
    $self->assert_equals( undef, undef );
    Test::Assert->assert_equals( undef, undef );
    assert_equals( undef, undef );
    assert_equals( 0, 0 );
    assert_equals( 0, '0' );
    assert_equals( 0, '0e0' );
    assert_equals( 1, 1 );
    assert_equals( 1, '1' );
    assert_equals( 1, '1.0' );
    assert_equals( 1E10, 1E10 );
    assert_equals( 1E10, '1E10' );
    assert_equals( 1E10, '10000000000' );
    assert_equals( '', '' );
    assert_equals( 'string', 'string' );
};

sub test_assert_equals_failed {
    assert_raises( {reason=>'Expected 1, got 0'}, sub { assert_equals( 1, 0 ) } );
    assert_raises( {reason=>'Expected 0, got 1'}, sub { assert_equals( 0, 1 ) } );
    assert_raises( {reason=>'Expected 0, got 10000000000'}, sub { assert_equals( 0, 1E10 ) } );
    assert_raises( {reason=>'Expected 10000000000, got 0'}, sub { assert_equals( 1E10, 0 ) } );
    assert_raises( {reason=>'Expected 1, got 2'}, sub { assert_equals( 1, 2 ) } );
    assert_raises( {reason=>"Expected 'string', got '1'"}, sub { assert_equals( 'string', 1 ) } );
    assert_raises( {reason=>"Expected '1', got 'string'"}, sub { assert_equals( 1, 'string' ) } );
    assert_raises( {reason=>"Expected 'string', got '0'"}, sub { assert_equals( 'string', 0 ) } );
    assert_raises( {reason=>"Expected '0', got 'string'"}, sub { assert_equals( 0, 'string' ) } );
    assert_raises( {reason=>"Expected '0', got ''"}, sub { assert_equals( 0, '' ) } );
    assert_raises( {reason=>"Expected '', got '0'"}, sub { assert_equals( '', 0 ) } );
    assert_raises( {reason=>qr/Expected value was undef/}, sub { assert_equals( undef, 0 ) } );
    assert_raises( {reason=>"Expected '0', got undef"}, sub { assert_equals( 0, undef ) } );
    assert_raises( {reason=>"Expected '0', got ''"}, sub { assert_equals( 0, '' ) } );
    assert_raises( {reason=>"Expected '', got undef"}, sub { assert_equals( '', undef ) } );
    assert_raises( {message=>'foo'}, sub { assert_equals( 1, 0, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_not_equals_succeed {
    my $self = shift;
    $self->assert_not_equals( 1, 0 );
    Test::Assert->assert_not_equals( 1, 0 );
    assert_not_equals( 1, 0 );
    assert_not_equals( 0, 1 );
    assert_not_equals( 0, 1E10 );
    assert_not_equals( 1E10, 0 );
    assert_not_equals( 1, 2 );
    assert_not_equals( 'string', 1 );
    assert_not_equals( 1, 'string' );
    assert_not_equals( 'string', 0 );
    assert_not_equals( 0,'string' );
    assert_not_equals( 0, '' );
    assert_not_equals( '', 0 );
    assert_not_equals( undef, 0 );
    assert_not_equals( 0, undef );
    assert_not_equals( 0, '' );
    assert_not_equals( undef, '' );
    assert_not_equals( '', undef );
};

sub test_assert_not_equals_failed {
    assert_raises( {reason=>'Both values were undefined'}, sub { assert_not_equals( undef, undef ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_not_equals( 0, 0 ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_not_equals( 0, '0' ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_not_equals( 0, '0.0' ) } );
    assert_raises( {reason=>'1 and 1 should differ'}, sub { assert_not_equals( 1, 1 ) } );
    assert_raises( {reason=>'1 and 1 should differ'}, sub { assert_not_equals( 1, '1' ) } );
    assert_raises( {reason=>'1 and 1 should differ'}, sub { assert_not_equals( 1, '1.0' ) } );
    assert_raises( {reason=>'10000000000 and 10000000000 should differ'}, sub { assert_not_equals( 1E10, 1E10 ) } );
    assert_raises( {reason=>'10000000000 and 10000000000 should differ'}, sub { assert_not_equals( 1E10, '1E10' ) } );
    assert_raises( {reason=>'10000000000 and 10000000000 should differ'}, sub { assert_not_equals( 1E10, '10000000000' ) } );
    assert_raises( {reason=>"'' and '' should differ"}, sub { assert_not_equals( '', '' ) } );
    assert_raises( {reason=>"'string' and 'string' should differ"}, sub { assert_not_equals( 'string', 'string' ) } );
    assert_raises( {message=>'foo'}, sub { assert_not_equals( undef, undef, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_not_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_num_equals_succeed {
    my $self = shift;
    $self->assert_num_equals( undef, undef );
    Test::Assert->assert_num_equals( undef, undef );
    assert_num_equals( undef, undef );
    assert_num_equals( 0, 0 );
    assert_num_equals( 0, '-0' );
    assert_num_equals( 1, 1 );
    assert_num_equals( 1, '1' );
    assert_num_equals( '15e7', 15e7 );
    assert_num_equals( '15e7', '15e7' );
    assert_num_equals( '15e7', '150000000' );
    assert_num_equals( '15E7', '150000000' );
    assert_num_equals( 'not 0', 0 );
    assert_num_equals( '', 0 );
    assert_num_equals( "  \n 5E2", 500 );
    assert_num_equals( "  \t 0E0  ", 0 );
    assert_num_equals( 'string', 'another string' );
};

sub test_assert_num_equals_failed {
    assert_raises( {reason=>'Expected undef, got 1'}, sub { assert_num_equals( undef, 1 ) } );
    assert_raises( {reason=>'Expected 0, got 1'}, sub { assert_num_equals( 0, 1 ) } );
    assert_raises( {reason=>'Expected 0, got undef'}, sub { assert_num_equals( 0, undef ) } );
    assert_raises( {message=>'foo'}, sub { assert_num_equals( undef, 1, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_num_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_num_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_num_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_num_not_equals_succeed {
    my $self = shift;
    $self->assert_num_not_equals( 0, 1 );
    Test::Assert->assert_num_not_equals( 0, 1 );
    assert_num_not_equals( 0, 1 );
    assert_num_not_equals( 0, undef );
    assert_num_not_equals( undef, 0 );
};

sub test_assert_num_not_equals_failed {
    assert_raises( {reason=>'Both values were undefined'}, sub { assert_num_not_equals( undef, undef ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( 0, 0 ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( 0, '-0' ) } );
    assert_raises( {reason=>'1 and 1 should differ'}, sub { assert_num_not_equals( 1, '1' ) } );
    assert_raises( {reason=>'150000000 and 150000000 should differ'}, sub { assert_num_not_equals( 15e7, '15e7' ) } );
    assert_raises( {reason=>'150000000 and 150000000 should differ'}, sub { assert_num_not_equals( '15e7', '15e7' ) } );
    assert_raises( {reason=>'150000000 and 150000000 should differ'}, sub { assert_num_not_equals( '15e7', '150000000' ) } );
    assert_raises( {reason=>'150000000 and 150000000 should differ'}, sub { assert_num_not_equals( '15E7', '150000000' ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( 'not 0', '0' ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( '', '0' ) } );
    assert_raises( {reason=>'500 and 500 should differ'}, sub { assert_num_not_equals( "  \n 5E2", '500' ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( "  \t 0E0", '0' ) } );
    assert_raises( {reason=>'0 and 0 should differ'}, sub { assert_num_not_equals( 'string', 'another string' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_num_not_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_num_not_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_num_not_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_str_equals_succeed {
    my $self = shift;
    $self->assert_str_equals( undef, undef );
    Test::Assert->assert_str_equals( undef, undef );
    assert_str_equals( undef, undef );
    assert_str_equals( '', '' );
    assert_str_equals( 0, 0 );
    assert_str_equals( 1, 1 );
    assert_str_equals( 'string', 'string' );
};

sub test_assert_str_equals_failed {
    assert_raises( {reason=>qr/Expected value was undef/}, sub { assert_str_equals( undef, 1 ) } );
    assert_raises( {reason=>"Expected '0', got '1'"}, sub { assert_str_equals( 0, 1 ) } );
    assert_raises( {reason=>"Expected '0', got undef"}, sub { assert_str_equals( 0, undef ) } );
    assert_raises( {reason=>"Expected '0', got '-0'"}, sub { assert_str_equals( 0, '-0' ) } );
    assert_raises( {reason=>"Expected '-0', got '0'"}, sub { assert_str_equals( '-0', '0' ) } );
    assert_raises( {reason=>"Expected 'foo', got 'bar'"}, sub { assert_str_equals( 'foo', 'bar' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_str_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_str_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_str_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_str_not_equals_succeed {
    my $self = shift;
    $self->assert_str_not_equals( undef, 1 );
    Test::Assert->assert_str_not_equals( undef, 1 );
    assert_str_not_equals( undef, 1 );
    assert_str_not_equals( 0, 1 );
    assert_str_not_equals( 0, undef );
    assert_str_not_equals( 0, '-0' );
    assert_str_not_equals( '-0', 0 );
    assert_str_not_equals( 'foo', 'bar' );
};

sub test_assert_str_not_equals_failed {
    assert_raises( {reason=>'Both values were undefined'}, sub { assert_str_not_equals( undef, undef ) } );
    assert_raises( {reason=>"'' and '' should differ"}, sub { assert_str_not_equals( '', '' ) } );
    assert_raises( {reason=>"'0' and '0' should differ"}, sub { assert_str_not_equals( 0, 0 ) } );
    assert_raises( {reason=>"'1' and '1' should differ"}, sub { assert_str_not_equals( 1, 1 ) } );
    assert_raises( {reason=>"'string' and 'string' should differ"}, sub { assert_str_not_equals( 'string', 'string' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_str_not_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_str_not_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_str_not_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_matches_succeed {
    my $self = shift;
    $self->assert_matches( qr/StRiNg/i, 'string');
    Test::Assert->assert_matches( qr/StRiNg/i, 'string');
    assert_matches( qr/StRiNg/i, 'string');
};

sub test_assert_matches_failed {
    assert_raises( {reason=>qr/Expected value was undef/}, sub { assert_matches( undef, undef ) } );
    assert_raises( {reason=>'Argument 1 to assert_matches() must be a regexp'}, sub { assert_matches( 1, 1 ) } );
    assert_raises( {reason=>qr/got undef/}, sub { assert_matches( qr/foo/, undef ) } );
    assert_raises( {reason=>qr/'bar' didn\'t match/}, sub { assert_matches( qr/foo/, 'bar' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_matches() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_matches( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_matches( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_not_matches_succeed {
    my $self = shift;
    $self->assert_not_matches( qr/foo/, undef );
    Test::Assert->assert_not_matches( qr/foo/, undef );
    assert_not_matches( qr/foo/, undef );
    assert_not_matches( qr/foo/, 'bar' );
};

sub test_assert_not_matches_failed {
    assert_raises( {reason=>qr/Expected value was undef/}, sub { assert_not_matches( undef, undef ) } );
    assert_raises( {reason=>'Argument 1 to assert_not_matches() must be a regexp'}, sub { assert_not_matches( 1, 1 ) } );
    assert_raises( {reason=>qr/'string' matched/}, sub { assert_not_matches( qr/string/, 'string' ) } );
    assert_raises( {message=>'foo'}, sub { assert_not_matches( undef, undef, 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_matches() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_matches( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_not_matches( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_deep_equals {
    my $self = shift;
    $self->assert_deep_equals( [], [] );
    Test::Assert->assert_deep_equals( [], [] );
    assert_deep_equals( [], [] );
    assert_deep_equals( {}, {} );
    assert_deep_equals( [ 0, 3, 5 ], [ 0, 3, 5 ] );

    my $hashref = { a => 2, b => 4 };
    assert_deep_equals( $hashref, $hashref );
    assert_deep_equals( $hashref, { b => 4, a => 2 } );

    my $complex = {
        array => [ 1, $hashref, 3 ],
        undefined => undef,
        number => 3.2,
        string => 'hi mom',
        deeper => {
            and => [
                even => [ qw< deeper wahhhhh > ],
                { foo => 11, bar => 12 }
            ],
        }
    };
    assert_deep_equals(
        $complex,
        {
            array => [ 1, $hashref, 3 ],
            undefined => undef,
            number => 3.2,
            string => 'hi mom',
            deeper => {
                and => [
                    even => [ qw< deeper wahhhhh > ],
                    {
                        foo => 11, bar => 12 }
                ],
            },
        }
    );

    my %families;
    foreach my $key (qw< orig copy bad_copy >) {
        my %family = ( john => { name => 'John Doe',
                                 spouse => undef,
                                 children => [],
                               },
                       jane => { name   => 'Jane Doe',
                                 spouse => undef,
                                 children => [],
                               },
                       baby => { name => 'Baby Doll',
                                 spouse => undef,
                                 children => [],
                               },
                     );
        $family{john}{spouse} = $family{jane};
        $family{jane}{spouse} = $family{john};
        push @{$family{john}{children}}, $family{baby};
        push @{$family{jane}{children}}, $family{baby};
        $families{$key} = \%family;
    }
    $families{bad_copy}->{jane}{spouse} = $families{bad_copy}->{baby};

    # Breakage under test is infinite recursion, to memory exhaustion!
    # Jump through hoops to avoid killing people's boxes
    {
        my $old_isa = \&UNIVERSAL::isa;
        # Pick on isa() because it'll be called from any deep-ing code
        local $^W = 0;
        no warnings 'redefine';
        local *UNIVERSAL::isa = sub {
            die "Giving up on deep recursion for assert_deep_equals"
              if defined caller(500);
            return $old_isa->(@_);
        };
        assert_deep_equals( $families{orig}, $families{copy} );
    }

    my ($H, $H2, $G) = qw< hello hello goodbye >;

    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_equals( undef, 0 ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_equals( 0, undef ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_equals( 0, 1 ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_equals( 0, '' ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_equals( '', 0 ) } );
    assert_raises( {reason=>qr/must be a reference/},
                   sub { assert_deep_equals( 0, [] ) } );
    assert_raises( {reason=>qr/must be a reference/},
                   sub { assert_deep_equals( [], 0 ) } );
    assert_raises( {reason=>qr/'ARRAY.0x\w+.'\n/}, sub { assert_deep_equals( [], {} ) } );
    assert_raises( {reason=>qr/'ARRAY.0x\w+.'\n/}, sub { assert_deep_equals( [1,2], {1,2} ) } );
    assert_raises( {reason=>qr/'ARRAY.0x\w+.'\n/}, sub { assert_deep_equals(  { 'test' => [] },
                                                           { 'test' => undef } ) } );
    assert_raises( {reason=>qr/'ARRAY.0x\w+.'\n/}, sub { assert_deep_equals( { 'test' => []}, {} ) } );
    assert_raises( {reason=>qr/undef\n/}, sub { assert_deep_equals( { 'test' => undef },
                                                           { 'test' => []} ) } );
    assert_raises( {reason=>qr/''\n/}, sub { assert_deep_equals( [ '' ], [ undef ] ) } );
    assert_raises( {reason=>qr/'undef'\n/}, sub { assert_deep_equals( [ 'undef' ], [ undef ] ) } );
    assert_raises( {reason=>qr/Does not exist\n/}, sub { assert_deep_equals( [1,2], [1,2,3] ) } );
    assert_raises( {reason=>qr/'3'\n/}, sub { assert_deep_equals( [1,2,3], [1,2] ) } );
    assert_raises( {reason=>qr/'wahhhhh'\n/}, sub { assert_deep_equals(
            $complex,
            {
                array => [ 1, $hashref, 3 ],
                undefined => undef,
                number => 3.2,
                string => 'hi mom',
                deeper => {
                    and => [
                        even => [ qw< deeper wahhhh > ],
                        { foo => 11, bar => 12 }
                    ],
                },
            }
    ) } );
    assert_raises( {reason=>qr/Structures begin differing/},
                   sub { assert_deep_equals( $families{orig}, $families{bad_copy} ) } );
    assert_raises( {reason=>qr/'3'\n/}, sub { assert_deep_equals( [ \$H, 3 ], [ \$H2, 5 ] ) } );
    assert_raises( {reason=>qr/'hello'\n/}, sub { assert_deep_equals( { world => \$H }, { world => \$G } ) } );
    assert_raises( {reason=>qr/'hello'\n/}, sub { assert_deep_equals( [ \$H, "world" ], [ \$G, "world" ] ) } );
    assert_raises( {message=>'foo'}, sub { assert_deep_equals( [1], [2], 'foo' ) } );
    assert_raises( qr/Not enough arguments/, sub { eval q{ assert_deep_equals() }; die $@ } );
    assert_raises( qr/Not enough arguments/, sub { eval q{ assert_deep_equals( 1 ) }; die $@ } );
    assert_raises( qr/Too many arguments/, sub { eval q{ assert_deep_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_deep_not_equals {
    my $self = shift;
    $self->assert_deep_not_equals( {1, 2}, {1, 3} );
    Test::Assert->assert_deep_not_equals( {1, 2}, {1, 3} );
    assert_deep_not_equals( {1, 2}, {1, 3} );
    assert_deep_not_equals( {1, [2, 3]}, {1, [2, 4]} );
    assert_deep_not_equals( {1, [2, {3, 4} ] }, {1, [2, {3, 5} ] } );
    assert_deep_not_equals( {1, [2, {3, {4, 5} } ] }, {1, [2, {3, {4, 6} } ] } );

    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_not_equals( undef, undef ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_not_equals( undef, 0 ) } );
    assert_raises( {reason=>'Both arguments were not references'},
                   sub { assert_deep_not_equals( 0, undef ) } );
    assert_raises( {reason=>qr/must be a reference/},
                   sub { assert_deep_not_equals( 0, [] ) } );
    assert_raises( {reason=>qr/must be a reference/},
                   sub { assert_deep_not_equals( [], 0 ) } );

    assert_raises( {reason=>'Both structures should differ'}, sub { assert_deep_not_equals( [ 1 ], [ 1 ] ) } );
    assert_raises( {reason=>'Both structures should differ'}, sub { assert_deep_not_equals( [], [] ) } );
    assert_raises( {reason=>'Both structures should differ'}, sub { assert_deep_not_equals( {}, {} ) } );
    assert_raises( {message=>'foo'}, sub { assert_deep_not_equals( [1], [1], 'foo' ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_deep_not_equals() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_deep_not_equals( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_deep_not_equals( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_isa_succeed {
    my $self = shift;
    $self->assert_isa( 'Test::Unit::TestCase', $self );
    Test::Assert->assert_isa( 'Test::Unit::TestCase', $self );
    assert_isa( 'Test::Unit::TestCase', $self );
    assert_isa( 'Test::Unit::TestCase', 'Test::Unit::TestCase' );
};

sub test_assert_isa_failed {
    my $self = shift;
    assert_raises( {reason=>qr/Class name was undef/}, sub { assert_isa( undef, undef ) } );
    assert_raises( {reason=>qr/got undef/}, sub { assert_isa( 'X', undef ) } );
    assert_raises( {reason=>qr/got 'Y' value/}, sub { assert_isa( 'X', 'Y' ) } );
    assert_raises( {reason=>qr/got 'Test::AssertTest' reference/}, sub { assert_isa( 'X', $self ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_isa() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_isa( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_isa( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_not_isa_succeed {
    my $self = shift;
    $self->assert_not_isa( 'X', $self );
    assert_not_isa( 'X', undef );
    assert_not_isa( 'X', 'Y' );
    assert_not_isa( 'X', $self );
};

sub test_assert_not_isa_failed {
    my $self = shift;
    assert_raises( {reason=>qr/Class name was undef/}, sub { assert_not_isa( undef, undef ) } );
    assert_raises( {reason=>qr/is a 'Test::Unit::TestCase' object or class/}, sub { assert_not_isa( 'Test::Unit::TestCase', 'Test::Unit::TestCase' ) } );
    assert_raises( {reason=>qr/is a 'Test::Unit::TestCase' object or class/}, sub { assert_not_isa( 'Test::Unit::TestCase', $self ) } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_isa() }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_not_isa( 1 ) }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_not_isa( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_raises_succeed {
    my $self = shift;
    $self->assert_raises( qr/^(Exception::\w+: )?string/, sub { die 'string' } );
    Test::Assert->assert_raises( qr/^(Exception::\w+: )?string/, sub { die 'string' } );
    assert_raises( 'string', sub { die 'string' } );
    assert_raises( qr/^(Exception::\w+: )?string/, sub { die 'string' } );
    assert_raises( ['Exception::Base'], sub { Exception::Base->throw } );
    assert_raises( {message=>'message'}, sub { Exception::Base->throw(message=>'message') } );
    assert_raises( ['Test::AssertTest::Test1'], sub { die bless {} => 'Test::AssertTest::Test1' } );
};

sub test_assert_raises_failed {
    assert_raises( {reason=>'Expected exception was not raised'}, sub { eval q{
        assert_raises( qr/string/, sub { } )
    }; die $@ } );
    assert_raises( {message=>'foo'}, sub { eval q{
        assert_raises( qr/string/, sub { }, 'foo' )
    }; die $@ } );
    assert_raises( 'foo', sub { eval q{
        assert_raises( 'bar', sub { die 'foo' } )
    }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?foo/, sub { eval q{
        assert_raises( qr/[b]ar/, sub { die 'foo' } )
    }; die $@ } );
    assert_raises( qr/^(Exception::\w+: )?foo/, sub { eval q{
        assert_raises( 'bar', sub { die 'foo' } )
    }; die $@ } );
    assert_raises( {message=>'foo'}, sub { eval q{
        assert_raises( ['NoSuchClass'], sub { Exception::Base->throw(message=>'foo') } )
    }; die $@ } );
    assert_raises( ['Test::AssertTest::Test1'], sub { eval q{
        assert_raises( ['NoSuchClass'], sub { die bless {} => 'Test::AssertTest::Test1' } )
    }; die $@ } );
    assert_raises( qr/(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_raises() }; die $@ } );
    assert_raises( qr/(Exception::\w+: )?Not enough arguments/, sub { eval q{ assert_raises( 1 ) }; die $@ } );
    assert_raises( qr/(Exception::\w+: )?Too many arguments/, sub { eval q{ assert_raises( 1, 2, 3, 4 ) }; die $@ } );
};

sub test_assert_test {
    my $self = shift;

    # This test is optional
    eval {
        require Test::More;
        Test::More->import( ['!fail'] );
        require Test::Builder;
    };
    return if $@;

    Test::Builder->new->no_plan;
    Test::Builder->new->no_ending(1);

    $self->assert_test( sub { ok(1) } );
    Test::Assert->assert_test( sub { ok(1) } );
    assert_test( sub { ok(1) } );

    assert_raises( {reason=>'assert_test failed'}, sub {
        assert_test( sub { ok(0) } )
    } );
    assert_raises( {message=>'foo'}, sub {
        assert_test( sub { ok(0) }, 'foo' )
    } );
    assert_raises( {message=>'foo'}, sub {
        assert_test( sub { ok(0, 'foo') } )
    } );
    assert_raises( {message=>"\nfoo\nbar"}, sub {
        assert_test( sub { ok(0, "foo\nbar") } )
    } );
};

1;
