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

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}


#== TESTS =====================================================================

use TM;

{
    my $tm = new TM;
    $tm->internalize ('aaa' => undef);
    $tm->internalize ('tm://nirvana/ccc' => undef);

    is ($tm->toplet ('tm://nirvana/aaa')->[TM->LID], 'tm://nirvana/aaa', 'LID');

# normal insert
    ok (eq_array ([ $tm->tids ('aaa') ],              [ 'tm://nirvana/aaa' ]), 'found inserted 1');
    ok (eq_array ([ $tm->tids ('tm://nirvana/aaa') ], [ 'tm://nirvana/aaa' ]), 'found inserted 2');
    ok (eq_array ([ $tm->tids ('xxx') ],              [ undef ]),              'not found not inserted 1');
    ok (eq_array ([ $tm->tids ('tm://nirvana/xxx') ], [ undef ]),              'not found not inserted 2');
# with full name
    ok (eq_array ([ $tm->tids ('tm://nirvana/ccc') ], [ 'tm://nirvana/ccc' ]), 'found inserted 3');
    ok (eq_array ([ $tm->tids ('ccc') ],              [ 'tm://nirvana/ccc' ]), 'found inserted 3a');

# double insert
    $tm->internalize ('bbb' => undef);
    $tm->internalize ('bbb' => undef);
    ok (eq_array ([ $tm->tids ('bbb') ],              [ 'tm://nirvana/bbb' ]), 'found inserted 4a');

# using a subject address
    $tm->internalize ('ddd', 'http://ddd/');
    ok (eq_array ([ $tm->tids ('ddd') ],              [ 'tm://nirvana/ddd' ]), 'found inserted 5');
    ok (eq_array ([ $tm->tids ('http://ddd/') ],      [ 'tm://nirvana/ddd' ]), 'found inserted 6');

# using a subject indicator
    $tm->internalize ('eee', \ 'http://eee/');
    ok (eq_array ([ $tm->tids ('eee') ],              [ 'tm://nirvana/eee' ]), 'found inserted 7');
    ok (eq_array ([ $tm->tids (\ 'http://eee/') ],    [ 'tm://nirvana/eee' ]), 'found inserted 8');
#warn Dumper $tm;

    is_deeply ( $tm->externalize ('tm://nirvana/aaa'),
		[
		 'tm://nirvana/aaa',
		 undef,
		 [ ]
		 ] ,                                                           'externalize 1');
    ok (!$tm->tids ('aaa'),                                                    'externalize 2');
    is_deeply ( $tm->externalize ($tm->tids ('http://ddd/')),
		[
		 'tm://nirvana/ddd',
		 'http://ddd/',
		 [ ]
		 ] ,                                                           'externalize 3');
    ok (!$tm->tids ('ddd'),                                                    'externalize 4');
    is_deeply ( $tm->externalize ($tm->tids (\ 'http://eee/')),
		[
		 'tm://nirvana/eee',
		 undef,
		 [
		  'http://eee/'
		  ]
		 ] ,                                                           'externalize 5');
    ok (!$tm->tids ('eee'),                                                    'externalize 6');
}

{ # adding one assertion, finding the toplets, finding it
    my $tm = new TM ();
    my ($aid)=$tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'rumsti', 'ramsti' ]));

    is ($tm->tids ('rumsti') , 'tm://nirvana/rumsti', 'found inserted by assertion 1');
    is ($tm->tids ('ramsti') , 'tm://nirvana/ramsti', 'found inserted by assertion 2');

    # add reifier topic
    my $tid1 = $tm->internalize(undef,$aid->[TM->LID]);
    ok($tid1 
       && $tm->toplet($tid1)->[TM->ADDRESS] eq $aid->[TM->LID],"internalize creates correct assertion reifier");
    
    # find this reifier topic again
    my $tid2=$tm->internalize(undef,$aid->[TM->LID]);
    is ($tid2, $tid1, "internalize finds existing assertion reifier");
}


