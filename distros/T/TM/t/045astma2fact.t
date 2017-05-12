use strict;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

use TM;
use TM::PSI;

sub _parse {
  my $text = shift;
  my $ms = new TM (baseuri => 'tm:');
  my $p  = new TM::AsTMa::Fact2 (store => $ms);
  my $i  = $p->parse ($text);
  return $ms;
}

sub _q_players {
    my $ms = shift;
#    my @res = $ms->match (TM->FORALL, @_);
#    warn "res no filter ".Dumper \@res;
    my @res = grep ($_ !~ m|^tm:|, map { ref($_) ? $_->[0] : $_ } map { @{$_->[TM->PLAYERS]} } $ms->match (TM->FORALL, @_));
#    warn "res ".Dumper \@res;
    return \@res;
}

##===================================================================================

my $astma = 'http://astma.topicmaps.bond.edu.au/2.0/';

#== TESTS ===========================================================================

require_ok( 'TM::AsTMa::Fact2' );

{ # class ok
    my $p = new TM::AsTMa::Fact2;
    ok (ref($p) eq 'TM::AsTMa::Fact2', 'class ok');
}

my $npa = scalar keys   %{$TM::infrastructure->{assertions}};
my $npt = scalar values %{$TM::infrastructure->{mid2iid}};


