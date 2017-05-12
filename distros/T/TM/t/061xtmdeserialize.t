use strict;
use warnings;

use Test::More qw(no_plan);
##use Test::Deep;

use TM;
use Class::Trait;
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

#== TESTS ===========================================================================
{ # xtm default namespace
    my $content = q|<topicMap
   xmlns="http://www.topicmaps.org/xtm/1.0/"
   xmlns:xlink="http://www.w3.org/1999/xlink">
  <topic id="rumsti" />
</topicMap>
|;

    my $tm = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm, "TM::Serializable::XTM");
    $tm->deserialize ($content);
#warn Dumper $tm;
    is ($tm->tids ('rumsti'), 'tm://rumsti', 'default namespace: topic found');
}

{ # explicit namespace + prefix
    my $content = q|<xtm:topicMap
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:xtm="http://www.topicmaps.org/xtm/1.0/"
>
  <xtm:topic id="rumsti" />
</xtm:topicMap>
|;

    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($content);
#warn Dumper $tm2;
    is ($tm2->tids ('rumsti'), 'tm://rumsti', 'prefixed namespace: xtm: topic found');
}

{ # explicit namespace + prefix
    my $content = q|<bamsti:topicMap
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:bamsti="http://www.topicmaps.org/xtm/1.0/"
>
  <bamsti:topic id="rumsti" />
</bamsti:topicMap>
|;

    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($content);
#warn Dumper $tm2;
    is ($tm2->tids ('rumsti'), 'tm://rumsti', 'prefixed namespace: bamsti: topic found');
}



#-- start with actual parsing

sub _parse {
    my $xtm = shift;
    unless ($xtm =~ /<\?/) {
	$xtm = qq|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/'
          xmlns:xlink = 'http://www.w3.org/1999/xlink'
          xml:base="tm:"
          version="1.1">$xtm</topicMap>
|;
    }
    my $tm = new TM;
    Class::Trait->apply ($tm, "TM::Serializable::XTM");
    $tm->deserialize ($xtm);
    return $tm;
}

#--

my $npa = scalar keys %{$TM::infrastructure->{assertions}};
my $npt = scalar keys %{$TM::infrastructure->{mid2iid}};

#-- empty maps, attrs

{
    my $ms = _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' version="1.1">
</topicMap>
|);

#warn Dumper $ms;

    is (scalar $ms->match(), $npa, 'empty map 1 (assertions)');
    is ($ms->toplets,        $npt, 'empty map 2 (toplets)');
}

{ # baseuri
    my $ms = _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' version="1.1">
</topicMap>|
);
    is ($ms->baseuri, 'tm://nirvana/', 'default baseuri');

    $ms = _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' xml:base="tm:" version="1.1">
</topicMap>|
);
#warn Dumper $ms;
    is ($ms->baseuri, 'tm:', 'explicit baseuri');
}

{ # standalone topic
    my $ms = _parse (q|
  <topic id="aaa">
  </topic>
  <topic id="bbb"/>
|);
#warn Dumper $ms;
  ok ($ms->toplet ('tm:aaa'), 'found topic (default namespace)');
  ok ($ms->toplet ('tm:bbb'), 'found topic (default namespace)');
}

{ # standalone, but explicit namespace
    my $ms = _parse (q|<?xml version="1.0"?>
<xx:topicMap xmlns:xx='http://www.topicmaps.org/xtm/1.0/' 
             xmlns:xlink = 'http://www.w3.org/1999/xlink'
             xml:base="tm:" version="1.1">
   <xx:topic id="aaa">
   </xx:topic>
   <xx:topic id="bbb"/>
</xx:topicMap>|
);
  ok ($ms->toplet ('tm:aaa'), 'found topic (explicit namespace)');
  ok ($ms->toplet ('tm:bbb'), 'found topic (explicit namespace)');
}

{ # topic with instanceOf
  my $ms = _parse (q|
<topic id="aaa">
  <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
</topic>
|);
#warn Dumper $ms;
  ok ($ms->toplet ('tm:aaa'), 'found topic');
  ok ($ms->toplet ('tm:bbb'), 'found topic (implicit)');
  
  is (scalar $ms->match (TM->FORALL, type => 'isa', arole => 'instance', aplayer => 'tm:aaa', 
			                            brole => 'class',    bplayer => 'tm:bbb'), 1, 'one type for aaa');
}

{ # topic with instanceOfs
  my $ms = _parse (q|
<topic id="aaa">
  <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
  <instanceOf><topicRef xlink:href="#ccc"/></instanceOf>
</topic>
|);
#warn Dumper $ms;
  ok ($ms->toplet ('tm:aaa'), 'found topic');
  ok ($ms->toplet ('tm:bbb'), 'found topic (implicit)');
  ok ($ms->toplet ('tm:ccc'), 'found topic (implicit)');
  
  is (scalar $ms->match (TM->FORALL, type => 'isa', arole => 'instance', aplayer => 'tm:aaa', 
			                            brole => 'class'), 2, 'two types for aaa');
}

