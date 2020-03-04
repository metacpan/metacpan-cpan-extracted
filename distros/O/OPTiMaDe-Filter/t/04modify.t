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

my $tree_now = OPTiMaDe::Filter::modify( $tree,
    sub {
        my( $node ) = @_;
        if( blessed $node && $node->isa( OPTiMaDe::Filter::ListComparison:: ) ) {
            my @values = @{$node->{values}};
            my $node_now;
            while( @values ) {
                my( undef, $value ) = @{shift @values};
                my $comparison = OPTiMaDe::Filter::Comparison->new( 'CONTAINS' );
                $comparison->push_operand( $node->{property} );
                $comparison->push_operand( $value );
                if( $node_now ) {
                    $node_now = [ $node_now, 'AND', $comparison ];
                } else {
                    $node_now = $comparison;
                }
            }
            $node = $node_now;
        }
        return $node;
    } );

my $expected = <<'END';
$VAR1 = [
          [
            bless( {
                     'operands' => [
                                     bless( {
                                              'name' => [
                                                          'value',
                                                          'list'
                                                        ]
                                            }, 'OPTiMaDe::Filter::Property' ),
                                     'a'
                                   ],
                     'operator' => 'CONTAINS'
                   }, 'OPTiMaDe::Filter::Comparison' ),
            'AND',
            bless( {
                     'operands' => [
                                     $VAR1->[0][0]{'operands'}[0],
                                     'b'
                                   ],
                     'operator' => 'CONTAINS'
                   }, 'OPTiMaDe::Filter::Comparison' )
          ],
          'AND',
          bless( {
                   'operands' => [
                                   $VAR1->[0][0]{'operands'}[0],
                                   'c'
                                 ],
                   'operator' => 'CONTAINS'
                 }, 'OPTiMaDe::Filter::Comparison' )
        ];
END

is( Dumper( $tree_now ), $expected );