{ #-- identification
    my $ms = _parse ('aaa
');
    is ($ms->tids ('aaa'), 'tm:aaa', 'aaa internalized');

    eval {
	my $ms = _parse ('aaa xxx ~ http://aaa/
');

    }; like ($@, qr/duplicate/i, _chomp($@));
}

{
    my $ms = _parse ('aaa ~ http://aaa/

bbb http://bbb/

ccc = http://ccc/
');
#warn Dumper $ms;
    is ($ms->tids ('aaa'), 'tm:aaa', 'aaa internalized');
    my $t = $ms->toplet ('tm:aaa');
    ok (eq_set (
		$t->[TM->INDICATORS],
		[
		 'http://aaa/',
		 ]), 'indicators');

    is ($ms->tids ('bbb'), 'tm:bbb', 'bbb internalized');
    $t = $ms->toplet ('tm:bbb');
    ok (eq_set (
		$t->[TM->INDICATORS],
		[
		 'http://bbb/',
		 ]), 'indicators');

    is ($ms->tids ('ccc'),         'tm:ccc', 'ccc internalized');
    is ($ms->tids ('http://ccc/'), 'tm:ccc', 'ccc internalized');
}

{
    my $ms = _parse ('aaa ~ http://aaa/  ~ http://bbb/ ~ http://ccc/

aaa
~ http://ddd/
  ~ http://eee/
        http://ccc/

');
#warn Dumper $ms;
    is ($ms->tids ('aaa'), 'tm:aaa', 'aaa internalized');
    my $t = $ms->toplet ('tm:aaa');
    ok (eq_set (
		$t->[TM->INDICATORS],
		[
		 'http://aaa/',
		 'http://bbb/',
		 'http://ccc/',
		 'http://ddd/',
		 'http://eee/'
		 ]), 'indicators');
}

#-- autogenerating ids

{
  my $ms = _parse (q|
* = http://aaa/

* = http://bbb/
|);
#warn Dumper $ms;

  like ($ms->tids ('http://aaa/'), qr/tm:uuid-\d{10}/, 'generated ids ok');
  like ($ms->tids ('http://bbb/'), qr/tm:uuid-\d{10}/, 'generated ids ok');

  eval {
      $ms = _parse (q|
* xxx = http://aaa/
|); }; like ($@, qr/duplicate/i, '* xxx fails: '._chomp($@));

  $ms = _parse (q|
xxx * = http://aaa/
|);
  ok (1, 'xxx * works');

  $ms = _parse (q|
* *
|);
  ok (1, '* * works, but weird');

}

{ # subject locators stand-alone
  my $ms = _parse (q|
= http://rumsti.com/ isa website

|);
#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL,                                       iplayer => $ms->tids ('http://rumsti.com/') ), 1, 'ext reification: finding');
}


{ #-- autogenerating date ids
  my $ms = _parse (q|
2004-01-12

2004-01-12T15:15
|);
#warn Dumper $ms;

  like ($ms->tids (\ 'urn:x-date:2004-01-12:00:00'), qr/tm:uuid-\d{10}/, 'generated dates ok');
  like ($ms->tids (\ 'urn:x-date:2004-01-12:15:15'), qr/tm:uuid-\d{10}/, 'generated dates ok');

}

{ #-- using ids with baseuri as prefix
  my $ms = _parse (q|
aaa

bbb isa tm:aaa

<< tm:bbb
tm:ccc : tm:aaa
|);
#warn Dumper $ms;

  is (scalar $ms->match(TM->FORALL, type => 'isa',    roles => [ 'class', 'instance'  ], players => [ 'tm:aaa',   'tm:bbb' ] ), 1, 'using baseuri 1');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc'  ],            players => [ 'tm:aaa' ] ),             1, 'using baseuri 2');
}

{ #-- predef inlineds (structural)
  my $ms = _parse (q|
aaa isa bbb

aaa is-a ccc

aaa subclasses ddd

|);

#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:aaa' ), 3, 'assocs for aaa');
}

{ # predef inlineds (struct + reification)
  my $ms = _parse (q|
xxx  isa http://www.topicmaps.org/xtm/1.0/#psi-topic
|);
#warn Dumper $ms;
  is (scalar $ms->match, $npa+1, 'reification: type');

  my $m = $ms->tids (\ 'http://www.topicmaps.org/xtm/1.0/#psi-topic');
  ok ($ms->is_asserted (Assertion->new (scope   => 'us',
					type    => 'isa',
					roles   => [ 'class', 'instance' ],
					players => [ $m, 'tm:xxx' ])), 'predef inlineds (struct + reification): xxx isa found');
  ok ($ms->is_asserted (Assertion->new (scope   => 'us',
					type    => 'isa',
					roles   => [ 'class', 'instance' ],
					players => [ $m, 'tm:xxx' ])), 'predef inlineds (struct + reification): xxx isa found (via tids)');
}

{ #-- characteristics (structural)
  my $ms = _parse (q|
aaa has bn : AAA   
bn: "BBB   " has oc: 23
in: bla has oc: http:www

|);

#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL,                                irole => 'thing',    iplayer => 'tm:aaa' ), 4, 'chars/assoc for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'characteristic',      irole => 'thing',    iplayer => 'tm:aaa' ), 4, 'chars for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence',          irole => 'thing',    iplayer => 'tm:aaa' ), 2, 'occurrences for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'name',                irole => 'thing',    iplayer => 'tm:aaa' ), 2, 'basenames for aaa');

  $ms = _parse (q|
bbb has nickname : "BBB"
firstname : CCC
lastname  : "DDD " has middlename: EEE
rumsti    : FFF

|);

#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL, type => 'name',                irole => 'thing',    iplayer => 'tm:bbb' ), 4, 'names for bbb');
  is (scalar $ms->match (TM->FORALL, type => 'tm:middlename',          irole => 'thing',    iplayer => 'tm:bbb' ), 1, 'names for bbb');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence',          irole => 'thing',    iplayer => 'tm:bbb' ), 1, 'occs for bbb');
  is (scalar $ms->match (TM->FORALL, type => 'tm:rumsti',              irole => 'thing',    iplayer => 'tm:bbb' ), 1, 'occs for bbb');

  $ms = _parse (q|
bbb has nickname : "BBB" and has firstname : CCC has lastname: "DDD"

bbb
nickname : BBB

bbb has nickname : "BBB" and which has firstname : CCC

bbb has nickname : "BBB" and which
firstname : "CCC" and which has lastname : DDD

|);

#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL, type => 'name',                irole => 'thing',    iplayer => 'tm:bbb' ), 4, 'names for bbb');

}

{ #-- predef inlineds + relatives (structural)
  my $ms = _parse (q|
aaa isa bbb , which isa ccc and which isa ddd and which has name : "BBB", and
name : "AAA" and which has nickname : "AAAAA" .

|);

#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:aaa' ), 3, 'assocs for aaa');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:bbb' ), 4, 'assocs for bbb');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:ccc' ), 1, 'assocs for ccc');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:ddd' ), 1, 'assocs for ddd');

  $ms = _parse (q|
aaa isa bbb, which isa ccc, which isa ddd and 
                            name : "CCC" , 
        name : "BBB", has name : "AAA"

|);

#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:aaa' ), 2, 'assocs for aaa');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:bbb' ), 3, 'assocs for bbb');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:ccc' ), 3, 'assocs for ccc');
  is (scalar $ms->match (TM->FORALL,                                    irole => 'thing',    iplayer => 'tm:ddd' ), 1, 'assocs for ddd');
}

#-- inlined values

{ # checking inlined subclassing
  my $ms = _parse (q|
aaa subclasses bbb

<< is-subclass-of
 superclass: ddd
 subclass: ccc

eee subclasses fff subclasses ggg

hhh < iii < jjj

|);
##warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:aaa', 'tm:bbb' ] ), 1, 'intrinsic is-subclass-of, different forms 1');
  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:ccc', 'tm:ddd' ] ), 1, 'intrinsic is-subclass-of, different forms 2');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:eee', 'tm:fff' ] ), 1, 'intrinsic is-subclass-of, different forms 3');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:eee', 'tm:ggg' ] ), 1, 'intrinsic is-subclass-of, different forms 4');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:hhh', 'tm:iii' ] ), 1, 'intrinsic is-subclass-of, different forms 5');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:hhh', 'tm:jjj' ] ), 1, 'intrinsic is-subclass-of, different forms 6');

}


