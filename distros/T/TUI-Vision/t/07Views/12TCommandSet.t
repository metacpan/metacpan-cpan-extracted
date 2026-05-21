use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Views::CommandSet';
}

my $intersect = \&{ TCommandSet . '::intersect' };
my $union     = \&{ TCommandSet . '::union'     };
my $equal     = \&{ TCommandSet . '::equal'     };
my $not_equal = \&{ TCommandSet . '::not_equal' };

# Test new method
my $cmd_set = TCommandSet->new();
isa_ok( $cmd_set, TCommandSet, 'new() creates an object of correct class' );

# Test has method
$cmd_set->enableCmd( 5 );
ok( $cmd_set->has( 5 ),  'has() returns true for enabled command' );
ok( !$cmd_set->has( 6 ), 'has() returns false for disabled command' );

# Test disableCmd method
$cmd_set->disableCmd( 5 );
ok( !$cmd_set->has( 5 ), 'disableCmd() disables the command' );

# Test enableCmd method
$cmd_set->enableCmd( 7 );
ok( $cmd_set->has( 7 ), 'enableCmd() enables the command' );

# Test disableCmd method
my $cmd_set2 = TCommandSet->new();
$cmd_set2->enableCmd( 7 );
$cmd_set->disableCmd( $cmd_set2 );
ok( !$cmd_set->has( 7 ), 'disableCmd() disables the commands in the set' );

# Test enableCmd method
$cmd_set2->enableCmd( 8 );
$cmd_set->enableCmd( $cmd_set2 );
ok( $cmd_set->has( 8 ), 'enableCmd() enables the commands in the set' );

# Test isEmpty method
$cmd_set = TCommandSet->new();
ok( $cmd_set->isEmpty(), 'isEmpty() returns true for empty set' );
$cmd_set->enableCmd( 9 );
ok( !$cmd_set->isEmpty(), 'isEmpty() returns false for non-empty set' );

# Test intersect method
$cmd_set->enableCmd( 10 );
$cmd_set2->enableCmd( 10 );
my $cmd_set3 = $intersect->( $cmd_set, $cmd_set2 );
ok( 
  !$cmd_set3->has( 9 ) && $cmd_set3->has( 10 ),
  'intersect() returns correct result'
);

# Test union method
$cmd_set2->enableCmd( 11 );
$cmd_set3 = $union->( $cmd_set, $cmd_set2 );
ok( $cmd_set3->has( 11 ), 'union() returns correct result' );

# Test & operator
$cmd_set3 = $cmd_set & $cmd_set2;
ok( 
  !$cmd_set3->has( 9 ) && $cmd_set3->has( 10 ),
  "'&' operator returns correct result"
);

# Test | operator
$cmd_set3 = $union->( $cmd_set, $cmd_set2 );
ok( $cmd_set3->has( 11 ), "'|' operator returns correct result" );

# Test equal method
ok(
  $equal->( $cmd_set, $cmd_set ),
  'equal() returns true for equal sets'
);
ok( 
  !$equal->( $cmd_set, $cmd_set2 ),
  'equal() returns false for non-equal sets'
);

# Test not_equal method
ok(
  $not_equal->( $cmd_set, $cmd_set2 ),
  'not_equal() returns true for non-equal sets'
);
ok(
  !$not_equal->( $cmd_set, $cmd_set ),
  'not_equal() returns false for equal sets'
);

# Test == operator
cmp_ok(
  $cmd_set, '==', $cmd_set,
  "'==' operator returns true for equal sets"
);

# Test != operator
cmp_ok(
  $cmd_set, '!=', $cmd_set2,
  "'!=' operator returns true for non-equal sets"
);

# Test include method
$cmd_set->include( 12 );
ok( $cmd_set->has( 12 ), 'include() enables a command' );

# Test exclude method
$cmd_set->exclude( 12 );
ok( !$cmd_set->has( 12 ), 'exclude() disables a command' );

# Test include method
$cmd_set2->enableCmd( 13 );
$cmd_set->include( $cmd_set2 );
ok( $cmd_set->has( 13 ), 'include() enables a command set' );

# Test exclude method
$cmd_set->exclude( $cmd_set2 );
ok( !$cmd_set->has( 13 ), 'exclude() disables a command set' );

done_testing();
