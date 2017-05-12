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

use TM;
use TM::PSI;

sub _parse {
  my $text = shift;
  my $ms = new TM (baseuri => 'tm:');
  my $p  = new TM::LTM::Parser (store => $ms);
  my $i  = $p->parse ($text);
#  use TM::Materialized::AsTMa;
#  TM::Materialized::AsTMa::_assert_implicits ($ms, $i);
  return $ms;
}

sub die_ok {
    my $ltm = shift;
    my $err = shift;
    eval {
	_parse ($ltm);
	fail ("exc: expected $@");
    };
    chomp ($@);
    my $verr = $@;
    $verr =~ s/\n/\n /g; # create blanks/comments on multiline complaints
    like ($@, qr/$err/, "exc: found '$verr'");
}

sub _q_players {
    my $ms = shift;
    my @res = $ms->match (TM->FORALL, @_);
#    warn "res no filter ".Dumper \@res;
    @res = grep ($_ !~ m|^tm:|, map { ref($_) ? ${$_} : $_ } map { @{$_->[TM->PLAYERS]} } $ms->match (TM->FORALL, @_));
#    warn "res ".Dumper \@res;
    return \@res;
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS ===========================================================================

require_ok( 'TM::Materialized::LTM' );

{
  my $tm = new TM::Materialized::LTM (inline => '
');

  ok ($tm->isa('TM::Materialized::Stream'),  'correct class');
  ok ($tm->isa('TM::Materialized::LTM'),   'correct class');

}

{ # comments
    my $ms = _parse (q|
[ aaa ]

/* some comment [ bbb ] 

*/

[ ccc ]
|);
#warn Dumper $ms;
    ok ($ms->tids ('aaa'), 'comment: outside');
    ok (!$ms->tids ('bbb'), 'comment: inside');
    ok ($ms->tids ('ccc'), 'comment: outside');
}

die_ok (q{
/*  [ aaa ]
     */  */ 
}, 'unparseable', 'invalid comment nesting');

{ # encoding
    my $ms = _parse (q|

@"utf-8"

[ aaa ]

|);
ok (1, 'encoding: ignored');
}

{ # topic address
    my $ms = _parse (q|
 [aaa % "urn:aaa" ]
|);
#    warn Dumper $ms;
    is ($ms->tids ('aaa'), $ms->tids ('urn:aaa'), 'reification: subject identifier ok');
}


{ # subject indicators
    my $ms = _parse (q|
 [aaa % "urn:aaa" @ "urn:xxx" @ "urn:yyy" ]
|);
#    warn Dumper $ms;

    ok (eq_set ($ms->midlet ($ms->tids ('urn:aaa'))->[TM->INDICATORS],
		[ 'urn:xxx', 'urn:yyy' ]),                          'indication: all found');
}

{ # topics types
    my $ms = _parse (q|
 [aaa: bbb ccc ]
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa');
    ok (eq_set ([ map { $_->[TM->PLAYERS]->[0]  } @res ],
		[ 'tm:bbb', 'tm:ccc' ]), 'topic: class values');
}

{ # topic basename
    my $ms = _parse (q|
 [aaa: bbb ccc = "AAA" ]
|);
#warn Dumper $ms;

    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAA' ]), 'topic: AAA basename');
}

{ # topic scoped basename
   my $ms = _parse (q|
[aaa: bbb ccc = "AAAS" / sss ]
		    |);
#warn Dumper $ms;
    ok (eq_set ([ map {$_->[0]}  map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, scope => 'tm:sss', type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAAS' ]), 'topic: AAA basename (scoped)');

    ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:sss' ) == 1, 'scope isa scope');
}

{ # topic, basename, sortname
my $ms = _parse (q|
[aaa: bbb ccc = "AAA" ; "SORTAAA" ]

[xxx: yyy = "XXX";  "SORTXXX"; "DISPXXX" ]

[uuu = "UUU";  "SORTUUU"; "DISPUUU" ]

[vvv = "VVV";  "SORTVVV"; "DISPVVV" / sss ]
|);
#warn Dumper $ms;
    ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAA' ]), 'topic: AAA basename');
#    ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
#		[ 'SORTAAA' ]), 'topic: SORTAAA basename');
}

{ # topic external occurrence (typed)
    my $ms = _parse (q|
{aaa, bbb, "http://xxxt/" }
		  |);
#warn Dumper $ms;
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:bbb',        iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: occurr typed');
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: occurr (typed)');
}


# untyped is not allowed in LTM?

{ # topic internal occurrence
    my $ms = _parse (q|
{aaa, bbb, [[http://xxxt/]] }
		  |);
#warn Dumper $ms;
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:bbb',        iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: int occurr typed');
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: int occurr (typed)');
}

{ # mix occurrences with topics
    my $ms = _parse (q|
[ aaa : bbb ]
{ aaa, xxx, "http://xxx/" }

{ ccc, yyy, "http://yyy/" }
[ ccc : ddd ]

|);

#warn Dumper $ms;

   ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ) == 1, 'topic+occur: class');
   ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ccc' ) == 1, 'topic+occur: class');

   ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	       [ 'http://xxx/' ]), 'topic+occur: occurr');
   ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:ccc' ) ] ,
	       [ 'http://yyy/' ]), 'topic+occur: occurr');
}

#-- assocs --------------

{
    my $ms = _parse (q|
aaa (play1: role1, play2: role2)

bbb (play1: role1, play2: role2)

ccc (play1, play2: role2)
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'tm:role1', 'tm:role2' ]), 'assoc: roles');

       @res = $ms->match (TM->FORALL, type => 'tm:bbb');
    ok (scalar @res == 1, 'assoc: separate');


       @res = $ms->match (TM->FORALL, type => 'tm:ccc');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'thing', 'tm:role2' ]), 'assoc: roles (default)');
}