{
  my $ms = _parse (q|
aaa

bbb isa thing

bbb isa ccc

ddd

eee isa bbb isa ccc isa ddd

|);
##warn Dumper $ms;

  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ccc',   'tm:bbb' ] ), 1, 'explicit isa 2');

  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ddd',   'tm:eee' ] ), 1, 'explicit isa 3');
  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ccc',   'tm:eee' ] ), 1, 'explicit isa 4');
  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:bbb',   'tm:eee' ] ), 1, 'explicit isa 5');
}


#-- characteristics, values

{ # testing toplets with characteristics
  my $ms = _parse (q|
xxx
bn: XXX
|);
##warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name', roles => [ 'value', 'thing' ], players => [ undef, 'tm:xxx' ]), 1, 'basename characteristics');
}

{
  # testing toplets with URI
  my $ms = _parse (q|
http://xxx
bn: XXX
|);
##warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name', roles   => [ 'value', 'thing' ], 
			                                players => [ $ms->tids (undef, 'http://xxx') ]), 1, 'basename characterisistics (reification)');
}

{ #-- name guessing
    my $ms = _parse (q|
bbb
nickname         : BBB    # should be name
firstname < oc   : CCC    # should be occurrence
lastname         : http://xxx/ # should be occurrence
middlename < name: EEE    # should be name
rumsti     < name: FFF    # should be name
remsti     < ccc : FFF    # should be nothing
|);
##warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name',                irole => 'thing',    iplayer => 'tm:bbb' ), 3, 'name guessing: names for bbb');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence',          irole => 'thing',    iplayer => 'tm:bbb' ), 2, 'name guessing: occurrence for bbb');
  is (scalar $ms->match (TM->FORALL, type => 'tm:ccc',                 irole => 'thing',    iplayer => 'tm:bbb' ), 1, 'name guessing: bogus type');
  is (scalar $ms->match (TM->FORALL, type => 'tm:remsti',              irole => 'thing',    iplayer => 'tm:bbb' ), 1, 'name guessing: bogus type');

}

{
my $ms = _parse (q|
aaa isa bbb
in:         blabla  
|);
##warn Dumper $ms;

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'blabla' ]), 'test blanks in resourceData 1');
}

{
  my $ms = _parse (q|
xxx
oc: http://xxx.com
ex: http://yyy.com
|);
##warn Dumper $ms;

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:xxx' ) ] ,
	      [ 'http://yyy.com', 'http://xxx.com' ]), 'occurrence char, value ok');
}

{  # adding types to characteristics
  my $ms = _parse (q|
aaa
 bn: AAA
 rumsti < name : AAAT
 oc: http://xxx/
 ramsti : http://xxxt/
 rimsti : http://yyy/
 rimsti : bla
|);
#warn Dumper $ms;
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } 
                      $ms->match (TM->FORALL, type => 'name',   iplayer => 'tm:aaa' ) ] ,
	      [ 'AAA', 'AAAT' ]), 'name typed & untyped char, value ok');
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } 
                grep ($_->[TM->TYPE] eq 'name', 
                      $ms->match (TM->FORALL, type => 'name',   iplayer => 'tm:aaa' )) ] ,
	      [ 'AAA' ]), 'basename untyped char, value ok');
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'tm:rumsti',         iplayer => 'tm:aaa' ) ] ,
	      [ 'AAAT' ]), 'basename typed char, value ok');

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'occurrence',     iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/',
		'http://yyy/',
		'http://xxx/',
		'bla' ]), 'occurr typed char, value ok');

  ok (eq_set (_q_players ($ms, type => 'tm:ramsti',         iplayer => 'tm:aaa' ) ,
	      [ 'http://xxxt/' ]), 'occurr typed char, value ok');
  ok (eq_set (_q_players ($ms, type => 'tm:rimsti',         iplayer => 'tm:aaa' ) ,
	      [ 
		'http://yyy/',
		'bla' ]), 'occurr typed char, value ok');
}

