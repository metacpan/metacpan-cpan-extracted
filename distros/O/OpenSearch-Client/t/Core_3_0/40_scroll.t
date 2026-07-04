# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Test::More;
use Test::Deep;
use Test::Exception;
use lib 't/lib';

use strict;
use warnings;

plan skip_all => "Skipping Scroll Helper" unless $ENV{OS_TEST_SCROLL_HELPER};

$ENV{OS_VERSION} = '3_0';
our $es = do "os_sync.pl" or die( $@ || $! );

$es->indices->delete( index => 'test', ignore => 404 );
$es->indices->create( index => 'test' );

test_scroll(
    "No records",
    {  index => 'test' },
    total     => 0,
    max_score => undef,
    steps     => [
        is_finished   => 1,
        next          => [0],
        refill_buffer => 0,
        drain_buffer  => [0],
    ]
);

do "index_test_data_7.pl" or die( $@ || $! );

test_scroll(
    "Match all",
    { index => 'test' },
    total     => 100,
    max_score => 1,
    steps     => [
        is_finished   => '',
        buffer_size   => 10,
        next          => [1],
        drain_buffer  => [9],
        refill_buffer => 10,
        refill_buffer => 20,
        is_finished   => '',
        next_81       => [81],
        next_20       => [9],
        next          => [0],
        is_finished   => 1,
    ]
);

test_scroll(
    "Query",
    {
        index => 'test',
        body => {
            query   => { term => { color => 'red' } },
            suggest => {
                mysuggest => { text => 'green', term => { field => 'color' } }
            },
            aggs => { switch => { terms => { field => 'switch' } } },
        }
    },
    total     => 50,
    max_score => num( 1, 0.99999 ),
    aggs      => bool(1),
    suggest   => bool(1),
    steps     => [
        next        => [1],
        next_50     => [49],
        is_finished => 1,
    ]
);

test_scroll(
    "Finish",
    { index => 'test' },
    total     => 100,
    max_score => 1,
    steps     => [
        is_finished => '',
        next        => [1],
        finish      => 1,
        is_finished => 1,
        buffer_size => 0,
        next        => [0]

    ]
);

my $s = $es->scroll_helper;
my $d = $s->next;
ok ref $d && $d->{_source}, 'next() in scalar context';

{
    # Test auto finish fork protection.
    my $s = $es->scroll_helper( index => 'test', size => 5 );

    my $pid = fork();
    unless ( defined($pid) ) { die "Cannot fork. Lack of resources?"; }
    unless ($pid) {

        # Child. Call finish check that its not finished
        # (the call to finish did nothing).
        $s->finish();
        exit;
    }
    else {
        # Wait for children
        waitpid( $pid, 0 );
        is $?, 0, "Child exited without errors";
    }
    ok !$s->is_finished(), "Our Scroll is not finished";
    my $count = 0;
    while ( $s->next ) { $count++ }
    is $count, 100, "All documents retrieved";
    ok $s->is_finished, "Our scroll is finished";
}

{
    # Test Scroll usage attempt in a different process.
    my $s = $es->scroll_helper(  index => 'test', size => 5 );
    my $pid = fork();
    unless ( defined($pid) ) { die "Cannot fork. Lack of resources?"; }
    unless ($pid) {

        # Calling this next should crash, not exiting this process with 0
        eval {
            while ( $s->next ) { }
        };
        my $err = $@;
        exit( eval { $err->is('Illegal') && 123 } || 999 );
    }
    else {
        # Wait for children
        waitpid( $pid, 0 );
        is $? >> 8, 123, "Child threw Illegal exception";
    }
}

{
    # Test valid Scroll usage after initial fork
    my $pid = fork();
    unless ( defined($pid) ) { die "Cannot fork. Lack of resources?"; }
    unless ($pid) {

        my $s = $es->scroll_helper( size => 5 );

        while ( $s->next ) { }
        exit 0;
    }
    else {
        # Wait for children
        waitpid( $pid, 0 );
        is $? , 0, "Scroll completed successfully";
    }
}

done_testing;
$es->indices->delete( index => 'test' );

#===================================
sub test_scroll {
#===================================
    my ( $title, $params, %tests ) = @_;

    subtest $title => sub {
        my $s = $es->scroll_helper($params);

        is $s->total,                $tests{total},     "$title - total";
        cmp_deeply $s->max_score,    $tests{max_score}, "$title - max_score";
        cmp_deeply $s->suggest,      $tests{suggest},   "$title - suggest";
        cmp_deeply $s->aggregations, $tests{aggs},      "$title - aggs";
        my $i     = 1;
        my @steps = @{ $tests{steps} };
        while ( my $name = shift @steps ) {
            my $expect = shift @steps;
            my ( $method, $result, @p );
            if ( $name =~ /next(?:_(\d+))?/ ) {
                $method = 'next';
                @p      = $1;
            }
            else {
                $method = $name;
            }

            if ( ref $expect eq 'ARRAY' ) {
                my @result = $s->$method(@p);
                $result = 0 + @result;
                $expect = $expect->[0];
            }
            else {
                $result = $s->$method(@p);
            }

            is $result, $expect, "$title - Step $i: $name";
            $i++;
        }
        }
}

