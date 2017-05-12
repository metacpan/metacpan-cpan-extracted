use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;
use Class::Trait;
use TM;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

#==================================================================

{ # xtm explicit namespace
    my $content = q|<topicMap
   xmlns="http://www.topicmaps.org/xtm/"
   version="2.0">
  <topic id="rumsti" />
</topicMap>
|;

    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($content);
#warn Dumper $tm2;
    is ($tm2->tids ('rumsti'), 'tm://rumsti', 'explicit namespace: topic found');
}

{ # xtm default namespace
    my $content = q|<topicMap
   version="2.0">
  <topic id="rumsti" />
</topicMap>
|;
    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($content);
#warn Dumper $tm2;
    is ($tm2->tids ('rumsti'), 'tm://rumsti', 'default namespace: topic found');
}

__END__

{ # explicit namespace + prefix
    my $content = q|<xtm:topicMap
   xmlns:xtm="http://www.topicmaps.org/xtm/" version='2.0'
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
   xmlns:bamsti="http://www.topicmaps.org/xtm/" version="2.0"
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

# eval {
#     my $content = q|<xxtopicMap xmlns='http://www.topicmaps.org/xtm/' version="2.0">
# </xxtopicMap>
# |;

#     my $tm2 = new TM (baseuri=>"tm://");
#     Class::Trait->apply ($tm2, "TM::Serializable::XTM");
#     $tm2->deserialize ($content);
#     ok (0);
# }; like ($@, qr/element/, 'topicMap missing');

#-- start with actual parsing

sub _parse {
    my $xtm = shift;
    unless ($xtm =~ /<\?/) {
	$xtm = qq|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/'
          xmlns:xlink = 'http://www.w3.org/1999/xlink'
          version="2.0">$xtm</topicMap>
|;
    }
    my $tm = new TM (baseuri => "tm:");
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
<topicMap xmlns='http://www.topicmaps.org/xtm/' version="2.0">
</topicMap>
|);

#warn Dumper $ms;

    is (scalar $ms->match(), $npa, 'empty map 1 (assertions)');
    is ($ms->toplets,        $npt, 'empty map 2 (toplets)');
}

{ # topic with basename
  my $ms = _parse (q|
<topic id="aaa">
  <name>
     <value>AAA</value>
  </name>
</topic>
|);
#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL, type => 'name',        irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'basenames for aaa');
}