{ #  adding scopes to characteristics
  my $ms = _parse (q|
aaa
 bn: AAA
 bn @ sss : AAAS
 oc: III
 oc @ sss : IIIS
 oc: http://xxx/
 oc @ sss : http://xxxs/
|);
#warn Dumper $ms;

  ok (eq_set (_q_players ($ms, type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAA', 'AAAS' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'us', type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAA' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAAS' ]), 'basename untyped, scoped, value ok');

  ok (eq_set (_q_players ($ms, type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'III', 'IIIS', 'http://xxx/', 'http://xxxs/' ]), 'occurrences untyped, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'IIIS', 'http://xxxs/' ]), 'occurrences untyped, scoped, value ok');
}

{ # typed and scoped characteristics
  my $ms = _parse (q|
aaa
 ramsti < name: AAA
 rumsti @ sss < bn: AAAS
 oc: III
 ramsti @ sss: IIIS
 oc: http://xxx/
 ramsti @ sss < oc: http://xxxs/

|);
#  warn Dumper $ms;
  ok (eq_set (_q_players ($ms, type => 'tm:ramsti',   iplayer => 'tm:aaa' ),
	      [ 'AAA', 'IIIS', 'http://xxxs/' ]), 'basename typed, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'us', type => 'tm:ramsti',   iplayer => 'tm:aaa' ),
	      [ 'AAA' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'tm:rumsti',   iplayer => 'tm:aaa' ),
	      [ 'AAAS' ]), 'basename untyped, scoped, value ok');


  ok (eq_set (_q_players ($ms, type => 'name',   iplayer => 'tm:aaa' ),
	      [   'http://xxxs/',  'AAA',  'IIIS',  'AAAS' ]), 'basenames typed, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'http://xxxs/',  'http://xxx/', 'AAA',  'IIIS',  'III' ]), 'occurrences typed, mixscoped, value ok');
}

#-- structural: assocs ----------------------------------------------------------

{
   my $ms = _parse (q|
yyy << xxx ( role : player )

|);
##warn Dumper $ms;

  is (scalar $ms->match,                                                                                 $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:player' ), 1, 'finding basic association 1');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:player' ), 1, 'finding basic association 2');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:player' ), 1, 'finding basic association 3');

     $ms = _parse (q|
yyy << xxx ( role : p1 p2 p3 )
|);
##  warn Dumper $ms;

  is (scalar $ms->match,                                                                           $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:p1' ), 1, 'finding basic association 4');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:p2' ), 1, 'finding basic association 5');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:p3' ), 1, 'finding basic association 6');

     $ms = _parse (q|
yyy << xxx ( role1 : aaa bbb , role2 : ccc )

|);
##warn Dumper $ms;

  is (scalar $ms->match, $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                        iplayer => 'tm:aaa' ), 1, 'finding basic association 10');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                      iplayer => 'tm:ccc' ), 1, 'finding basic association 11');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role2', iplayer => 'tm:ccc' ), 1, 'finding basic association 12');

     $ms = _parse (q|
* << xxx ( role : player )

|);
#warn Dumper $ms;

  is (scalar $ms->match,                                                                                 $npa+1, 'basic association *');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:player' ), 1, 'finding basic association 1 *');
  like ( ($ms->match (TM->FORALL,        iplayer => 'tm:player' ))[0]->[TM::LID], qr/tm:uuid-\d{10}/, 'generated id for * assoc ok');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:player' ), 1, 'finding basic association 1 *');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:player' ), 1, 'finding basic association 2 *');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:player' ), 1, 'finding basic association 3 *');

     $ms = _parse (q|
<< xxx ( role : player )

|);
#warn Dumper $ms;

  is (scalar $ms->match,                                                                                 $npa+1, 'basic association no *');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:player' ), 1, 'finding basic association 1 no *');
  like (    ($ms->match (TM->FORALL,        iplayer => 'tm:player' ))[0]->[TM->LID], qr/[0-9a-f]{32}/,  'generated id for no * assoc ok');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:player' ), 1, 'finding basic association 2 no *');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:player' ), 1, 'finding basic association 3 no *');


      $ms = _parse (q|
yyy << xxx
       role1 : player1
       role2 : player2

|);
#warn Dumper $ms;

  is (scalar $ms->match,                                                                                 $npa+1, 'basic association eol');
  is (scalar $ms->match (TM->FORALL,                                        iplayer => 'tm:player1' ), 1, 'finding basic association 1 eol');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                      iplayer => 'tm:player2' ), 1, 'finding basic association 2 eol');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role1', iplayer => 'tm:player1' ), 1, 'finding basic association 3 eol');

}

