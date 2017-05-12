use strict;
use warnings;

use Test::More qw(no_plan);
##use Test::Deep;

use Data::Dumper;
$Data::Dumper::Indent = 1;
use TM::Materialized::AsTMa;

#== TESTS ===========================================================================
my $tm = new TM::Materialized::AsTMa (baseuri=>"tm://", inline=> '
nackertes_topic 

atop
bn: just a topic

btop (ctop)
bn: something
bn@ascope: some other thing

ctop
bn: over the top!
in: something
in: somemore
oc: http://somewhere
in@ascope: scoped
in@ascope (sometype): also typed
oc (sometype): http://typedoc
oc @ascope (sometype): http://typedandscopedoc

(sucks-more-than)
sucker: ctop
winner: atop
winner: others

(sucks-more-than) @ascope
sucker: nobody
winner: nobody

thistop reifies http://rumsti
bn: reification
in: reification
sin: http://nowhere.never.ever
sin: http://nowhere.ever.never

(sucks-more-than) is-reified-by atop
winner: nobody
sucker: nobody

')->sync_in;

Class::Trait->apply ($tm, "TM::Serializable::XTM");

can_ok $tm, 'serialize';

{
    my $content = $tm->serialize (version => '1.0');

#warn $content;
    use XML::LibXML;
    my $xp  = XML::LibXML->new();
    my $doc = $xp->parse_string($content);

#   use XML::LibXML::Dtd;
    my $dtd = XML::LibXML::Dtd->new("-//TopicMaps.Org//DTD XML Topic Map (XTM) 1.0//EN",'schemas/xtm10.dtd');
    ok ( $doc->validate($dtd), 'validates XTM 1.0');
    
    ok (eq_set ([
		 map { "tm://$_" }
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic/@id')
		 ],
		[
		 map { $_->[TM->LID] } $tm->toplets (\ '+all -infrastructure')
		 ]), 'topic ids');
    
    ok (
	eq_set ([
		 map { $_->nodeValue }
		 $doc->findnodes('/topicMap/topic[@id="btop"]/instanceOf/topicRef/@xlink:href')
		],
		[
	          '#ctop',
		]
		), 'instance btop');

    ok ($doc->findnodes('/topicMap/association[@id="a068ce15eb7cf7cc4536d504c73a4c05c"]/instanceOf/topicRef[@xlink:href="#sucks-more-than"]'),
	'found assoc');
    
    ok (
	eq_set ([
		 map { $_->nodeValue }
		 $doc->findnodes('/topicMap/association[@id="a4abe49897cefeb950e4affaab0418e4f"]/member[roleSpec/topicRef/@xlink:href = "#winner"]/topicRef/@xlink:href')
                ],
		[
		 '#atop', '#others'
		 ]
		), 'found assoc');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="btop"]/baseName/baseNameString/text()')
		 ],
		['something', 'some other thing' ]), 'basename value');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="btop"]/baseName[scope/topicRef/@xlink:href = "#ascope"]/baseNameString/text()')
		 ],
		['some other thing' ]), 'basename value, scoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="ctop"]/occurrence[instanceOf/topicRef/@xlink:href = "#sometype"]/resourceRef/@xlink:href')
		 ],
		[
		 'http://typedoc',
		 'http://typedandscopedoc'
		 ]), 'occ value, scoped and unscoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="ctop"]/occurrence[instanceOf/topicRef/@xlink:href = "#sometype"][scope/topicRef/@xlink:href = "#ascope"]/resourceRef/@xlink:href')
		 ],
		[
		 'http://typedandscopedoc'
		 ]), 'occ value, scoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="thistop"]/subjectIdentity/subjectIndicatorRef/@xlink:href')
		 ],
		[
		 'http://nowhere.never.ever',
		 'http://nowhere.ever.never'
		 ]), 'indicators');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="thistop"]/subjectIdentity/resourceRef/@xlink:href')
		 ],
		[
		 'http://rumsti'
		 ]), 'address');

    ok (! $doc->findnodes('/topicMap/topic[@id="ctop"]/subjectIdentity/resourceRef/@xlink:href'),         'no address');
    ok (! $doc->findnodes('/topicMap/topic[@id="ctop"]/subjectIdentity/subjectIndicatorRef/@xlink:href'), 'no indicators');

    my ($aid) = map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="atop"]/subjectIdentity/topicRef/@xlink:href');

    ok ($aid =~ /^\#a.{32}$/, 'internal reification');

    $aid =~ s/\#//;

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes(qq|/topicMap/association[\@id="$aid"]/member
						       [roleSpec/topicRef/\@xlink:href = "#winner"]
						       /topicRef/\@xlink:href|)
		 ],
		[
		 '#nobody'
		 ]), 'reified assoc, role + players');
    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes(qq|/topicMap/association[\@id="$aid"]/member
						       [roleSpec/topicRef/\@xlink:href = "#sucker"]
						       /topicRef/\@xlink:href|)
		 ],
		[
		 '#nobody'
		 ]), 'reified assoc, role + players II');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[count(*) = 0]/@id')
		 ],
		[
		 'nackertes_topic',
		 'nobody',
		 'others',
		 'sometype',
		 'sucker',
		 'sucks-more-than',
		 'winner'
		 ]), 'empty topics');