{ # topic with typed basename
  my $ms = _parse (q|
<topic id="aaa">
  <name>
     <type><topicRef href="#bbb"/></type>
     <value>AAA</value>
  </name>
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
  <name>
     <type><topicRef href="#bbb"/></type>
     <scope><topicRef href="#sss"/></scope>
     <value>AAA</value>
  </name>
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

{ #-- XML data as string
  my $ms = _parse (q|
<topic id="aaa">
    <occurrence>
       <resourceData>
           <x:some  xmlns:x="html">text</x:some>
           <x:some2 xmlns:x="xhtml">text2</x:some2>
       </resourceData>
    </occurrence>
</topic>
|);

#warn Dumper $ms;
  my ($o) = $ms->match (TM->FORALL, type => 'occurrence',    irole => 'thing',    iplayer => 'tm:aaa' );
  is ($o->[TM->PLAYERS]->[1]->[1], TM::Literal->STRING, 'occ: XML as string');
  like ($o->[TM->PLAYERS]->[1]->[0], qr/<x:some /,  'occ: XML value 1');
  like ($o->[TM->PLAYERS]->[1]->[0], qr/<x:some2 /, 'occ: XML value 2');
  like ($o->[TM->PLAYERS]->[1]->[0], qr/xmlns:x="xhtml"/, 'occ: XML value 3');
}

{ #-- XML data as XML
  my $ms = _parse (q|
<topic id="aaa">
    <occurrence>
       <resourceData datatype="http://www.w3.org/2001/XMLSchema#anyType">
           <x:some  xmlns:x="html">text</x:some>
           <x:some2 xmlns:x="xhtml">text2</x:some2>
       </resourceData>
    </occurrence>
</topic>
|);

#warn Dumper $ms;
  my ($o) = $ms->match (TM->FORALL, type => 'occurrence',    irole => 'thing',    iplayer => 'tm:aaa' );
  is ($o->[TM->PLAYERS]->[1]->[1], TM::Literal->ANY, 'occ: XML as XML');
  like ($o->[TM->PLAYERS]->[1]->[0], qr/<x:some /,  'occ: XML value 1');
}

{ #-- URI as resourceData
  my $ms = _parse (q|
<topic id="aaa">
    <occurrence>
       <resourceData datatype="http://www.w3.org/2001/XMLSchema#anyURI">http://xxx.com/</resourceData>
    </occurrence>
</topic>
|);

#warn Dumper $ms;
  my ($o) = $ms->match (TM->FORALL, type => 'occurrence',    irole => 'thing',    iplayer => 'tm:aaa' );
  is ($o->[TM->PLAYERS]->[1]->[1], TM::Literal->URI, 'occ: URI');
  like ($o->[TM->PLAYERS]->[1]->[0], qr/http/,  'occ: URI');
}

{ #scoped, typed resourceData occurrence
  my $ms = _parse (q|
<topic id="aaa">
  <occurrence>
     <type><topicRef href="#bbb"/></type>
     <scope><topicRef href="#sss"/></scope>
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
  <type><topicRef href="#atype"/></type>
  <role>
     <type><topicRef href="#role2"/></type>
     <topicRef href="#player1"/>
  </role>
  <role>
     <type><topicRef href="#role1"/></type>
     <topicRef    href="#player2"/>
  </role>
</association>
|);
#warn Dumper $ms;

  my @m = $ms->match (TM->FORALL, type => 'tm:atype');
  ok (@m == 1, 'assoc: exactly one added');

#warn Dumper \@m;
  ok (eq_array (
		$m[0]->[TM->ROLES],
		[ 'tm:role1', 'tm:role2' ]
		), 'assoc: roles ok');
  ok (eq_array (
                $m[0]->[TM->PLAYERS],
                [ 'tm:player2', 'tm:player1' ]
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
  <type><topicRef href="#atype"/></type>
  <scope><topicRef href="#ascope"/></scope>
  <role>
     <type><topicRef href="#role1"/></type>
     <topicRef href="#player1"/>
  </role>
  <role>
     <type><topicRef href="#role2"/></type>
     <topicRef href="#player2"/>
  </role>
</association>
|);
#warn Dumper $ms;

  my @m = $ms->match (TM->FORALL, type => 'tm:atype');
  ok (@m == 1, 'assoc: exactly one added');

#warn Dumper \@m;
  ok (eq_array (
		$m[0]->[TM->ROLES],
		[ 'tm:role1', 'tm:role2' ]
		), 'assoc: roles ok');
  ok (eq_array (
                $m[0]->[TM->PLAYERS],
                [ 'tm:player1', 'tm:player2' ]
                ), 'assoc: players ok');

  is ($m[0]->[TM->SCOPE],  'tm:ascope', 'assoc: explicit scope');
  @m = $ms->match (TM->FORALL, scope => 'tm:ascope');
  ok (@m == 1, 'assoc: exactly one scoped');
}

{ # topic with subject indicator
  my $ms = _parse (q|
<topic id="aaa">
   <subjectIdentifier href="http://rumsti"/>
   <subjectIdentifier href="http://remsti"/>
   <subjectLocator    href="http://ramsti"/>
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

<mergeMap href="file:$tmp"/>

|);
#  warn Dumper $ms;

    ok ($ms->toplet ('tm:aaa'),    'mergeMap: found topic');
    ok ($ms->toplet ('tm:xxx'),    'mergeMap: found topic');
    ok ($ms->toplet ('tm:yyy'),    'mergeMap: found topic');

    unlink ($tmp) || die "cannot unlink '$tmp' file";
}

eval {
    _parse (q|

<mergeMap href="rumsti"/>

|);
    ok (0);
}; like ($@, qr/unable to load/i, "mergeMap: "._chomp $@);

eval {
    _parse (q|

<mergeMap xhref="rumsti"/>

|);
    ok (0);
}; like ($@, qr/missing/i, "mergeMap: "._chomp $@);

{ # assoc reification
  my $ms = _parse (q|
<association reifier="rumsti">
   <type><topicRef href="bumsti"/></type>
</association>
|);
# warn Dumper $ms;

  ok ($ms->toplet ('tm:rumsti'),    'reified assoc: found reifying topic');
  my $aid = $ms->toplet ('tm:rumsti')->[TM->ADDRESS];
  like ($aid, qr/.{32}/, 'assoc id sane');
  is ($ms->retrieve ($aid)->[TM->TYPE], 'tm:bumsti', 'assoc type')
}

{ # assoc reification with existing topics
  my $ms = _parse (q|
<topic id="rumsti"/>

<association reifier="rumsti">
   <type><topicRef href="bumsti"/></type>
</association>

<association reifier="ramsti">
   <type><topicRef href="bumsti"/></type>
</association>

<topic id="ramsti"/>

|);
# warn Dumper $ms;

  ok ($ms->toplet ('tm:rumsti'),    'reified assoc: found reifying topic');
  ok ($ms->toplet ('tm:ramsti'),    'reified assoc: found reifying topic');
  my $aid = $ms->toplet ('tm:rumsti')->[TM->ADDRESS];
  like ($aid, qr/.{32}/, 'assoc id sane');
  is ($ms->retrieve ($aid)->[TM->TYPE], 'tm:bumsti', 'assoc type');
  $aid = $ms->toplet ('tm:ramsti')->[TM->ADDRESS];
  like ($aid, qr/.{32}/, 'assoc id sane');
  is ($ms->retrieve ($aid)->[TM->TYPE], 'tm:bumsti', 'assoc type');
}

{ # name, occ reification with and without existing topics
  my $ms = _parse (q|
<topic id="ramsti"/>

<topic id="rumsti">
   <name reifier="ramsti"><value>AAA</value></name>
   <occurrence reifier="remsti"><resourceData>AAA</resourceData></occurrence>
</topic>

|);
# warn Dumper $ms;

  ok ($ms->toplet ('tm:rumsti'),    'reified chars: found topic');
  ok ($ms->toplet ('tm:ramsti'),    'reified assoc: found reifying topic');
  ok ($ms->toplet ('tm:remsti'),    'reified assoc: found reifying topic');

  my $aid = $ms->toplet ('tm:ramsti')->[TM->ADDRESS];
  like ($aid, qr/.{32}/, 'char id sane');
  is ($ms->retrieve ($aid)->[TM->KIND], TM->NAME, 'char kind');
  $aid = $ms->toplet ('tm:remsti')->[TM->ADDRESS];
  like ($aid, qr/.{32}/, 'char id sane');
  is ($ms->retrieve ($aid)->[TM->KIND], TM->OCC, 'char kind');
}

#-- errorneous situations

eval {
    _parse (q|<?xml version="1.0"?>
<topicMaps xmlns='http://www.topicmaps.org/xtm/1.0/'/>
|);
}; like ($@, qr/unsupported/, _chomp $@);

eval {
    _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' version="2.2"/>
|);
    ok (0);
}; like ($@, qr/version/, _chomp $@);

eval {
    _parse (q|<?xml version="1.0"?>
<topicMap xmlns='http://wwwxxx.topicmaps.org/xtm/' version="2.0"/>
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


__END__



TODO: variants