{ # reasserting
    my $tm = new TM;
    my $npa = $tm->match (TM->FORALL);

    $tm->assert (Assertion->new (type => 'isa', roles => [ 'class', 'instance' ], players => [ 'rumsti', 'ramsti' ]));
    $tm->assert (Assertion->new (type => 'isa', roles => [ 'class', 'instance' ], players => [ 'rumsti', 'ramsti' ]));
    is (scalar $tm->match (TM->FORALL),                                 1+$npa, 'double assert 1');
    is (scalar $tm->match (TM->FORALL, iplayer => 'tm://nirvana/rumsti'),    1, 'double assert 2');
#warn Dumper $tm;
}

{ # simple matching
    my $tm = new TM;

    $tm->assert (Assertion->new (type => 'isa', roles => [ 'class', 'instance' ], players => [ 'rumsti', 'ramsti' ]));
    is (scalar $tm->match (TM->FORALL, iplayer => 'tm://nirvana/rumsti'),    1, 'isa match 1');
    is (scalar $tm->match (TM->FORALL, iplayer => 'tm://nirvana/ramsti',
			               irole   => 'instance'),               1, 'isa match 2');
    is (scalar $tm->match (TM->FORALL, iplayer => 'tm://nirvana/ramsti'),    1, 'isa match 3');

    is (scalar $tm->match (TM->FORALL, iplayer => 'tm://nirvana/romsti'),    0, 'isa match 4');
#warn Dumper $tm;
}

{ # testing subclassing
    my $tm = new TM;
    $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'ramsti' ]));
    $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'remsti' ]));

    ok ($tm->is_subclass ($tm->tids ('ramsti', 'rumsti')), 'found subclass');
    ok ($tm->is_subclass ($tm->tids ('remsti', 'rumsti')), 'found subclass 2');

    ok (eq_set ([
		 map { $tm->get_players ($_, 'subclass') }
		 $tm->match (TM->FORALL,
			     type    => 'is-subclass-of', 
			     arole   => 'superclass', 
			     aplayer => 'tm://nirvana/rumsti', 
			     brole   => 'subclass')
		 ], 
		[
		 'tm://nirvana/ramsti',
		 'tm://nirvana/remsti'
		 ]
		), 'found all subclasses');
#warn Dumper $tm;

    # indirect subclassing
    $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'ramsti', 'rimsti' ]));
    ok ($tm->is_subclass ($tm->tids('rimsti', 'rumsti')), 'found indirect subclass');
    ok ($tm->is_subclass ($tm->tids('ramsti', 'rumsti')), 'found subclass');
    ok ($tm->is_subclass ($tm->tids('remsti', 'rumsti')), 'found subclass');
}

{ # retracting
  my $tm = new TM;
  ok (!$tm->retrieve ('tm://nirvana/aaa'), 'looking for aaa, not there');
  $tm->assert (Assertion->new (lid => 'tm://nirvana/aaa', players => [], roles => []),
	       Assertion->new (lid => 'tm://nirvana/bbb', players => [], roles => []),
	       Assertion->new (lid => 'tm://nirvana/ccc', players => [], roles => []));
#warn Dumper $tm;
  ok ($tm->retrieve ('tm://nirvana/aaa'),  'looking for aaa, is there');
  $tm->retract ('tm://nirvana/bbb');
  ok ($tm->retrieve ('tm://nirvana/aaa'),  'looking for aaa, is still there');
  $tm->retract ('tm://nirvana/aaa');
  ok (!$tm->retrieve ('tm://nirvana/aaa'), 'looking for aaa, not anymore there');
}

{ # exact result
  my $tm = new TM;
  my $m = Assertion->new (scope => 'sss', type => 'ttt', roles => [ 'aaa', 'bbb' ], players => [ 'xxx', 'yyy' ]);
  ($m) = $tm->assert ($m);
#warn Dumper $tm, $m;

  my @res = $tm->match (TM->FORALL, scope => 'tm://nirvana/sss');
  is (@res, 1,       'assertions detected');
  ok ($res[0] == $m, 'assertion correct');
}

{
  my $tm = new TM;
  my ($m1, $m2) = $tm->assert (Assertion->new (type => 'ttt', scope => 'sss', roles => [ 'aaa', 'bbb' ], players => [ 'xxx', 'yyy' ]),
			       Assertion->new (type => 'ttt', scope => 'sss', roles => [ 'aaa', 'bbb' ], players => [ 'zzz', 'uuu' ]));
#warn Dumper $tm;
  my @res = $tm->match        (TM->FORALL,
			       type => 'tm://nirvana/ttt',    roles => [ 'tm://nirvana/aaa', 'tm://nirvana/bbb' ]);
  ok (@res == 2, 'assertions detected');

  $tm->retract ($m2->[TM->LID], $m1->[TM->LID]);
  @res = $tm->match           (TM->FORALL,
			       type => 'tm://nirvana/ttt',    roles => [ 'tm://nirvana/aaa', 'tm://nirvana/bbb' ]);
  ok (@res == 0, 'assertions not detected');
}