{ # scoped assoc
    my $ms = _parse (q|
aaa (play1: role1, play2: role2) / sss

aaa (play1: role1, play2: role2)

aaa (play1: role1, play2: role2) / ttt

		     |);
##warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (scalar @res == 3, 'scoped mixed assoc: number');

    ok (grep ($_->[TM->SCOPE] eq 'tm:ttt', @res), 'scoped mixed assoc: scoping');
    ok (grep ($_->[TM->SCOPE] eq 'tm:sss', @res), 'scoped mixed assoc: scoping');
    ok (grep ($_->[TM->SCOPE] eq 'us',  @res), 'scoped mixed assoc: scoping');

    foreach my $r (@res) {
	ok (eq_set ([ @{$r->[TM->PLAYERS]} ],
		    [ 'tm:play1', 'tm:play2' ]), 'scoped mixed assoc: players');
	ok (eq_set ([ @{$r->[TM->ROLES]} ],
		    [ 'tm:role1', 'tm:role2' ]), 'scoped mixed assoc: roles');
    }
}

{ # assoc with nested topic
    my $ms = _parse (q|
aaa ( [ play1: ccc ]:  role1, play2: role2)
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc + embed: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'tm:role1', 'tm:role2' ]), 'assoc + embed: roles');

    @res = $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:play1');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:ccc' ]), 'assoc + embed: types');
}

# reifications

{ # reified assocs
    my $ms = _parse (q|
aaa ( play1: role1, play2: role2) ~ xxx

|);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'tm:aaa');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'assoc reification');
}

{ # reified occurrence
    my $ms = _parse (q|
{aaa, bbb, "http://xxxt/" } ~ xxx
		     |);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'tm:bbb');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'occurrence reification');
}

{ # reified basename
    my $ms = _parse (q|
[ aaa = "AAA" ~ xxx ]
		     |);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'name');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'basename reification');
}

#== Directives ========================

{ # wrong VERSION format
    die_ok (q|
#VERSION "123"
|, 'not supported');
}


{ # wrong VERSION
    die_ok (q|
#VERSION "1.4"
|, 'not supported');
}

{ # VERSION
    my $ms = _parse (q|

#VERSION "1.3"

[ aaa ]
|);

ok (1, 'version supported');
}

{ # TOPICMAP
    die_ok (q|
#TOPICMAP ~ xxxx
|, 'use proper');
}


{ # INCLUDE
    die_ok (q|
[aaa]

#INCLUDE "xyz:abc"
|, 'unable to load');

}

{ # INCLUDE
    my $ms = _parse (q|
[ aaa ]

#INCLUDE "inline: [ bbb ]"

[ ccc ]
|);
#    warn Dumper $ms;

    ok ($ms->midlet ('tm:aaa'), 'include: topic');
    ok ($ms->midlet ('tm:bbb'), 'include: topic');
    ok ($ms->midlet ('tm:ccc'), 'include: topic');
}

{
    die_ok (q|

aa:uuu (bbb:play: bbb:role)

|, 'unparseable');
}

