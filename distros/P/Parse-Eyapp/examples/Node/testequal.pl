#!/usr/bin/perl -w
use strict;
use Parse::Eyapp::Node;
use Data::Dumper;
use Data::Compare;

my $debugging = 0;

my $handler = sub { 
  print Dumper($_[0], $_[1]) if $debugging; 
  Compare($_[0], $_[1]) 
};

# A tree PROGRAM(FUNCTION) with the attributes set, just after type checking
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
if (Parse::Eyapp::Node::equal($t1, $t2)) {
  print "\nNot considering attributes: Equal\n";
}
else {
  print "\nNot considering attributes: Not Equal\n";
}

# Equality with attributes
if (Parse::Eyapp::Node::equal(
      $t1, $t2, 
      symboltable => $handler,
      types => $handler,
    )
   ) {
      print "\nConsidering attributes: Equal\n";
}
else {
  print "\nConsidering attributes: Not Equal\n";
}

# Equality with attributes
if (Parse::Eyapp::Node::equal(
      $t1, $t3, 
      symboltable => $handler,
      types => $handler,
    )
   ) {
      print "\nConsidering attributes: Equal\n";
}
else {
  print "\nConsidering attributes: Not Equal\n";
}