{ # testing taxonometric functions
    use TM;
    my $tm = new TM (baseuri => 'tm:');
#warn Dumper $tm;

    ok (eq_set ([ $tm->instances  ('assertion-type') ],[ 'isa', 'is-subclass-of' ]),       'subsumption: instances 1');

    ok (eq_set ([ $tm->instances  ('scope') ],         [ 'us' ]),                          'subsumption: instances 2');
#warn Dumper [ $tm->instancesT ('thing') ];
    ok (eq_set ([$tm->instances  ('thing')], [map { $_->[TM->LID]} $tm->toplets]),         'instances of thing');
    ok (eq_set ([$tm->instancesT ('thing')], [map { $_->[TM->LID]} $tm->toplets]),         'instances of thing *');

    ok (eq_set ([$tm->instances ('isa') ], [
					    'c667ce5f4e485b45698c75621bc63893',
					    '9aa74da04e36d6f5c05ffe1c91eab7d2',
					    '8168aba8d6a9284c70e9c461a8977892'
					    ]),                                            'subsumption: instances 5');

    foreach my $a ($tm->instances ('isa')) {
	ok (eq_set ([ $tm->types($a)] , [ 'isa' ]),                                       'subsumption assertions type');
	is ($tm->retrieve ($a)->[TM->TYPE], 'isa',                                        'subsumption assertions instances')
    }
    foreach my $a ($tm->instances ('is-subclass-of')) {
	ok (eq_set ([ $tm->types($a)] , [ 'is-subclass-of' ]),                            'subsumption assertions type');
	is ($tm->retrieve ($a)->[TM->TYPE], 'is-subclass-of',                             'subsumption assertions instances')
    }

    ok (eq_set ([$tm->types ('isa')],  [ 'assertion-type']),                              'subsumption: types 1');
    ok (eq_set ([$tm->typesT ('isa')], [ 'assertion-type',  'class' ]),                   'subsumption: typesT 1');

    ok (eq_set ([$tm->types ('us', 'us', 'isa')],
		[ 'scope', 'assertion-type' ]),                                           'subsumption, several types, unique');


    ok (eq_set ([ $tm->subclasses ('thing') ],        [  ]),                              'subsumption: subclasses 1');
    ok (eq_set ([ $tm->subclasses ('characteristic') ],
                [ 'occurrence', 'unique-characteristic', 'name' ]),                       'subsumption: subclasses 2');

    ok (eq_set ([ $tm->subclassesT ('characteristic') ],
                [ 'characteristic', 'occurrence', 
		  'unique-characteristic', 'name' ]),                                  'subsumption: subclassesT 1');



}