{ # PREFIXES
    my $ms = _parse (q|

#PREFIX aaa @ "http://xxxx/#"
#PREFIX bbb @ "http://yyyy/#"

aaa:uuu (play: bbb:role)

|);

#    warn Dumper $ms;
    
    my @res = $ms->match (TM->FORALL, type => $ms->tids ('http://xxxx/#uuu'));
    ok (scalar @res == 1, 'prefixed assoc name: found');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play' ]), 'unprefixed player name');

    my $id = $ms->tids ('http://yyyy/#role');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ $id ]), 'prefixed role name');
}

die_ok (q{
#MERGEMAP "inline: [ bbb ]" "rumsti"
}, 'unsupported', 'invalid TM format');

{ # MERGEMAP
    my $ms = _parse (q|
#MERGEMAP "inline: [ bbb ]" "ltm"

[ aaa ]

[ ccc ]
|);
#    warn Dumper $ms;

TODO: {
    local $TODO = "merging";
    ok ($ms->tids ('aaa'), 'merge: topic');
    ok ($ms->tids ('bbb'), 'merge: topic');
    ok ($ms->tids ('ccc'), 'merge: topic');
}
}

{ # MERGEMAP (default
    my $ms = _parse (q|
#MERGEMAP "inline: [ bbb ]"

[ aaa ]

[ ccc ]
|);
#    warn Dumper $ms;

TODO: {
    local $TODO = "merging (default)";
    ok ($ms->tids ('aaa'), 'merge: topic');
    ok ($ms->tids ('bbb'), 'merge: topic');
    ok ($ms->tids ('ccc'), 'merge: topic');
}
}


__END__



__END__

die_ok (q{
format-for ([ ltm ] : standard, topic-maps )

@"abssfsdf"

}, 1, 'invalid encoding');

$tm = new XTM (tie => new XTM::LTM ( text => q{
  

@"iso8859-1"

 { ltm , test , [[Ich chan Glaas ässe, das tuet mir nöd weeh]] }

}));

like ($tm->topic ('ltm')->occurrences->[0]->resource->data, qr/\x{E4}sse/, 'encoding from iso8859-1');



die_ok (q{
format-for ([ ltm ] : standard, topic-maps )

xxxx

{ ltm , test , "http://rumsti/" }
}, 1, 'unknown keyword');

die_ok (q{
format-for ([ ltm ] : standard, topic-maps 
}, 1, 'missing terminator 1');

die_ok (q{
[ ltm : format <= "The linear topic map notation" @ "http://something1/" @ "http://something2/" ]
}, 1, 'invalid terminator 1');

die_ok ('
{ ltm , test , "http://rumsti/" '
, 1, 'missing terminator 2');

die_ok ('
{ ltm , test , "http://rumsti/" } abc'
, 1, 'additional nonparsable text');


$tm = new XTM (tie => new XTM::LTM ( text => q{
  [ ltm ]
  { ltm , test , [[http://rumsti/
ramsti romsti ]] }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 1, 'occurrence with topic');
is (@{$tm->topics('occurrence regexps /romsti/')}, 1, 'occurrence with topic, multiline');

#print Dumper $tm;

$tm = new XTM (tie => new XTM::LTM ( text => q{
  [ ltm ]
  { ltm , test , "http://rumsti/" }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 1, 'occurrence with topic');
is (@{$tm->topics()},                              2, 'occurrence with topic, 2');

#print Dumper $tm;

$tm = new XTM (tie => new XTM::LTM ( text => q{
  { ltm , test ,  "http://rumsti/" }
  { ltm , test2 , "http://ramsti/" }
  { ltm2, test ,  "http://rumsti/" }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 2, 'occurrence wo topic');


$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation" @ "http://something1/" @ "http://something2/" ]
}));
is (@{$tm->topics('indicates regexps /something1/')}, 1, 'subject indication1');
is (@{$tm->topics('indicates regexps /something2/')}, 1, 'subject indication2');

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation" % "http://something/" ]
}));
is (@{$tm->topics('reifies regexps /something/')}, 1, 'subject reification');



#__END__

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation"  ]
}));
is (@{$tm->topics('baseName regexps /linear/')}, 1, 'basename wo scope');

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation / scope1"  ]
}));
is (@{$tm->topics('baseName regexps /linear/')}, 1, 'basename with scope');


#__END__



# with types
my @types = qw(format1 format2 format3);
$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : }.join (" ", @types).q{  ]
}));
is (@{$tm->topics()}, 4, 'topic with types');
foreach my $t (@types) {
  is (@{$tm->topics("is-a $t")}, 1, "finding $t");
}

