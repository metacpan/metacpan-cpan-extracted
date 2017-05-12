# -*- perl -*-


use strict;
# for emacs debugger
#use lib "../blib/lib";
#use lib ".";
use lib "t/springfield";
use Springfield qw(stdpop %id leaked @kids);

# This is set to 1 by iarray.t
use vars qw( $intrusive );

BEGIN {
    my $tests = ($intrusive ? 49 : 57);
    eval "use Test::More tests => $tests;"; die $@ if $@;
}

#$intrusive = 1;
#$Tangram::TRACE = \*STDOUT;

my $children = $intrusive ? 'ia_children' : 'children';

sub NaturalPerson::children
{
    my ($self) = @_;
    join(' ', map { $_->{firstName} || '' } @{ $self->{$children} } )
}

sub marge_test
{
    my $storage = shift;
    SKIP:
    unless ($intrusive)
    {
	#skip("n/a to Intrusive Tests", 1) if $intrusive;
	is( $storage->load( $id{Marge} )->children,
	    'Bart Lisa Maggie',
	    "Marge's children all found" );
    }
}

#=====================================================================
#  TESTING BEGINS
#=====================================================================

# insert the test data
stdpop($children);

is(leaked, 0, "Nothing leaked yet!");

# Test that updates notice changes to collections
{
    my $storage = Springfield::connect;
    my $homer = $storage->load( $id{Homer} );
    ok($homer, "Homer still exists!");

    is($homer->children, 'Bart Lisa Maggie', "array auto-vivify 1" );
    marge_test( $storage );

    @{ $homer->{$children} }[0, 2] = @{ $homer->{$children} }[2, 0];
    $storage->update( $homer );

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load( $id{Homer} );

    is($homer->children, 'Maggie Lisa Bart', "array update test 1");
    marge_test( $storage );

    pop @{ $homer->{$children} };
    $storage->update( $homer );

    $storage->disconnect;
}

###############################################
# insert

{
    my $storage = Springfield::connect;
    my $homer = $storage->load($id{Homer}) or die;

    is( $homer->children, 'Maggie Lisa',
	"array update test 2 (pop)" );

    shift @{ $homer->{$children} };
    $storage->update($homer);

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load($id{Homer}) or die;
    is( $homer->children, 'Lisa',
	"array update test 2 (shift)" );
    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load($id{Homer}) or die;
    shift @{ $homer->{$children} };
    $storage->update($homer);
    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load($id{Homer}) or die;

    is( $homer->children, "", "array update test 3 (all gone)");

    push @{ $homer->{$children} }, $storage->load( $id{Bart} );
    $storage->update($homer);

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load($id{Homer}) or die;

    is( $homer->children, 'Bart', "array insert test 1"  );

    push ( @{ $homer->{$children} },
	   $storage->load( @id{qw(Lisa Maggie)} ) );
    $storage->update($homer);

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load( $id{Homer} );

    is( $homer->children, 'Bart Lisa Maggie', "array insert test 2" );
    marge_test( $storage );

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $homer = $storage->load( $id{Homer} );

    is( $homer->children, 'Bart Lisa Maggie', "still there" );
    marge_test( $storage );

    $storage->unload();
    undef $homer;

    is(leaked, 0, "leaktest (unload)");

    $storage->disconnect;
}

