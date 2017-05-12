#!/usr/bin/perl -w
use strict;
use Test::More tests=>4;
use_ok qw(Parse::Eyapp::Node) or exit;

our $test_datacompare_installed;
BEGIN { 
  $test_datacompare_installed = 1;
  eval { require Data::Compare };
  $test_datacompare_installed = 0 if $@;
}

SKIP: {
  skip "Data::Compare not installed", 3 unless $test_datacompare_installed;

  my $handler = sub { 
    Data::Compare::Compare($_[0], $_[1]) 
  };

  my $t1 = bless( {
                   'types' => {
                                'CHAR' => bless( { 'children' => [] }, 'CHAR' ),
                                'VOID' => bless( { 'children' => [] }, 'VOID' ),
                                'INT' => bless( { 'children' => [] }, 'INT' ),
                                'F(X_0(),INT)' => bless( { 
                                   'children' => [ 
                                      bless( { 'children' => [] }, 'X_0' ), 
                                      bless( { 'children' => [] }, 'INT' ) ] 
                                 }, 'F' )
                              },
                   'symboltable' => { 'f' => { 'type' => 'F(X_0(),INT)', 'line' => 1 } },
                   'lines' => 2,
                   'children' => [
                                   bless( {
                                            'symboltable' => {},
                                            'fatherblock' => {},
                                            'children' => [],
                                            'depth' => 1,
                                            'parameters' => [],
                                            'function_name' => [ 'f', 1 ],
                                            'symboltableLabel' => {},
                                            'line' => 1
                                          }, 'FUNCTION' )
                                 ],
                   'depth' => 0,
                   'line' => 1
                 }, 'PROGRAM' );
  $t1->{'children'}[0]{'fatherblock'} = $t1;

  # Tree similar to $t1 but without some attttributes (line, depth, etc.)
  my $t2 = bless( {
                   'types' => {
                                'CHAR' => bless( { 'children' => [] }, 'CHAR' ),
                                'VOID' => bless( { 'children' => [] }, 'VOID' ),
                                'INT' => bless( { 'children' => [] }, 'INT' ),
                                'F(X_0(),INT)' => bless( { 
                                   'children' => [ 
                                      bless( { 'children' => [] }, 'X_0' ), 
                                      bless( { 'children' => [] }, 'INT' ) ] 
                                 }, 'F' )
                              },
                   'symboltable' => { 'f' => { 'type' => 'F(X_0(),INT)', 'line' => 1 } },
                   'children' => [
                                   bless( {
                                            'symboltable' => {},
                                            'fatherblock' => {},
                                            'children' => [],
                                            'parameters' => [],
                                            'function_name' => [ 'f', 1 ],
                                          }, 'FUNCTION' )
                                 ],
                 }, 'PROGRAM' );
  $t2->{'children'}[0]{'fatherblock'} = $t2;

  # Tree similar to $t1 but without some attttributes (line, depth, etc.)
  # and without the symboltable attribute
  my $t3 = bless( {
                   'types' => {
                                'CHAR' => bless( { 'children' => [] }, 'CHAR' ),
                                'VOID' => bless( { 'children' => [] }, 'VOID' ),
                                'INT' => bless( { 'children' => [] }, 'INT' ),
                                'F(X_0(),INT)' => bless( { 
                                   'children' => [ 
                                      bless( { 'children' => [] }, 'X_0' ), 
                                      bless( { 'children' => [] }, 'INT' ) ] 
                                 }, 'F' )
                              },
                   'children' => [
                                   bless( {
                                            'symboltable' => {},
                                            'fatherblock' => {},
                                            'children' => [],
                                            'parameters' => [],
                                            'function_name' => [ 'f', 1 ],
                                          }, 'FUNCTION' )
                                 ],
                 }, 'PROGRAM' );

  $t3->{'children'}[0]{'fatherblock'} = $t2;

  # Without attributes
  ok(Parse::Eyapp::Node::equal($t1, $t2), "Not considering attributes: Equal");

  # Equality with attributes
  ok(Parse::Eyapp::Node::equal(
        $t1, $t2, 
        symboltable => $handler,
        types => $handler,
      ), "Considering attributes: Equal");

  # Equality with attributes
  ok(!Parse::Eyapp::Node::equal( $t1, $t3, symboltable => $handler, types => $handler,), 
     "Considering attributes: Not Equal");
}