#print Dumper [
#	      map { $_->nodeValue } $doc->findnodes('/topicMap/topic[count(*) = 0]/@id')
#	     ];
}

{
    my $content = $tm->serialize (omit_trivia => 1, version => '1.0');

    use XML::LibXML;
    my $xp  = XML::LibXML->new();
    my $doc = $xp->parse_string($content);
    
    ok (eq_set ([
		 map { "tm://$_" }
		 (
		 'nackertes_topic',
		 'nobody',
		 'others',
		 'sometype',
		 'sucker',
		 'sucks-more-than',
		 'winner',
		  map { $_->nodeValue } $doc->findnodes('/topicMap/topic/@id')
		  )
		 ],
		[
		 map { $_->[TM->LID] } $tm->toplets (\ '+all -infrastructure')
		 ]), 'topic ids');
}

{
    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    can_ok $tm2, 'deserialize';

    $tm2->deserialize ($tm->serialize (version => '1.0'));

#warn Dumper $tm2;

    is_deeply( $tm->{mid2iid},    $tm2->{mid2iid},    'toplet structure identical' );
    is_deeply( $tm->{assertions}, $tm2->{assertions}, 'asserts structure identical' );
}

{
    my $content = $tm->serialize (version => '1.0');

    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($tm->serialize (version => '1.0'));
    my $content2 = $tm2->serialize (version => '1.0');
    is ($content, $content2, 'round tripping');

#    use Text::Diff;
#    my $diff = diff \$content, \$content2, { STYLE => "Context" }; #,   \%options;
#    warn Dumper $diff;
}


{ #-- create name reification
    my ($name, $occ) = $tm->match_forall (char => 1, topic => $tm->tids ('thistop'));
    $tm->internalize ('thistop_name' => $name->[TM->LID]);  # create a reification
    $tm->internalize ('thistop_occ'  => $occ->[TM->LID]);   # create a reification
}

{ # version 1.0 cannot deal with name reification?
    my $tm2 = new TM;
    Class::Trait->apply ($tm2, 'TM::Serializable::XTM');

    my $c = $tm->serialize (version => '1.0');
#    warn $c;
    $tm2->deserialize ($c);

  TODO: {
      local $TODO = "name/occ reification support for XTM 1.0";
      is_deeply( $tm->{mid2iid},    $tm2->{mid2iid},    'toplet structure identical' ); 
      is_deeply( $tm->{assertions}, $tm2->{assertions}, 'asserts structure identical' );
  }
}

__END__

TODO: variants