###########
# back-refs
SKIP:
if ($intrusive)
{
    skip("Intr types test only", 2) unless $intrusive;

    my $storage = Springfield::connect;
    my $bart = $storage->load( $id{Bart} );

    is($bart->{ia_parent}{firstName}, 'Homer', "array back-refs" );
    marge_test( $storage );

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

##########
# prefetch
# FIXME - add documentation to Tangram::Storage for prefetch
{
    my $storage = Springfield::connect;

    my @prefetch = $storage->prefetch( 'NaturalPerson', $children );

    my $homer = $storage->load( $id{Homer} );

    is( $homer->children, 'Bart Lisa Maggie',
	"prefetch test returned same results");

    marge_test( $storage );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;

    my $person = $storage->remote('NaturalPerson');
    my @prefetch = $storage->prefetch( 'NaturalPerson', $children );

    my $homer = $storage->load( $id{Homer} );

    is( $homer->children, 'Bart Lisa Maggie',
	"prefetch test returned same results");
    marge_test( $storage );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");

#########
# queries

my $parents = $intrusive ? 'Homer' : 'Homer Marge';
my $pops = $intrusive ? 'Abraham Homer' : 'Abraham Homer Marge';

{
    my $storage = Springfield::connect;
    my ($parent, $child)
	= $storage->remote(qw( NaturalPerson NaturalPerson ));

    ##local($Tangram::TRACE) = \*STDERR;

    my @results = $storage->select
	(
	 $parent,
	 $parent->{$children}->includes( $child )
	 & $child->{firstName} eq 'Bart'
	);

    is(join( ' ', sort map { $_->{firstName} } @results ),
       $parents, "Query (array->includes(t2) & t2->{foo} eq Bar)" );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");

SKIP:
{
    skip "SQLite doesn't like IN having a non hard-coded list", 1
	if DBConfig->dialect =~ /sqlite/i;

    my $storage = Springfield::connect;
    my ($parent, $child1, $child2)
	= $storage->remote(qw( NaturalPerson NaturalPerson NaturalPerson ));

    #local($Tangram::TRACE) = \*STDERR;

    my @results = $storage->select
	(
	 $parent,
	 $parent->{$children}->includes_or( $child1, $child2
					  )
	 # note the caveat - both these conditions must hold for one
	 # row, although this may not be the one selected; ie, if I
	 # replace "Homer" with "Montgomery", I get *NO* results -
	 # RDBMSes suck :-)
	 & $child1->{firstName} eq 'Bart'
	 & $child2->{firstName} eq 'Homer'
	);

    is(join( ' ', sort map { $_->{firstName} } @results ),
       $pops, "Query (includes_or with two remotes)" );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");
#diag("-"x69);

{
    my $storage = Springfield::connect;
    my ($parent, $child)
	= $storage->remote(qw( NaturalPerson NaturalPerson ));

    my @males = $storage->select
	(
	 $child,
	 $child->{firstName} eq 'Bart'
	 | $child->{firstName} eq 'Homer'
	);

    #local($Tangram::TRACE) = \*STDERR;

    my @results = $storage->select
	(
	 $parent,
	 $parent->{$children}->includes_or( @males )
	);

    is(join( ' ', sort map { $_->{firstName} } @results ),
       $pops, "Query (includes_or with two objects)" );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");
#diag("-"x69);

SKIP:{
    skip "SQLite doesn't like IN having a non hard-coded list", 1
	if DBConfig->dialect =~ /sqlite/i;
    skip "Oracle doesn't like DISTINCT on CLOBs; we need a new test suite ;)", 1
	if DBConfig->dialect =~ /oracle/i;
    my $storage = Springfield::connect;
    my ($parent, $child )
	= $storage->remote(qw( NaturalPerson NaturalPerson ));

    my @male = $storage->select
	(
	 $parent,
	 $parent->{firstName} eq 'Bart'
	);

    #local($Tangram::TRACE) = \*STDERR;

    my @results = $storage->select
	(
	 $parent,
	 filter => ($parent->{$children}->includes_or( @male, $child ) &
		    ($child->{firstName} eq "Homer")),
	 distinct => 1,
	);

    is(join( ' ', sort map { $_->{firstName} } @results ),
       $pops, "Query (includes_or with one objects & one remote)" );

    $storage->disconnect();
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;
    my $parent = $storage->remote( 'NaturalPerson' );
    my $bart = $storage->load( $id{Bart} );

    my @results = $storage->select
	(
	 $parent,
	 $parent->{$children}->includes( $bart )
	);

    is(join( ' ', sort map { $_->{firstName} } @results ),
       $parents, 'Query (array->includes($dbobj))' );
    $storage->disconnect();
}

is(leaked, 0, "leaktest");

#############
# aggreg => 1
{
    my $storage = Springfield::connect_empty;

    my @children = (map { NaturalPerson->new( firstName => $_ ) }
		    @kids);

    my $homer = NaturalPerson->new
	(
	 firstName => 'Homer',
	 $children => [ map { NaturalPerson->new( firstName => $_ ) }
			@kids ]
	);

    my $abe = NaturalPerson->new( firstName => 'Abe',
				  $children => [ $homer ] );

    $id{Abe} = $storage->insert($abe);

    $storage->disconnect();
}

is(leaked, 0, "leaktest");

SKIP:
{
    my $storage = Springfield::connect;

    $storage->erase( $storage->load( $id{Abe} ) );

    my @pop = $storage->select('NaturalPerson');
    is(@pop, 0, "aggreg deletes children via arrays");

    #skip( "n/a to Intrusive Tests", 1 ) if $intrusive;
    unless ($intrusive) {

	is($storage->connection()->selectall_arrayref
	   ("SELECT COUNT(*) FROM a_children")->[0][0],
	   0, "Link table cleared successfully after remove");
    }

    $storage->disconnect();
}

is(leaked, 0, "leaktest");


#############################################################################
# Tx

SKIP:
{
    skip "No transactions configured/supported", ($intrusive ? 9 : 11)
	if $Springfield::no_tx;

    stdpop($children);

    # check rollback of DB tx
    is(leaked, 0, "leaktest");

    {
	my $storage = Springfield::connect;
	my $homer = $storage->load( $id{Homer} );

	$storage->tx_start();

	shift @{ $homer->{$children} };
	$storage->update( $homer );

	$storage->tx_rollback();

	$storage->disconnect;
    }

    is(leaked, 0, "leaktest");


    # storage should still contain 3 children

    {
	my $storage = Springfield::connect;
	my $homer = $storage->load( $id{Homer} );

	is( $homer->children, 'Bart Lisa Maggie', "rollback 1" );
	marge_test( $storage );

	$storage->disconnect;
    }

    is(leaked, 0, "leaktest");


    # check that DB and collection state remain in synch in case of rollback
    {
	my $storage = Springfield::connect;
	my $homer = $storage->load( $id{Homer} );

	$storage->tx_start();

	shift @{ $homer->{$children} };
	$storage->update( $homer );

	$storage->tx_rollback();

	$storage->update( $homer );

	$storage->disconnect;
    }

    # Bart should no longer be Homer's child
    {
	my $storage = Springfield::connect;
	my $homer = $storage->load( $id{Homer} );

	is( $homer->children, 'Lisa Maggie',
	    "auto-commit on disconnect" );
	marge_test( $storage );

	$storage->disconnect;
    }

    is(leaked, 0, "leaktest");

}

1;
