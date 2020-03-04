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
my $tree = $parser->parse_string( 'a >= 5 OR b <= 2 AND c > 10' );

my $tree_now = OPTiMaDe::Filter::modify( $tree,
    sub {
        my( $node ) = @_;
        if( blessed $node && $node->isa( OPTiMaDe::Filter::Comparison:: ) ) {
            $node->{operator} =~ s/([<>])=/$1/;
        }
        return $node;
    } );

my $expected = <<'END';
$VAR1 = bless( {
                 'operands' => [
                                 bless( {
                                          'operands' => [
                                                          bless( {
                                                                   'name' => [
                                                                               'a'
                                                                             ]
                                                                 }, 'OPTiMaDe::Filter::Property' ),
                                                          '5'
                                                        ],
                                          'operator' => '>'
                                        }, 'OPTiMaDe::Filter::Comparison' ),
                                 bless( {
                                          'operands' => [
                                                          bless( {
                                                                   'operands' => [
                                                                                   bless( {
                                                                                            'name' => [
                                                                                                        'b'
                                                                                                      ]
                                                                                          }, 'OPTiMaDe::Filter::Property' ),
                                                                                   '2'
                                                                                 ],
                                                                   'operator' => '<'
                                                                 }, 'OPTiMaDe::Filter::Comparison' ),
                                                          bless( {
                                                                   'operands' => [
                                                                                   bless( {
                                                                                            'name' => [
                                                                                                        'c'
                                                                                                      ]
                                                                                          }, 'OPTiMaDe::Filter::Property' ),
                                                                                   '10'
                                                                                 ],
                                                                   'operator' => '>'
                                                                 }, 'OPTiMaDe::Filter::Comparison' )
                                                        ],
                                          'operator' => 'AND'
                                        }, 'OPTiMaDe::Filter::AndOr' )
                               ],
                 'operator' => 'OR'
               }, 'OPTiMaDe::Filter::AndOr' );
END

is( Dumper( $tree_now ), $expected );