{ # testing taxonometric functions
    my $tm = new TM;

    $tm->assert (Assertion->new (type => 'is-subclass-of', scope => 'us', roles => [ 'subclass', 'superclass' ], players => [ 'XXX', 'AAA' ]));
    $tm->assert (Assertion->new (type => 'is-subclass-of', scope => 'us', roles => [ 'subclass', 'superclass' ], players => [ 'AAA', 'BBB' ]));
    $tm->assert (Assertion->new (type => 'is-subclass-of', scope => 'us', roles => [ 'subclass', 'superclass' ], players => [ 'AAA', 'CCC' ]));

    $tm->assert (Assertion->new (type => 'isa', scope => 'us', roles => [ 'class', 'instance' ], players => [ 'XXX', 'xxx' ]));
    $tm->assert (Assertion->new (type => 'isa', scope => 'us', roles => [ 'class', 'instance' ], players => [ 'ZZZ', 'xxx' ]));
    $tm->assert (Assertion->new (type => 'isa', scope => 'us', roles => [ 'class', 'instance' ], players => [ 'XXX', 'yyy' ]));

    $tm->assert (Assertion->new (type => 'isa', scope => 'us', roles => [ 'class', 'instance' ], players => [ 'AAA', 'aaa' ]));
    $tm->assert (Assertion->new (type => 'isa', scope => 'us', roles => [ 'class', 'instance' ], players => [ 'BBB', 'bbb' ]));

    ok ($tm->is_a  ('tm://nirvana/aaa',  'thing'),              'is_a 1');
    ok ($tm->is_a  ('us',   'scope'),                           'is_a 2');

    ok (!$tm->is_a ('tm://nirvana/uuu',  'thing'),              'is_a 3');

    ok ($tm->is_a  ('tm://nirvana/aaa',  'tm://nirvana/AAA'),   'is_a 4');
    ok ($tm->is_a  ('tm://nirvana/aaa',  'tm://nirvana/BBB'),   'is_a 5');
    ok ($tm->is_a  ('tm://nirvana/aaa',  'tm://nirvana/CCC'),   'is_a 6');

    ok (eq_set ([ $tm->are_instances ('tm://nirvana/XXX', map { $_->[TM->LID] } $tm->toplets ) ],
		[  'tm://nirvana/yyy',
		   'tm://nirvana/xxx'  ]),                           'are_instance: XXX');

    ok (eq_set ([ $tm->are_instances ('tm://nirvana/AAA', map { $_->[TM->LID] } $tm->toplets ) ],
		[  'tm://nirvana/aaa',
		   'tm://nirvana/yyy',
                   'tm://nirvana/xxx' ]),                            'are_instance: AAA');

    ok (eq_set ([ $tm->are_instances ('tm://nirvana/BBB', map { $_->[TM->LID] } $tm->toplets ) ],
		[  'tm://nirvana/aaa',
		   'tm://nirvana/bbb',
		   'tm://nirvana/yyy',
                   'tm://nirvana/xxx' ]),                            'are_instance: BBB');

  TODO: {
      local $TODO = "are_types, ....";
      ok ($tm->are_types,      'filter: are types');
      ok ($tm->are_supertypes, 'filter: are supertypes');
      ok ($tm->are_subtypes,   'filter: are subtypes');
  }


    ok ($tm->is_subclass ('tm://nirvana/AAA', 'thing'),              'subclass thing');
    ok ($tm->is_subclass ('tm://nirvana/AAA', 'tm://nirvana/BBB'),   'subclass 1');
    ok ($tm->is_subclass ('tm://nirvana/XXX', 'tm://nirvana/BBB'),   'subclass 2');

    ok (eq_set ([ $tm->subclasses ('tm://nirvana/BBB') ],
		[ 'tm://nirvana/AAA' ]),                             'subclasses 1');
    ok (eq_set ([ $tm->subclasses ('tm://nirvana/AAA') ],
		[ 'tm://nirvana/XXX' ]),                             'subclasses 2');
    ok (eq_set ([ $tm->subclassesT ('tm://nirvana/BBB') ],
		[ 'tm://nirvana/XXX',
		  'tm://nirvana/BBB',
		  'tm://nirvana/AAA']),                              'subclasses 3');

    ok (eq_set ([ $tm->superclasses ('tm://nirvana/XXX') ],
		[ 'tm://nirvana/AAA' ]),                             'superclasses 1');
    ok (eq_set ([ $tm->superclasses ('tm://nirvana/AAA') ],
		[ 'tm://nirvana/BBB',
		  'tm://nirvana/CCC' ]),                             'superclasses 2');
    ok (eq_set ([ $tm->superclassesT ('tm://nirvana/XXX') ],
		[ 'tm://nirvana/XXX',
		  'tm://nirvana/BBB',
		  'tm://nirvana/CCC',
		  'tm://nirvana/AAA']),                              'superclasses 3');

    ok (eq_set ([ $tm->types ('tm://nirvana/xxx') ],
		[ 'tm://nirvana/XXX',
                  'tm://nirvana/ZZZ' ]),                             'types 1');
    ok (eq_set ([ $tm->typesT ('tm://nirvana/xxx') ],
		[ 'tm://nirvana/XXX',
                  'tm://nirvana/ZZZ',
		  'tm://nirvana/BBB',
		  'tm://nirvana/CCC',
		  'tm://nirvana/AAA' ]),                             'types 2');

    ok (eq_set ([ $tm->instances ('tm://nirvana/AAA') ],
		[ 'tm://nirvana/aaa' ]),                             'instances 1');
    ok (eq_set ([ $tm->instancesT ('tm://nirvana/AAA') ],
		[ 'tm://nirvana/xxx',
                  'tm://nirvana/yyy',
		  'tm://nirvana/aaa' ]),                             'instances 2');
}

