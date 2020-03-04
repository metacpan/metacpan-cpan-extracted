#!/usr/bin/env perl

use strict;
use warnings;
use Data::Compare;
use Data::Dumper;
use OPTiMaDe::Filter;
use OPTiMaDe::Filter::Parser;
use Scalar::Util qw(blessed);
use Test::More tests => 1;

$Data::Dumper::Sortkeys = 1;

my $parser = new OPTiMaDe::Filter::Parser;
my $tree = $parser->parse_string( 'value.list HAS ALL "a", "b", "c"' );

my @traverse_order;
OPTiMaDe::Filter::modify( $tree,
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
                 }, 'OPTiMaDe::Filter::Property' ),
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
                 }, 'OPTiMaDe::Filter::ListComparison' )
        ];
END

is( Dumper( \@traverse_order ), $expected );