{ # reified assoc/ value
  my $ms = _parse (q|
yyy << xxx
  role : player

|);
#warn Dumper $ms;

  my ($a) = $ms->match (TM->FORALL, type => 'tm:xxx');
  is ('tm:yyy', $a->[TM->LID], 'assoc reified: regained');
}

{ # scoping of assocs
  my $ms = _parse (q|
<< aaa @ sss
  role : player

|);
#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type=> 'isa',                     iplayer => 'tm:sss'    ),   1, 'association scoped 1');

  is (scalar $ms->match, $npa+2, 'association scoped');
  is (scalar $ms->match (TM->FORALL,                                      iplayer => 'tm:player' ),   1, 'association scoped 2');
  is (scalar $ms->match (TM->FORALL, scope => 'tm:sss',                   iplayer => 'tm:player' ),   1, 'association scoped 3');
}

{ # reification in assocs
  my $ms = _parse (q|
<< http://xxx
  http://role1 : aaa = http://bbb
  http://role2 : ccc
|);
#warn Dumper $ms;
  is (scalar $ms->match, $npa+1, 'reification: association');
  is (scalar $ms->match (TM->FORALL, type    =>   $ms->tids (\ 'http://xxx'), 
			             roles   => [ $ms->tids (\ 'http://role1', \ 'http://role2', \ 'http://role1') ],
			             players => [ $ms->tids ('tm:aaa', undef, 'http://bbb') ] ), 1, 'reification: association');
}

#-- prefixes --------------------------

{
  my $ms = _parse (q|
xsd  isa astma:ontology ~ http://www.w3c.org/xsd/

tmql isa astma:ontology ~ http://www.isotopicmaps.org/tmql/

aaa subclasses xsd:integer

bbb isa tmql:function

<< aaa
tmql:function : ccc

<< ddd
bbb: tmql:function

|);
#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'isa', iplayer => 'ontology' ),                                             2, 'finding all ontologies');
  is (scalar $ms->match (TM->FORALL, type => 'is-subclass-of', iplayer => $ms->tids (\ 'http://www.w3.org/2001/XMLSchema#integer' )), 1, 'prefixed tid as player');

  is (scalar $ms->match (TM->FORALL, type => 'tm:ddd', iplayer => $ms->tids (\ 'http://www.isotopicmaps.org/tmql/#function' )), 1, 'prefixed tid as assoc player');
  is (scalar $ms->match (TM->FORALL, type => 'tm:aaa', irole   => $ms->tids (\ 'http://www.isotopicmaps.org/tmql/#function' )), 1, 'prefixed tid as assoc role');
  is (scalar $ms->match (TM->FORALL, type => 'isa', iplayer => $ms->tids (\ 'http://www.isotopicmaps.org/tmql/#function' )), 1, 'prefixed tid as class player');
}

eval {
  my $ms = _parse (q|
tmql isa astma:ontology # this by itself is ok

xxx isa tmql:function   # here is must crash

|);
}; like ($@, qr/subject indicator/i, _chomp($@));

#-- templates --------------------


#-- inline templates first
eval {
   my $ms = _parse (q|
xxx bbb zzz

|);
}; like ($@, qr/duplicate ID/i, _chomp($@));

eval {
   my $ms = _parse (q|
ttt isa astma:template

xxx ttt zzz

|);
}; like ($@, qr/does not have/i, _chomp($@));

eval {
   my $ms = _parse (q|
ttt isa astma:template
return: xxxx
return: yyyy

xxx ttt zzz
|);
}; like ($@, qr/ambiguous/i, _chomp($@));