{ # testing characteristics
    my $tm = new TM;

    use TM::Literal;

    $tm->assert (Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'aaa', new TM::Literal ('AAA') ]));
    $tm->assert (Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'aaa', new TM::Literal ('AAAA') ]));
    $tm->assert (Assertion->new (kind => TM->OCC,  type => 'occurrence', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'aaa', new TM::Literal ('OOOO') ]));
    $tm->assert (Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'ccc', new TM::Literal ('CCC') ]));
#warn Dumper $tm;

    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $tm->match_forall (char => 1, topic => $tm->tids ('aaa')) ] ,
		[ 'AAA',
		  'OOOO',
                  'AAAA' ]),                             'chars of aaa');
}

{ # testing midlet functionality
    use TM;
    my $tm = new TM (baseuri => 'tm:');
#warn Dumper $tm;

    my ($a1) = $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'ramsti' ]));
    my ($a2) = $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'remsti' ]));

    $tm->assert (Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'rumsti', new TM::Literal ('Rumsti') ]));
    $tm->assert (Assertion->new (kind => TM->OCC,  type => 'occurrence', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'rumsti', new TM::Literal ('OOOO') ]));

    ok (eq_set ([$tm->instances  ('thing')],      [map { $_->[TM->LID]} $tm->toplets]),                              'midlets (everything)');
    ok (eq_set ([$tm->tids ('rumsti', 'ramsti')], [map { $_->[TM->LID]} $tm->toplets ('rumsti', 'ramsti')]),         'midlets (explicit)');
    ok (eq_set ([$tm->instances  ('thing')],      [map { $_->[TM->LID]} $tm->toplets (\ '+all')]),                   'midlets (all)');

    ok (eq_set ([ keys %{ $TM::infrastructure->{mid2iid} }, $tm->tids ('rumsti', 'ramsti', 'remsti') ], 
		[ map { $_->[TM->LID]} $tm->toplets (\ '+all ')]),                                                   'midlets');

    ok (eq_set ([$tm->tids ('rumsti', 'ramsti', 'remsti') ], 
		[map { $_->[TM->LID]} $tm->toplets (\ '+all -infrastructure ')]),                                    'midlets (-infra)');

    ok (eq_set ([ $tm->toplets ],
		[ $tm->toplets (\ '+all ') ]),                                                                       'spec: impl = expl');

#warn Dumper [ sort map { $_->[TM->LID] } $tm->toplets (\ '+all ') ];
    ok (eq_set ([ map { $_->[TM->LID] }  $tm->toplets (\ '+all -infrastructure +infrastructure') ],
		[ map { $_->[TM->LID] }  $tm->toplets (\ '+all ') ]),                                                'spec: expl, - +');
    ok (eq_set ([ map { $_->[TM->LID] }  $tm->toplets (\ '+all +infrastructure -infrastructure') ],
		[ map { $_->[TM->LID] }  $tm->toplets (\ '+all -infrastructure') ]),                                 'toplets spec, + -');
    ok (eq_set ([ map { $_->[TM->LID] }  $tm->toplets (\ '+all -infrastructure -infrastructure') ],
		[ map { $_->[TM->LID] }  $tm->toplets (\ '+all -infrastructure') ]),                                 'toplets spec, - -');

    ok (eq_set ([ map { $_->[TM->LID] }  $tm->asserts (\ '+all -names +names') ],
		[ map { $_->[TM->LID] }  $tm->asserts (\ '+all') ]),                                                 'asserts spec: - +');
    ok (eq_set ([ map { $_->[TM->LID] }  $tm->asserts (\ '+all -names +names +names') ],
		[ map { $_->[TM->LID] }  $tm->asserts (\ '+all +names') ]),                                          'asserts spec: - +');
    ok (eq_set ([ map { $_->[TM->LID] }  $tm->asserts (\ '+all -names -names') ],
		[ map { $_->[TM->LID] }  $tm->asserts (\ '+all -names') ]),                                          'asserts spec: - -');

    ok (eq_set ([ map { $_->[TM->LID] }  $tm->asserts ],
		[
		 '8858da88a2fed47eff8fd60e9bbc5f67',
		 'f6cad13ec8543fadf6e3f615ff825bdb',
		 'c667ce5f4e485b45698c75621bc63893',
		 '27171f029a95d996c1d95281c2f4a207',
		 '9aa74da04e36d6f5c05ffe1c91eab7d2',
		 '4cc6e8f01f478ad4da3e9219d1e325fe',
		 '99c6df083c9cfa2ad264553f33403d66',
		 '8168aba8d6a9284c70e9c461a8977892',
		 '95cbe2f86579c5f6a28fe5a197fc2df4',
		 '04da9fc6bfb1a1738e6bf6b7d1d99d85',
		 '7580e0151c0fb1d9aa9eb71f25ff4d64',
		 '97b634a43b47218b9970e86f61671ce9'
		 ]),                                                                                                 'asserts: all, enumerate');

    ok (eq_set ([ $tm->asserts ],
		[ $tm->asserts (\ '+all ') ]),                                                                       'asserts: all, impl = expl');

    ok (eq_set ([ map { $_->[TM->LID] }  $tm->asserts (\ '+names +occurrences') ],
		[ map { $_->[TM->LID] }  $tm->asserts (\ '+occurrences +names') ]),                                  'asserts spec: + commutative');
