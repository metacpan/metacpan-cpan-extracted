#!/usr/bin/env perl

use strict;
use warnings;
use Data::Compare;
use Data::Dumper;
use OPTIMADE::Filter::Modifiable;
use OPTIMADE::Filter::Parser;
use Scalar::Util qw(blessed);
use Test::More tests => 1;

$Data::Dumper::Sortkeys = 1;

my $parser = new OPTIMADE::Filter::Parser;
my $tree = $parser->parse_string( 'value.list HAS ALL "a", "b", "c"' );

my @traverse_order;
OPTIMADE::Filter::Modifiable::modify( $tree,
    sub {
        my( $node, $traverse_order ) = @_;

        push @$traverse_order, $node;
        return $node;
    },
    \@traverse_order );

my $expected = <<'END';
$VAR1 = [
          bless( {
                   'name' => [
                               'value',
                               'list'
                             ]
                 }, 'OPTIMADE::Filter::Property' ),
          '=',
          'a',
          '=',
          'b',
          '=',
          'c',
          bless( {
                   'operator' => 'HAS ALL',
                   'property' => $VAR1->[0],
                   'values' => [
                                 [
                                   '=',
                                   'a'
                                 ],
                                 [
                                   '=',
                                   'b'
                                 ],
                                 [
                                   '=',
                                   'c'
                                 ]
                               ]
                 }, 'OPTIMADE::Filter::ListComparison' )
        ];
END

is( Dumper( \@traverse_order ), $expected );