{ # static template
  my $ms = _parse (q|
ttt isa astma:template
return: """
<< bbb
ccc: ddd
eee: fff
"""

xxx ttt zzz

uuu ttt vvv

|);

#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:ddd',   'tm:fff' ] ), 1, 'template: static');
}

{ # left/right template
  my $ms = _parse (q|
ttt isa astma:template
return: """
<< bbb
ccc: {$_left}
eee: { $_right }
"""

xxx ttt zzz

uuu ttt vvv

|);

#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:xxx',   'tm:zzz' ] ), 1, 'template: dynamic');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:uuu',   'tm:vvv' ] ), 1, 'template: dynamic');
}

{ # left/right template
  my $ms = _parse (q|
ttt isa astma:template
return: """
<< bbb
ccc: {$_left}
eee: { $_right }
fff: { $aaa }
"""

xxx ttt (aaa : "ddd") zzz

uuu ttt (aaa : "ddd") vvv

|);
#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee', 'tm:fff'  ], players => [ 'tm:xxx', 'tm:zzz', 'tm:ddd' ] ), 1, 'template: dynamic');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee', 'tm:fff'  ], players => [ 'tm:uuu', 'tm:vvv', 'tm:ddd' ] ), 1, 'template: dynamic');
}

#-- standalone templates

{
  my $ms = _parse (q|
ttt isa astma:template
return: """
<< bbb
ccc: {$aaa}
eee: { $bbb  }
"""

ttt ( aaa : "xxx" , bbb : "yyy" )

ttt (aaa: "uuu", bbb: "vvv" )

ttt (aaa: "mmm", bbb: "nnn", ccc: "ooo" ) # one too much, is ignored

|);

#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:xxx',   'tm:yyy' ] ), 1, 'standalone template: dynamic');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:uuu',   'tm:vvv' ] ), 1, 'standalone template: dynamic');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:mmm',   'tm:nnn' ] ), 1, 'standalone template: dynamic');
}

eval {
  my $ms = _parse (q|
ttt isa astma:template
return: """
<< bbb
ccc: {$aaa}
eee: { $bbb  }
"""

ttt ( aaa : "xxx" )

|);
}; like ($@, qr/has no value/i, _chomp($@));

#-- template keep yes/no

{
  my $ms = _parse (q|
ttt isa astma:template
return: """
whatever
"""

xxx

|);

#warn Dumper $ms;
  ok (! $ms->tids ('ttt'), 'template ttt removed by default');
}

#-- syntactic issues ----------------------------------------------------------------

{ # comments
  my $ms = _parse (q|
# this is AsTMa

|);
#warn Dumper $ms;
  is (scalar $ms->match(), $npa, 'empty map 1 (assertions)');
  is ($ms->toplets,        $npt, 'empty map 2 (toplets)');
}

{
  my $ms = _parse (q|
# comment1

aaa isa bbbbb

#comment2

#comment4
ccc isa bbb
#comment3
#comment4
ddd isa xxxx
#comment5
|);
##warn Dumper $ms;

  is (scalar $ms->toplets, $npt+6, 'test comment/separation');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ), 1, 'types for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ccc' ), 1, 'type  for ccc');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ddd' ), 1, 'type  for ddd');
}

{ # inline comments
  my $ms = _parse (q|
aaa
bn: AAA  # comment
bn: AAA# no-comment
oc: http://rumsti#no-comment
|);
# warn Dumper $ms;

  is (scalar $ms->match, $npa+3, 'comment + assertions');

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
	      [ 'AAA',
		'AAA# no-comment' ]), 'getting back commented basename');
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://rumsti#no-comment' ]), 'getting back commented occ');
}

#-- syntactic issues ----------------------------------------------------------------

{ # empty line with blanks
  my $ms = _parse (q|
topic1
   
topic2

|);
##warn Dumper $ms;
  is (scalar $ms->toplets(), $npt+2, 'empty line contains blanks');
}

{ # empty lines with \r
    my $ms = _parse (q|
topic1topic2topic3
|);

    is (scalar $ms->toplets(), $npt+3, 'empty line \r contains blanks');
}

{ # using TABs as separators
    my $ms = _parse (q|
topic1	isa	topic2	

topic3  isa	topic4	
|);
#warn Dumper $ms;
    is (scalar $ms->toplets, $npt+2+2, 'using TABs as separators');
}

