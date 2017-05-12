#!perl
use lib qw( t/lib );
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Storable qw( dclone );
use TAP::Parser;
use TAP::Parser::Result;
use TAP::Filter;
use TAP::Filter::Iterator;

# Default values to expect per result type. Overridden by specific
# expect specs in the schedule.
my %default_expect = (
    test => {
        directive    => '',
        explanation  => '',
        is_unplanned => bool( 0 ),
        is_ok        => bool( 1 ),
        is_actual_ok => bool( 1 ),
        todo_passed  => bool( 0 ),
        has_skip     => bool( 0 ),
        has_todo     => bool( 0 ),
    },
);

my %default_parser = (
    is_good_plan  => bool( 1 ),
    has_problems  => bool( 0 ),
    version       => 12,
    parse_errors  => 0,
    passed        => 0,
    failed        => 0,
    tests_planned => 0,
);

# Test schedule
my @cases = (
    {
        name   => 'Pass through',
        input  => [ '1..2', 'ok 1 - one', 'ok 2 - two', ],
        expect => [
            plan => { tests_planned => 2 },
            test => { description   => '- one', number => 1 },
            test => { description   => '- two', number => 2 },
        ],
        parser => { tests_planned => 2, passed => 2, },
    },
    {
        name => 'Pass through TAP 13',
        input =>
          [ 'TAP Version 13', '1..2', 'ok 1 - one', 'ok 2 - two', ],
        expect => [
            version => { version       => 13 },
            plan    => { tests_planned => 2 },
            test    => { description   => '- one', number => 1 },
            test    => { description   => '- two', number => 2 },
        ],
        parser => { tests_planned => 2, passed => 2, version => 13, },
    },
    {
        name => 'Double',
        input =>
          [ '1..3', 'ok 1 - one', 'not ok 2 - two', 'ok 3 - three' ],
        filters => [
            sub {
                my $result = shift;
                return $result->is_test
                  ? ( dclone $result, dclone $result )
                  : ( $result );
              }
        ],
        expect => [
            plan => { tests_planned => 3 },
            test => { description   => '- one', number => 1 },
            test => { description   => '- one', number => 2 },
            test => {
                description  => '- two',
                number       => 3,
                is_ok        => bool( 0 ),
                is_actual_ok => bool( 0 ),
            },
            test => {
                description  => '- two',
                number       => 4,
                is_ok        => bool( 0 ),
                is_actual_ok => bool( 0 ),
            },
            test => { description => '- three', number => 5 },
            test => { description => '- three', number => 6 },
        ],
        parser => {
            tests_planned => 6,
            passed        => 4,
            failed        => 2,
            has_problems  => 2
        },
    },
    {
        name => 'Double, trailing plan',
        input =>
          [ 'ok 1 - one', 'not ok 2 - two', 'ok 3 - three', '1..3', ],
        filters => [
            sub {
                my $result = shift;
                return $result->is_test
                  ? ( dclone $result, dclone $result )
                  : ( $result );
              }
        ],
        expect => [
            test => { description => '- one', number => 1 },
            test => { description => '- one', number => 2 },
            test => {
                description  => '- two',
                number       => 3,
                is_ok        => bool( 0 ),
                is_actual_ok => bool( 0 ),
            },
            test => {
                description  => '- two',
                number       => 4,
                is_ok        => bool( 0 ),
                is_actual_ok => bool( 0 ),
            },
            test => { description   => '- three', number => 5 },
            test => { description   => '- three', number => 6 },
            plan => { tests_planned => 6 },
        ],
        parser => {
            tests_planned => 6,
            passed        => 4,
            failed        => 2,
            has_problems  => 2
        },
    },
    {
        name  => 'Delete some',
        input => [
            '1..4',
            'ok 1 - one',
            'ok 2 - DELETE',
            'ok 3 - three',
            'ok 4 - DELETE',
        ],
        filters => [
            sub {
                my $result = shift;
                return $result unless $result->is_test;
                my $desc = $result->description;
                return if $desc =~ /DELETE/;
                return $result;
              }
        ],
        expect => [
            plan => { tests_planned => 4 },
            test => { description   => '- one', number => 1 },
            test => { description   => '- three', number => 2 },
        ],
        parser => {
            tests_planned => 2,
            passed        => 2,
        },
    },
    {
        name  => 'Delete more',
        input => [
            '1..4',
            'ok 1 - one',
            'ok 2 - DELETE',
            'ok 3 - DELETE',
            'ok 4 - DELETE',
        ],
        filters => [
            sub {
                my $result = shift;
                return $result unless $result->is_test;
                my $desc = $result->description;
                return if $desc =~ /DELETE/;
                return $result;
              }
        ],
        expect => [
            plan => { tests_planned => 4 },
            test => { description   => '- one', number => 1 },
        ],
        parser => {
            tests_planned => 1,
            passed        => 1,
        },
    },
    {
        name    => 'Missing description',
        input   => [ '1..3', 'ok 1 - one', 'ok 2', 'ok 3 - three', ],
        filters => [
            sub {
                my $result = shift;
                return $result unless $result->is_test;
                my $desc = $result->description;
                return $result if defined $desc && $desc =~ /\S/;
                return (
                    $result,
                    TAP::Filter::Iterator->ok(
                        ok          => 0,
                        description => 'Missing test description'
                    )
                );
              }
        ],
        expect => [
            plan => { tests_planned => 3 },
            test => { description   => '- one', number => 1 },
            test => { description   => '', number => 2 },
            test => {
                description  => '- Missing test description',
                number       => 3,
                is_ok        => bool( 0 ),
                is_actual_ok => bool( 0 ),
                raw          => 'not ok 3 - Missing test description',
            },
            test => {
                description => '- three',
                number      => 4,
                raw         => 'ok 4 - three'
            },
        ],
        parser => {
            tests_planned => 4,
            passed        => 3,
            failed        => 1,
            has_problems  => 1,
        },
    },
);

plan tests => @cases * 2;

for my $case ( @cases ) {
    my $name = $case->{name};
    my $parser = TAP::Parser->new( { source => $case->{input} } );
    for my $filter ( @{ $case->{filters} || [] } ) {
        TAP::Filter::Iterator->new(
            'ARRAY' eq ref $filter ? @$filter : $filter )
          ->add_to_parser( $parser );
    }
    my @results = ();
    while ( defined( my $result = $parser->next ) ) {
        push @results, $result;
    }
    unless (
        logand(
            cmp_deeply(
                \@results,
                results_assertion( @{ $case->{expect} || [] } ),
                "$name: results"
            ),
            cmp_deeply(
                $parser,
                parser_assertion( $case->{parser} || {} ),
                "$name: parser"
            )
        )
      ) {
        diag Dumper( { results => \@results, parser => $parser } )
          if $ENV{TEST_VERBOSE};
    }
}

# Not short-circuiting and
sub logand { !scalar grep !$_, @_ }

sub merge_defaults {
    my ( $type, $want ) = @_;
    return { %{ $default_expect{$type} || {} }, %$want };
}

sub item_assertion {
    my $type = shift;
    my $want = merge_defaults( $type, shift );
    return all( isa( 'TAP::Parser::Result' ),
        methods( %$want, "is_$type" => bool( 1 ) ) );
}

sub results_assertion {
    my @want = @_;
    my @test = ();
    while ( my ( $type, $want ) = splice @want, 0, 2 ) {
        push @test, item_assertion( $type, $want );
    }
    return \@test;
}

sub parser_assertion {
    my $want = { %default_parser, %{ shift() } };
    return all( isa( 'TAP::Parser' ), methods( %$want ) );
}