#    warn Dumper [map {$_->{mid} } $tm->topics (\ '+all -infrastructure -associations -names -occurrences') ];
    is (scalar $tm->asserts (\ '+all -infrastructure -associations -names -occurrences'),	0,                   'asserts spec: all gone');
    is (scalar $tm->asserts (\ '+all -infrastructure -associations        -occurrences'),	1,                   'asserts spec: only name');
    is (scalar $tm->asserts (\ '+all -infrastructure -associations -names             '),	1,                   'asserts spec: only assoc');
    is (scalar $tm->asserts (\ '+all -infrastructure               -names -occurrences'),	2,                   'asserts spec: all user');

    eval {
	$tm->toplets (\ 'rumsti');
    }; like ($@, qr/unhandled/i, _chomp($@));

    eval {
	$tm->toplets (\ '+rumsti');
    }; like ($@, qr/unknown/i, _chomp($@));
}

{ # testing reification
    use TM;
    my $tm = new TM (baseuri => 'tm:');

    $tm->internalize (bbb => 'http://bbb/');
    is ($tm->reifies ('tm:bbb'), 'http://bbb/',                                    'forward reification (extern)');
    is_deeply ([ $tm->is_reified ('http://bbb/') ], [ 'tm:bbb' ],                  'backwards reification (extern)');

    is ($tm->tids ('http://bbb/'), 'tm:bbb',                                       'identification via tids');


    my ($a) = $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'ramsti' ]));
    $tm->internalize (aaa => $a);
    is_deeply ([ $tm->is_reified ($a) ], [ 'tm:aaa' ],                             'backwards reification (intern)');
    is ($a, $tm->reifies ('tm:aaa'),                                               'forward reification (intern)');

    my ($b) = $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'superclass', 'subclass' ], players => [ 'rumsti', 'remsti' ]));
    is_deeply ([ $tm->is_reified ($b) ], [ ],                                      'backwards reification (empty)');

    $tm->internalize (undef, $b);
#warn Dumper $tm;
    my ($tid) = $tm->is_reified ($b);
    like ($tid, qr/^tm:uuid/,                                                      'backwards reification (autogen)');

    is_deeply ([ $tm->is_reified ($tm->reifies ($tid)) ], [ $tid ],                'reification roundtrip');

    eval {
	$tm->internalize ($tid => 'http://bbb/');
    }; like ($@, qr/duplicate subject address/,                                    'detected error: duplicate reification');

}

{
    use TM;
    my $tm = new TM (baseuri => 'tm:');
    $tm->internalize ('aaa');
    ok (eq_array ( [$tm->tids ('aaa')], [ 'tm:aaa' ]), 'found inserted');
    $tm->clear;
    ok (eq_array ([ $tm->tids ('aaa') ], [ undef ]),             'inserted is gone now');
}


__END__



TODO: are_instances, ...filters



TODO: variants