#-- syntactic issues ----------------------------------------------------------------

{ # line continuation with comments
    my $ms = _parse (q|

topic1
# comment \
topic2

|);
    is (scalar $ms->toplets, $npt+1, 'continuation in comment');
}

{ # line continuation with comments
    my $ms = _parse (q|

topic1
# comment \

topic2

|);
    is (scalar $ms->toplets, $npt+2, 'continuation in comment, not 1');
}

{ # line continuation with comments
    my $ms = _parse (q|
topic1
# comment \ 
topic2

|);
    is (scalar $ms->toplets, $npt+2, 'continuation in comment, not 2');
}

{ # line continuation
  my $ms = _parse (q|
aaa isa bbbbb \
isa cccc \
isa dddd

|
);
  is (scalar $ms->toplets, $npt+4, 'line continuation');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ), 3, 'continuation: types for aaa');
}

{ # line continuation, not
  my $ms = _parse (q|
aaa
 bn: AAA
 in: a \ within the text is ok
 in: also one with a \\ followed by a blank: \\ 
 in: this is a new one \\
 in: this is not a new one
|);
##warn Dumper $ms;

  my @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:aaa' );
  is (scalar @res, 3, 'ins for aaa');
#warn Dumper \@res;
##warn Dumper [ map { ${$_->[TM->PLAYERS]->[1]}} @res ];
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } @res ],
	      [ 'a \ within the text is ok',
		'also one with a \ followed by a blank: \\',   # blank is gone now
		'this is a new one  in: this is not a new one']), 'same text');
}

{ # line continuation, not \\
  my $ms = _parse (q|
# this is a continuation
aaa isa bbbb \
has bn: but not this \\\\
in: should be separate

|
);
##warn Dumper $ms;
  is (scalar $ms->match, $npa+3, 'line continuation, =3');
}

#-- syntactic issues ----------------------------------------------------------------
#-- line splitters  -----------------------------------------------

{ # line separation
  my $ms = _parse (q|
aaa isa bbb +++ bn: AAA +++ in: rumsti

ccc isa ddd +++ bn: CCC
|);
##  warn Dumper $ms;

  is (scalar $ms->match, $npa+5, '+++ assertions');
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
	      [ 'AAA' ]), 'AAA basename');
}

{ # line no split
  my $ms = _parse (q|
aaa isa bbb +++ bn: AAA +++ in: rumsti is using ++++ in: text

|);
##  warn Dumper $ms;
  is (scalar $ms->match, $npa+3, '++++ assertions');

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } $ms->match (TM->FORALL,  type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'rumsti is using +++ in: text' ]), 'getting back ++++ text');
}

#-- syntactic issues ----------------------------------------------------------------

{ # multi string detection
  my $ms = _parse (q|
bbb
in: """
xxxxxxxxxxxxx
yyyyyyyyyy
zzzzzz
"""

ccc
in: """\
rumsti
ramsti
romsti"""

|);
##  warn Dumper $ms;
  is (scalar $ms->match, $npa+2, 'multiline string detection');
  my @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:bbb' );
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0]} @res ],
	      [ '
xxxxxxxxxxxxx
yyyyyyyyyy
zzzzzz
',
		]), 'multiline string: same text ["""]');

  @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:ccc' );
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[1]->[0] } @res ],
	      [ 'rumsti
ramsti
romsti',
		]), 'multiline string: same text ["""]');
}

#-- syntax errors (assoc)

eval {
  my $ms = _parse (q|
<< xxx zzz
member : aaa
|);
}; like ($@, qr/Found ID but expected LPAREN/i, _chomp($@));

eval {
  my $ms = _parse (q|
<< xxx
|);
}; like ($@, qr/Found DOT but expected LPAREN/i, _chomp($@));

eval {
  my $ms = _parse (q|
<< xxx

rumsti

|);
}; like ($@, qr/Found DOT but expected LPAREN/i, _chomp($@));

eval {
  my $ms = _parse (q|
<< xxx
role : aaa
role2 : 

|);
}; like ($@, qr/Found DOT but expected ID/i, _chomp($@));

eval {
   my $ms = _parse (q|
<< aaa
aaa :

|);
   fail ("raises except on empty role");
}; like ($@, qr/Found DOT but expected ID/i, _chomp($@));

eval {
  my $ms = _parse (q|
<< 
role : player
|);
}; like ($@, qr/Found HAS but expected ID/i, _chomp($@));

