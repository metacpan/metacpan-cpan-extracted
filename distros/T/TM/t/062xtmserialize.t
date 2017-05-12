use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;
use TM::Materialized::AsTMa;

#== TESTS ===========================================================================
my $tm = new TM::Materialized::AsTMa (baseuri=>"tm://", inline=> '
nackertes_topic 

atop
bn: just a topic

btop (ctop dtop)
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
sin: http://nowhere.never.ever
sin: http://nowhere.ever.never

(sucks-more-than) is-reified-by atop
winner: nobody
sucker: nobody

thistop_name
bn: this will reify the thistop name
')->sync_in;

{
    my ($name) = $tm->match_forall (char => 1, topic => $tm->tids ('thistop'));
    $tm->internalize ('thistop_name' => $name->[TM->LID]);  # create a reification
}

Class::Trait->apply ($tm, "TM::Serializable::XTM");
can_ok $tm, 'serialize';

{
    my $content = $tm->serialize (version => '2.0');
#    warn $content;

    use XML::LibXML;
    my $xp  = XML::LibXML->new();
    my $doc = $xp->parse_string ($content);
#    use XML::LibXML::Dtd;
    my $dtd = XML::LibXML::Dtd->new("SOME // Public / ID / 1.0",'schemas/xtm20.dtd');
    ok ( $doc->validate($dtd), 'validates XTM 2.0');
}

{
    my $content = $tm->serialize (version => '2.0');
#    warn $content;exit;
    $content =~ s{xmlns="http://www.topicmaps.org/xtm/"}{};  # get rid of the namespace

    use XML::LibXML;
    my $xp  = XML::LibXML->new();
    my $doc = $xp->parse_string ($content);

    ok (eq_set ([
		 map { "tm://$_" }
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic/@id')
		 ],
		[
		 map { $_->[TM->LID] } $tm->toplets (\ '+all -infrastructure')
		 ]), 'topic ids');
    is ('2.0', $doc->findvalue ('/topicMap/@version'), 'version');

    ok (
	eq_set (
                [
                 map { $_->nodeValue }
		 $doc->findnodes('/topicMap/topic[@id="btop"]/instanceOf/topicRef/@href')
		],
	        [
	          '#ctop','#dtop'
		]), 'instances btop');

    ok ($doc->findnodes('/topicMap/association[itemIdentity/@href="068ce15eb7cf7cc4536d504c73a4c05c"]/type/topicRef[@href="#sucks-more-than"]'),
        'found assoc');
    
    ok (
	eq_set ([
		 map { $_->nodeValue }
		 $doc->findnodes('/topicMap/association[itemIdentity/@href="4abe49897cefeb950e4affaab0418e4f"]/role[type/topicRef/@href = "#winner"]/topicRef/@href')],
		[
		 '#atop', '#others'
		 ]
		), 'found assoc II');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="btop"]/name/value/text()')
		 ],
		['something', 'some other thing' ]), 'name value');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="btop"]/name[scope/topicRef/@href = "#ascope"]/value/text()')
		 ],
		['some other thing' ]), 'basename value, scoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="ctop"]/occurrence[type/topicRef/@href = "#sometype"]/resourceRef/@href')
		 ],
		[
		 'http://typedoc',
		 'http://typedandscopedoc'
		 ]), 'occ value, scoped and unscoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="ctop"]/occurrence[type/topicRef/@href = "#sometype"][scope/topicRef/@href = "#ascope"]/resourceRef/@href')
		 ],
		[
		 'http://typedandscopedoc'
		 ]), 'occ value, scoped');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="thistop"]/subjectIdentifier/@href')
		 ],
		[
		 'http://nowhere.never.ever',
		 'http://nowhere.ever.never'
		 ]), 'indicators');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[@id="thistop"]/subjectLocator/@href')
		 ],
		[
		 'http://rumsti'
		 ]), 'address');

    ok (! $doc->findnodes('/topicMap/topic[@id="ctop"]/subjectLocator'),    'no address');
    ok (! $doc->findnodes('/topicMap/topic[@id="ctop"]/subjectIdentifier'), 'no indicators');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes('/topicMap/topic[count(*) = 0]/@id')
		 ],
		[
		 'dtop',
		 'nackertes_topic',
		 'nobody',
		 'others',
		 'sometype',
		 'sucker',
		 'sucks-more-than',
		 'winner'
		 ]), 'empty topics');

    my ($aid) = map { $_->nodeValue } $doc->findnodes('/topicMap/association[@reifier = "atop"]/itemIdentity/@href');
#    warn $aid;

    ok ($aid =~ /^.{32}$/, 'internal reification');

    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes(qq|/topicMap/association[itemIdentity/\@href="$aid"]/role
						          [type/topicRef/\@href = "#winner"]
						          /topicRef/\@href|)
		 ],
		[
		 '#nobody'
		 ]), 'reified assoc, role + players');
    ok (
	eq_set ([
		 map { $_->nodeValue } $doc->findnodes(qq|/topicMap/association[itemIdentity/\@href="$aid"]/role
						          [type/topicRef/\@href = "#sucker"]
						          /topicRef/\@href|)
		 ],
		[
		 '#nobody'
		 ]), 'reified assoc, role + players II');

#print Dumper [
#	      map { $_->nodeValue } $doc->findnodes('/topicMap/topic[count(*) = 0]/@id')
#	     ];
}

{
    my $content = $tm->serialize (omit_trivia => 1, version => '2.0');
    $content =~ s{xmlns="http://www.topicmaps.org/xtm/"}{};  # get rid of the namespace

    use XML::LibXML;
    my $xp  = XML::LibXML->new();
    my $doc = $xp->parse_string($content);
    
    ok (eq_set ([
		 map { "tm://$_" }
		 (
		  'dtop',
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
		 ]), 'topic ids (trivia)');
}

{
    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    can_ok $tm2, 'deserialize';

    $tm2->deserialize ($tm->serialize (version => '2.0'));

    is_deeply( $tm->{mid2iid},    $tm2->{mid2iid},    'toplet structure identical' );
#warn Dumper $tm2;
#    foreach my $a (keys %{ $tm2->{assertions} }) {
#	warn "checking $a";
#	ok ($tm->{assertions}->{$a}, $a . " exists in tm");
#    }
#    foreach my $a (keys %{ $tm->{assertions} }) {
#	warn "checking $a";
#	ok ($tm2->{assertions}->{$a}, $a . " exists in tm2");
#	warn Dumper $tm->{assertions}->{$a} unless $tm2->{assertions}->{$a};
#    }

    is_deeply( $tm->{assertions}, $tm2->{assertions}, 'asserts structure identical' );
}

{
    my $content = $tm->serialize (version => '2.0');

    my $tm2 = new TM (baseuri=>"tm://");
    Class::Trait->apply ($tm2, "TM::Serializable::XTM");
    $tm2->deserialize ($content);
    my $content2 = $tm2->serialize;
    is ($content, $content2, 'round tripping');

#    use Text::Diff;
#    my $diff = diff \$content, \$content2, { STYLE => "Context" }; #,   \%options;
#    warn Dumper $diff;
}

__END__