{ # topic with basename
  my $ms = _parse (q|
<topic id="aaa">
  <baseName>
     <baseNameString>AAA</baseNameString>
  </baseName>
</topic>
|);
#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name',        irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'basenames for aaa');
}

{ # topic with typed basename
  my $ms = _parse (q|
<topic id="aaa">
  <baseName>
     <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
     <baseNameString>AAA</baseNameString>
  </baseName>
</topic>
|);
#warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name',   irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'basenames for aaa (via bbb)');
  is (scalar $ms->match (TM->FORALL, type => 'tm:bbb', irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'basenames for aaa (via bbb)');
  ok ($ms->toplet ('tm:bbb'), 'found topic (implicit)');
}

{ # topic with typed, scoped basename
  my $ms = _parse (q|
<topic id="aaa">
  <baseName>
     <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
     <scope><topicRef xlink:href="#sss"/></scope>
     <baseNameString>AAA</baseNameString>
  </baseName>
</topic>
|);
#warn Dumper $ms;

  ok ($ms->toplet ('tm:sss'), 'found topic (implicit)');
  is (scalar $ms->match (TM->FORALL, type => 'tm:bbb',   irole => 'thing',  iplayer => 'tm:aaa' ), 1, 'scoped, typed basenames for aaa (via bbb)');
  is (scalar $ms->match (TM->FORALL, scope => 'tm:sss' ), 1,                                          'scoped, typed basenames for aaa (via bbb)');
}

{ # topic with resourceData occurrence
  my $ms = _parse (q|
<topic id="aaa">
  <occurrence>
     <resourceData>sldfsdlf</resourceData>
  </occurrence>
</topic>
|);
#  warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name',           irole => 'thing',    iplayer => 'tm:aaa' ), 0, 'occ: no basenames for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence',     irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'occ: occurrence for aaa');

  my ($o) = $ms->match (TM->FORALL, type => 'occurrence',      irole => 'thing',    iplayer => 'tm:aaa' );
  like ($o->[TM->PLAYERS]->[1]->[0], qr/sldfsdlf/, 'occ: value');
}

{ #scoped, typed resourceData occurrence
  my $ms = _parse (q|
<topic id="aaa">
  <occurrence>
     <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
     <scope><topicRef xlink:href="#sss"/></scope>
     <resourceData>sldfsdlf</resourceData>
  </occurrence>
</topic>
|);
#warn Dumper $ms;

  ok ($ms->toplet ('tm:bbb'), 'found topic (implicit)');
  ok ($ms->toplet ('tm:sss'), 'found topic (implicit)');
  is (scalar $ms->match (TM->FORALL, type => 'tm:bbb',      irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'occ: occurrence for aaa (via bbb)');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence',  irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'occ: occurrence for aaa');
}

{ # unscoped assoc
  my $ms = _parse (q|
<association>
  <instanceOf><topicRef xlink:href="#atype"/></instanceOf>
  <member>
     <roleSpec><topicRef xlink:href="#role2"/></roleSpec>
     <topicRef xlink:href="#player1"/>
  </member>
  <member>
     <roleSpec><topicRef xlink:href="#role1"/></roleSpec>
     <topicRef    xlink:href="#player2"/>
     <resourceRef xlink:href="http://player3/"/>
  </member>
</association>
|);
#warn Dumper $ms;

  my @m = $ms->match (TM->FORALL, type => 'tm:atype');
  ok (@m == 1, 'assoc: exactly one added');

#warn Dumper \@m;
  ok (eq_array (
		$m[0]->[TM->ROLES],
		[ 'tm:role1', 'tm:role1', 'tm:role2' ]
		), 'assoc: roles ok');
  ok (eq_array (
                $m[0]->[TM->PLAYERS],
                [ 'tm:player2', 'tm:uuid-0000000000', 'tm:player1' ]
                ), 'assoc: players ok');
  is ($m[0]->[TM->SCOPE], 'us', 'assoc: default scope');
  ok ($ms->toplet ('tm:role1'),   'assoc: found topic (implicit)');
  ok ($ms->toplet ('tm:role2'),   'assoc: found topic (implicit)');
  ok ($ms->toplet ('tm:player1'), 'assoc: found topic (implicit)');
  ok ($ms->toplet ('tm:player2'), 'assoc: found topic (implicit)');
}

{ # scoped assoc, defaults, id
  my $ms = _parse (q|
<association id="rumsti">
  <instanceOf><topicRef xlink:href="#atype"/></instanceOf>
  <scope><topicRef xlink:href="#ascope"/></scope>
  <member>
     <topicRef xlink:href="#player1"/>
  </member>
  <member>
     <roleSpec><topicRef xlink:href="#role1"/></roleSpec>
  </member>
</association>
|);
#warn Dumper $ms;

  my @m = $ms->match (TM->FORALL, type => 'tm:atype');

  ok (@m == 1, 'assoc: exactly one added');

#warn Dumper \@m;
  ok (eq_array (
		$m[0]->[TM->ROLES],
		[ 'thing' ]
		), 'assoc: roles ok');
  ok (eq_array (
                $m[0]->[TM->PLAYERS],
                [ 'tm:player1' ]
                ), 'assoc: players ok');

  is ($m[0]->[TM->SCOPE],  'tm:ascope', 'assoc: explicit scope');
  ok (!$ms->toplet ('tm:role1'),  'assoc: not found empty role topic (implicit)');
  ok ($ms->toplet ('tm:player1'), 'assoc: found topic (implicit)');

#  is ($m[0]->[TM->LID],    'tm:rumsti', 'assoc: explicit id');

  @m = $ms->match (TM->FORALL, scope => 'tm:ascope');
  ok (@m == 1, 'assoc: exactly one scoped');

}

{ # topic with subject indicator
  my $ms = _parse (q|
<topic id="aaa">
   <subjectIdentity>
      <subjectIndicatorRef xlink:href="http://rumsti"/>
      <subjectIndicatorRef xlink:href="http://remsti"/>
      <resourceRef xlink:href="http://ramsti"/>
   </subjectIdentity>
</topic>
|);
##  warn Dumper $ms;

  my $t = $ms->toplet ('tm:aaa');
  is ($t->[TM->ADDRESS], 'http://ramsti', 'subject address');
  ok (eq_set (
	      $t->[TM->INDICATORS],
	      ['http://rumsti', 'http://remsti' ]), 'subject indicators');
}

{ # mergeMap, die Kraetzn
# create tmp file
    my $tmp;
    use IO::File;
    use POSIX qw(tmpnam);
    do { $tmp = tmpnam().".xtm" ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

##warn "tmp is $tmp";

    my $fh = IO::File->new ("> $tmp") || die "so what?";
print $fh q|<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' xml:base="tm:" xmlns:xlink='http://www.w3.org/1999/xlink' version="1.1">
  <topic id="xxx"/>
  <topic id="yyy"/>
</topicMap>
|;
    $fh->close;

#    warn "# sleeping for 2 secs";
#    sleep 2;

    my $ms = _parse (qq|
<topic id="aaa"/>

<mergeMap xlink:href="file:$tmp"/>

|);
#  warn Dumper $ms;

    ok ($ms->toplet ('tm:xxx'),    'mergeMap: found topic');
    ok ($ms->toplet ('tm:yyy'),    'mergeMap: found topic');
    ok ($ms->toplet ('tm:aaa'),    'mergeMap: found topic');

    unlink ($tmp) || die "cannot unlink '$tmp' file";
}

eval {
    _parse (q|

<mergeMap xlink:href="file:/tmp/rumsti"/>

|);
    ok (0);
}; like ($@, qr/unable to load/i, "mergeMap: "._chomp $@);

#-- errorneous situations

eval {
    _parse (q|<?xml version="1.0"?>
<topicMaps xmlns='http://www.topicmaps.org/xtm/1.0/'/>
|);
}; like ($@, qr/unsupported/, _chomp $@);

eval {
    _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' version="1.2"/>
|);
    ok (0);
}; like ($@, qr/version/, _chomp $@);

eval {
    _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://wwwxxx.topicmaps.org/xtm/1.0/' version="1.0"/>
|);
    ok (0);
}; like ($@, qr/namespace/, _chomp $@);

eval {
    _parse (q|
<topic id="aaa">
  <instanceOf><topicRef xlink:href="#type"/></instanceOf>
  <baseName>
     <baseNameString>Testus</baseNameString>
  </baseName>
</toxxxxpic>
|);
    ok (0);
}; ok (1, scalar 'tag mismatch');

__END__

# TODO test for broken URIs

# welcher Schwachsinnige hat sich das einfallen lassen? multiple maps in a doc, i man....
eval {
    _parse (q|<?xml version="1.0"?>
<xxxx>
<topicMap xmlns = 'http://www.topicmaps.org/xtm/1.0/' version="1.1">
</topicMap>
<topicMap xmlns = 'http://www.topicmaps.org/xtm/1.0/' version="1.1">
</topicMap>
</xxxx>
|);
    ok (0);
}; like ($@, qr/sick/, $@);

__END__


{ # variant, who is actually using this crap?
  my $ms = _parse (q|
<topic id="aaa">
    <baseName>
         <baseNameString>something</baseNameString>
         <variant>
             <parameters><topicRef xlink:href="#param1"/></parameters>
             <variantName>name for param1</variantName>
             <variant>
                <parameters><topicRef xlink:href="#param3"/></parameters>
                <variantName>name for param3</variantName>
             </variant>
         </variant>
         <variant>
             <parameters><topicRef xlink:href="#param2"/></parameters>
             <variantName>name for param2</variantName>
         </variant>
    </baseName>
</topic>
|);
#warn Dumper $ms;

  my ($bn) = $ms->match (TM->FORALL, type => 'tm:has-basename',        irole => 'tm:thing',    iplayer => 'tm:aaa' );
  my $va = $ms->variants ($bn->[TM->LID]);

#warn Dumper $va;

  is ($va->{'tm:param1'}->{value}, 'name for param1', 'variant: value 1');
  is ($va->{'tm:param2'}->{value}, 'name for param2', 'variant: value 2');
  is ($va->{'tm:param1'}->{variants}->
           {'tm:param3'}->{value}, 'name for param3', 'variant: value 3');
}