eval {
   my $ms = _parse (q|
<< aaa
aaa:bbb

|);
fail ("raises except on empty role 2");
}; like ($@, qr/Found DOT but expected COLON/i, _chomp($@));

eval {
   my $ms = _parse (q|
<< ddd
bbb:aaa:ccc

|);
fail ("raises except on empty role 3");
}; like ($@, qr/Found DOT but expected COLON/i, _chomp($@));

#-- syntax errors (topics)

eval {
   my $ms = _parse (q|
ttt
bn:    
|);
## warn Dumper $ms;
}; like ($@, qr/Found DOT but expected VALUE/i, _chomp($@));

eval {
   my $ms = _parse (q|
ttt
oc: 
|);
}; like ($@, qr/Found DOT but expected VALUE/i, _chomp($@));

eval {
   my $ms = _parse (q|
ttt
in: 
|);
}; like ($@, qr/Found DOT but expected VALUE/i, _chomp($@));

#-- directives ------------------------------------------------------------

open (STDERR, '>/dev/null');

{ # cancel
  my $ms = _parse (q|
aaa

%cancel

bbb
|);
#warn Dumper $ms;
 is (scalar $ms->toplets, $npt+1, 'cancelling');
}

{ # log
  my $ms = _parse (q|
aaa

%log xxx

bbb
|);
 is (scalar $ms->toplets, $npt+2, 'logging');
}

{ # version
  my $ms = _parse (q|
%version 2.3

|);
  ok (1, "version ok");
}

eval { # version, not good
  my $ms = _parse (q|
%version 1.5

|);
}; like ($@, qr/unsupported/i, _chomp($@));

{
    my $tmp;
    use IO::File;
    use POSIX qw(tmpnam);
    do { $tmp = tmpnam().".atm" ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

    my $fh = IO::File->new ("> $tmp") || die "so what?";
    print $fh q|
aaa

ccc
|;
    $fh->close;

    my $ms = _parse (qq|

eee

%include file:$tmp

|);
#warn Dumper $ms;
    is ($ms->tids ('aaa'), 'tm:aaa', '%include: file, internalized');
    is ($ms->tids ('ccc'), 'tm:ccc', '%include: file, internalized');
    is ($ms->tids ('eee'), 'tm:eee', '%include: file, internalized');
}

{ # include with UNIX pipe
    my $ms = _parse (qq|

eee

%include (echo "aaa" ; echo ; echo "ccc" ; echo ) \|

|);
    is ($ms->tids ('aaa'), 'tm:aaa', '%include: pipe, internalized');
    is ($ms->tids ('ccc'), 'tm:ccc', '%include: pipe, internalized');
    is ($ms->tids ('eee'), 'tm:eee', '%include: pipe, internalized');

};

{ # encoding
  my $ms = _parse (q|
%encoding iso-8859-2

aaa
in: Ich chan Glaas ässe, das tuet mir nöd weeh

bbb
in: Mohu jíst sklo, neublí?í mi

|);
#warn Dumper $ms;

  my ($a) = $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' );
  like ($a->[TM->PLAYERS]->[1]->[0], qr/Ich/,       'encoding: iso-8859-2, normal text');
  like ($a->[TM->PLAYERS]->[1]->[0], qr/\x{E4}sse/, 'encoding: iso-8859-2, normal text');

  ($a) = $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:bbb' );
  like ($a->[TM->PLAYERS]->[1]->[0], qr/Mohu/,       'encoding: iso-8859-2, normal text');
  like ($a->[TM->PLAYERS]->[1]->[0], qr/\x{ED}st/,   'encoding: iso-8859-2, normal text');

}

#-- scopes as dates

TODO: {
   local $TODO = "scopes as dates";

  my $ms = _parse (q|
aaa
 bn : AAA
 bn @ 2004-01-12 : XXX
 bn @ 2004-01-12T12:23 : YYY
|);
#warn Dumper $ms;

  ok (eq_set (_q_players ($ms, scope => $ms->tids (\ 'http://psi.semagia.com/iso8601/2004-01-12'), type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'XXX' ]), 'date scoped 1');
  ok (eq_set (_q_players ($ms, scope => $ms->tids (\ 'http://psi.semagia.com/iso8601/2004-01-12T12:23'), type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'YYY' ]), 'date scoped 2');

}

__END__

