#!perl
use lib qw( t/lib );
use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Spec;
use Data::Dumper;
use Storable qw( dclone );
use DeepStuff;
use TAP::Parser::Aggregator;

use TAP::Filter qw( FakeFilter Iterator );
use TAP::Filter::Iterator;

my @cases = (
    {
        class            => 'TAP::Harness',
        files            => ['a_test.tt'],
        aggregate_expect => {
            total        => 3,
            has_problems => bool( 0 ),
            passed       => 3,
            failed       => 0,
        },
    },
    {
        class            => 'TAP::Filter',
        files            => ['a_test.tt'],
        aggregate_expect => {
            total        => 4,
            has_problems => bool( 0 ),
            passed       => 4,
            failed       => 0,
        },
        closure_filter_expect => [
            ['init'],
            [ 'inspect', is_plan( 3 ) ],
            [ 'inspect', is_test( 1, 'one',   1 ) ],
            [ 'inspect', is_test( 2, 'two',   1 ) ],
            [ 'inspect', is_test( 3, 'three', 1 ) ],
            ['done'],
        ],
        fake_filter_expect => [
            ['FakeFilter::init'],
            [ 'FakeFilter::inspect', is_plan( 3 ) ],
            [ 'FakeFilter::inspect', is_test( 1, 'one',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 2, 'two',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 3, 'two',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 4, 'three', 1 ) ],
            ['FakeFilter::done'],
        ],
    },
    {
        class            => 'TAP::Filter',
        files            => [ 'a_test.tt', 'b_test.tt' ],
        aggregate_expect => {
            total        => 10,
            has_problems => bool( 0 ),
            passed       => 10,
            failed       => 0,
        },
        closure_filter_expect => [
            ['init'],
            [ 'inspect', is_plan( 3 ) ],
            [ 'inspect', is_test( 1, 'one',   1 ) ],
            [ 'inspect', is_test( 2, 'two',   1 ) ],
            [ 'inspect', is_test( 3, 'three', 1 ) ],
            ['done'],
            ['init'],
            [ 'inspect', is_plan( 4 ) ],
            [ 'inspect', is_test( 1, 'not two',       1 ) ],
            [ 'inspect', is_test( 2, 'not one',       1 ) ],
            [ 'inspect', is_test( 3, 'three',         1 ) ],
            [ 'inspect', is_test( 4, 'still not two', 1 ) ],
            ['done'],
        ],
        fake_filter_expect => [
            ['FakeFilter::init'],
            [ 'FakeFilter::inspect', is_plan( 3 ) ],
            [ 'FakeFilter::inspect', is_test( 1, 'one',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 2, 'two',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 3, 'two',   1 ) ],
            [ 'FakeFilter::inspect', is_test( 4, 'three', 1 ) ],
            ['FakeFilter::done'],
            ['FakeFilter::init'],
            [ 'FakeFilter::inspect', is_plan( 4 ) ],
            [ 'FakeFilter::inspect', is_test( 1, 'not two',       1 ) ],
            [ 'FakeFilter::inspect', is_test( 2, 'not two',       1 ) ],
            [ 'FakeFilter::inspect', is_test( 3, 'not one',       1 ) ],
            [ 'FakeFilter::inspect', is_test( 4, 'three',         1 ) ],
            [ 'FakeFilter::inspect', is_test( 5, 'still not two', 1 ) ],
            [ 'FakeFilter::inspect', is_test( 6, 'still not two', 1 ) ],
            ['FakeFilter::done'],
        ],
    },
);

plan tests => @cases * 3 + 2;

cmp_deeply [ TAP::Filter->get_filters ],
  [
    all( isa( 'FakeFilter' ), isa( 'TAP::Filter::Iterator' ) ),
    all( isa( 'TAP::Filter::Iterator' ) ),
  ],
  "FakeFilter, Iterator loaded";

{
    my @filter_log = ();

    sub get_log { splice @filter_log }
    sub record { push @filter_log, [@_] }

    TAP::Filter->add_filter(
        TAP::Filter::Iterator->new(
            sub {
                record( inspect => @_ );
                my $tok = shift;
                if ( $tok->is_test && $tok->description =~ /two/ ) {
                    return ( dclone $tok, dclone $tok );
                }
                return dclone $tok;
            },
            sub {
                record( init => @_ );
            },
            sub {
                record( done => @_ );
            },
        )
    );
}

cmp_deeply [ TAP::Filter->get_filters ],
  [
    all( isa( 'FakeFilter' ), isa( 'TAP::Filter::Iterator' ) ),
    all( isa( 'TAP::Filter::Iterator' ) ),
    all( isa( 'TAP::Filter::Iterator' ) ),
  ],
  "another Iterator added";

my $fake_filter = ( TAP::Filter->get_filters )[0];

for my $case ( @cases ) {
    my $class = $case->{class};
    my $harness = $class->new( { verbosity => -9 } );

    my @files = @{ $case->{files} || [] };
    my $name = "$class (" . join( ', ', @files ) . ")";

    my $aggregate = TAP::Parser::Aggregator->new;
    $aggregate->start;
    $harness->aggregate_tests( $aggregate,
        map { File::Spec->catfile( 't', $_ ) } @files );
    $aggregate->stop;

    unless (
        cmp_deeply $aggregate,
        methods( %{ $case->{aggregate_expect} || {} } ),
        "$name: aggregate"
      ) {
        diag Dumper( $aggregate )
          if $ENV{TEST_VERBOSE};
    }

    unless ( cmp_deeply my $log = [ $fake_filter->get_log ],
        $case->{fake_filter_expect} || [], "$name: fake filter log" ) {
        diag Dumper( $log )
          if $ENV{TEST_VERBOSE};
    }

    unless ( cmp_deeply my $log = [ get_log() ],
        $case->{closure_filter_expect} || [],
        "$name: closure filter log" ) {
        diag Dumper( $log )
          if $ENV{TEST_VERBOSE};
    }
}
