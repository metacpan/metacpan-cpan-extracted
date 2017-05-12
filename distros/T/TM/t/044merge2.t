use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

#== TESTS =====================================================================


use TM;
use TM::Materialized::AsTMa;

{ # testing add, same baseuri
    my $tm1 = new TM;
    $tm1->internalize ('rumsti' => \ 'http://rumsti/');

    $tm1->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'ramsti' ]));
    $tm1->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'remsti' ]));

    my $tm2 = new TM;
    $tm2->internalize ('rumsti' => \ 'http://xxxrumsti/');
    $tm2->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'rimsti' ]));

    $tm2->add ($tm1);
#warn Dumper $tm2;

    my $m = $tm2->insane;
    die $m if $m;

    ok (eq_set ([
		 map { $_->players->[0] }
		 $tm2->match (TM->FORALL, anyid => $tm2->tids (\ 'http://rumsti/'))
		 ], 
		[
		 'tm://nirvana/ramsti',
		 'tm://nirvana/remsti',
		 ]
		), 'add: found all assocs (new rumsti)');
    ok (eq_set ([
		 map { $_->players->[0] }
		 $tm2->match (TM->FORALL, anyid => $tm2->tids (\ 'http://xxxrumsti/'))
		 ], 
		[
		 'tm://nirvana/rimsti',
		 ]
		), 'add: found all assocs (old rumsti)');
    ok (eq_array ([ 
		    $tm2->tids ('ramsti', 
				'remsti',
				'rimsti',) ], 
		  [  'tm://nirvana/ramsti',
		     'tm://nirvana/remsti',
		     'tm://nirvana/rimsti', ]), 'add: found all rumstis');
}

{
    my $tm1 = new TM::Materialized::AsTMa (baseuri => 'tm1:', inline => 'aaa (bbb)
in: AAA
oc: http://aaa/

bbb
bn: BBB
oc: http://bbb/
sin: http://xxx/

(is-subclass-of)
subclass: ccc
superclass: bbb

');
    $tm1->sync_in;
    my $tm2 = new TM::Materialized::AsTMa (baseuri => 'tm2:', inline => 'aaa (bbb)
in: AAA2
oc: http://aaa2/

bbb
bn: BBB2
oc: http://bbb2/
sin: http://xxx/

(is-subclass-of)
subclass: ccc
superclass: bbb

');
    $tm2->sync_in;
    $tm1->add ($tm2);

    $tm1->consolidate;

    my $m = $tm1->insane;
    die "CORRRUPT $m" if $m;

    { # make sure that only bbb is merged
	isnt ($tm1->toplet ('tm1:aaa'), $tm1->toplet ('tm2:aaa'), 'aaa not merged');
	is   ($tm1->toplet ('tm1:bbb'), $tm1->toplet ('tm2:bbb'), 'bbb     merged (toplet)');
	ok   (eq_set   (
			$tm1->toplets ('tm1:bbb')->[TM->INDICATORS],
			[ 'http://xxx/' ] ), 'subject indicators');
	is   ($tm1->tids   ('tm1:bbb'), $tm1->tids   ('tm2:bbb'), 'bbb     merged (ID)');
    }
    { # try to find chars
	ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $tm1->match_forall (char => 1, topic => $tm1->tids ('bbb')) ] ,
                [ 
		  'BBB2',
		  'http://bbb/',
		  'BBB',
		  'http://bbb2/'
		  ]),       'chars of bbb');
	ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $tm1->match_forall (char => 1, topic => $tm1->tids ('tm1:aaa')) ] ,
                [ 
		  'AAA',
		  'http://aaa/',
		  ]),       'chars of tm1:aaa');
	ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $tm1->match_forall (char => 1, topic => $tm1->tids ('tm2:aaa')) ] ,
                [ 
		  'AAA2',
		  'http://aaa2/',
		  ]),       'chars of tm2:aaa');
     }

#warn Dumper $tm1;
    {
	ok (eq_set ([ $tm1->instances  ('tm1:bbb') ],[ 'tm1:aaa', 'tm2:aaa' ]), 'instances of bbb');
	ok (eq_set ([ $tm1->subclasses ('tm1:bbb') ],[ 'tm1:ccc', 'tm2:ccc' ]), 'subclasses of bbb');
    }

  TODO: {
      local $TODO = "merge maps with the same baseURI";

      ok( 0,       'exotic use' );
  };

}


__END__
