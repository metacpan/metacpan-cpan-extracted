#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'POE::Filter::JSON::Incr';

use JSON qw(to_json from_json);

my $filter = POE::Filter::JSON::Incr->new;

isa_ok( $filter, "POE::Filter::JSON::Incr" );
isa_ok( $filter, "POE::Filter" );

my $obj = { foo => 1, bar => 2 };
my $json_array = $filter->put( [ $obj, [ ] ] );

ok( $json_array, "got output from put" );

is( scalar(@$json_array), 2, "one element in output array" );
is_deeply( from_json($json_array->[0]), $obj, "json output" );
is_deeply( from_json($json_array->[1]), [], "json output" );

my $obj_array = $filter->get( $json_array );

is_deeply( $obj_array, [ { bar => 2, foo => 1 }, [] ], "json input" );

my @objs = map { @{ $filter->get($_) } } [ "[1,", "2" ], [ "]" ];

is_deeply( \@objs, [[1, 2]], "incr input" );

$filter->get_one_start(['{"fo', 'o":', '3}[', ']']);

is_deeply( $filter->get_pending, [{foo => 3}, []], "get_pending" );

is_deeply( $filter->get_one, [{foo => 3}], "inc input, get_one style" );
is_deeply( $filter->get_one, [[]], "inc input, get_one style" );
is_deeply( $filter->get_one, [], "buffer empty" );

is( $filter->get_pending, undef, "nothing pending" );

is_deeply( $filter->get([ "[", "]", "[1", "]", "foo", "{}"]), [[], [1],{}], "input errors" );

if ( $filter->meta->can("clone_object" ) ) {
	$filter->get_one_start(['{}']);
	my $clone = $filter->clone;
	isa_ok( $clone, "POE::Filter::JSON::Incr" );
	is_deeply( $clone->buffer, [], "buffer empty" );
}
