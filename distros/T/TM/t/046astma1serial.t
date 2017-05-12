use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}
#== TESTS ===========================================================================
use TM::Materialized::AsTMa;
require_ok( 'TM::Serializable::AsTMa' );

my $tm=TM::Materialized::AsTMa->new(baseuri=>"tm://", inline=>
'nackertes_topic 

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

dtop reifies http://gaia.earth/

etop is-reified-by ftop

(sucks-more-than)
sucker: ctop
winner: atop
winner: others

(sucks-more-than) @ascope
sucker: nobody
winner: nobody

thistop 
bn: reification
sin: http://nowhere.never.ever

(sucks-more-than) is-reified-by atop
winner: nobody
sucker: nobody

');
$tm->sync_in;

my $content = $tm->serialize;
ok ($content, "serialize returned something");

#warn $content;

like ($content, qr/sucks-more.+is-reified-by atop/, 'association reification');
like ($content, qr/btop \(ctop\)/,                  'topic type');

like($content, qr!dtop\s+reifies\s+http://gaia.earth/!, 'topic reifies ext url');
like($content, qr/etop\s+is-reified-by\s+ftop/, 'topic reifies other topic');


# now do the round trip
my $rt=TM::Materialized::AsTMa->new(baseuri=>"tm://", inline=>$content);
$rt->sync_in;
ok($rt->is_a($rt->mids("atop"),$rt->mids("thing")),"serialized stuff is parseable AsTMa");

# check that the topics/reification info has survived
my @otopics =sort map { $_->[TM->LID] } $tm->toplets;
my @ntopics =sort map { $_->[TM->LID] } $rt->toplets;
ok(eq_array(\@otopics,\@ntopics),"topics roundtrip");

#warn "diff: ".Dumper diffarr (\@otopics,\@ntopics);

sub diffarr {
    my $arr1 = shift;
    my $arr2 = shift;
    my @intersection;
    my @difference;
    my @union = @intersection = @difference = ();
    my %count = ();
    foreach my $element (@$arr1, @$arr2) { $count{$element}++ }
    foreach my $element (keys %count) {
        push @union, $element;
        push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
    }
    return \@difference;

}

# and the rest: topic-chars and associations
my @oass = map { $_->[TM->LID] } sort { $a->[TM->LID] cmp $b->[TM->LID] } $tm->match(TM->FORALL);
my @nass = map { $_->[TM->LID] } sort { $a->[TM->LID] cmp $b->[TM->LID] } $rt->match(TM->FORALL);
ok(eq_array(\@oass,\@nass),"assertions roundtrip");

#warn "diff: ".Dumper diffarr (\@oass,\@nass);

is (ref ($tm->reifies ($tm->tids ('atop'))), 'Assertion', 'reification still there');

## test infrastructure
#$content = $tm->serialize;
#
#warn $content;


# test omission options
$content=$tm->serialize(omit_trivia=>1);
ok($content,"serialize with options returns something");
ok($content!~/nackertes_topic/,"suppression of naked topics works");

ok($content,"serialize with options returns something");
ok($content!~/nackertes_topic/,"suppression of naked topics works");

$content=$tm->serialize;
like ($content, qr/originally from/, 'provenance default on');
$content=$tm->serialize(omit_provenance => 1);
unlike ($content, qr/originally from/, 'provenance explicit off');




# time for some destruction!
# reified bn or oc: no go in AsTMa 1.
my @stuff=$rt->match(TM->FORALL,char=>1,topic=>$rt->mids("ctop")); # topic must have 1 or more bn and oc
for my $nogo (@stuff) {
    $rt->internalize ('rumsti' => $nogo);
    eval {
	$content=$rt->serialize;
    }; like ($@, qr/offer reification/, "serialize throws exception on non-AsTMa-1 construct");
    $rt->externalize ($rt->tids ('rumsti'));
}
