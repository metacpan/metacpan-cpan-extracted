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
my $tree = $parser->parse_string( 'a >= 5 OR b <= 2 AND c > 10' );

my $tree_now = OPTIMADE::Filter::Modifiable::modify( $tree,
    sub {
        my( $node ) = @_;
        if( blessed $node && $node->isa( OPTIMADE::Filter::Comparison:: ) ) {
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
                                                                 }, 'OPTIMADE::Filter::Property' ),
                                                          '5'
                                                        ],
                                          'operator' => '>'
                                        }, 'OPTIMADE::Filter::Comparison' ),
                                 bless( {
                                          'operands' => [
                                                          bless( {
                                                                   'operands' => [
                                                                                   bless( {
                                                                                            'name' => [
                                                                                                        'b'
                                                                                                      ]
                                                                                          }, 'OPTIMADE::Filter::Property' ),
                                                                                   '2'
                                                                                 ],
                                                                   'operator' => '<'
                                                                 }, 'OPTIMADE::Filter::Comparison' ),
                                                          bless( {
                                                                   'operands' => [
                                                                                   bless( {
                                                                                            'name' => [
                                                                                                        'c'
                                                                                                      ]
                                                                                          }, 'OPTIMADE::Filter::Property' ),
                                                                                   '10'
                                                                                 ],
                                                                   'operator' => '>'
                                                                 }, 'OPTIMADE::Filter::Comparison' )
                                                        ],
                                          'operator' => 'AND'
                                        }, 'OPTIMADE::Filter::AndOr' )
                               ],
                 'operator' => 'OR'
               }, 'OPTIMADE::Filter::AndOr' );
END

is( Dumper( $tree_now ), $expected );
