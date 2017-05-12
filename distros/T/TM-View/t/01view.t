use strict;
use TM::Materialized::AsTMa;
use TM::View;
use Data::Dumper;
use Test::More qw(no_plan);
use Test::Deep;
use XML::LibXML;


my $base="tm:/";

# pull in a tiny map
my $tiny='
atopic
bn: first

btopic 
bn: second
oc: http://cpan.org/
oc(search): http://search.cpan.org/

ctopic
bn: third
in: some text
in: some more text

dtopic
bn @ german: viertes
bn: fourth

(aassoc)
arole: atopic
brole: btopic

(bassoc)
arole: btopic
brole: ctopic dtopic

(cassoc)
arole: atopic
brole: btopic
crole: ctopic

cassoc
bn@arole: pov arole:
bn@brole: pov brole:

';
my $tm=TM::Materialized::AsTMa->new(baseuri=>$base,inline=>$tiny);
$tm->sync_in;

# aref has no bases
sub _check_seqids
{
    my ($v,$aref,$text)=@_;

    return cmp_deeply([map {$_->[0]->[0]} (@{$v->{sequence}})],
		     [map {$base.$_} @$aref],$text);
}


# add a view to it
my $v=TM::View->new($tm);
ok(ref($v) eq "TM::View","view constructor works");

# properly empty?
ok($v->sequence_length == 0,"new view is empty");
ok($v->map eq $tm,"map object can be retrieved");
# searchers return nothing
ok(!defined $v->sequence_move(0,+10),"accessors balk at empty view");
ok(!defined $v->where($base."atopic"),"accessors balk at empty view");
ok(!defined $v->who(0),"accessors balk at empty view");

# add topics at end
my $n=$base."atopic";
ok(1==$v->sequence_add($n),"adding a topic works");
ok(!defined $v->sequence_add($n),"topic can be added only once");
# searchers work?
cmp_deeply([$v->where($n)],[0,0],"finding topic works");
ok($v->who(0) eq $n,"looking up topic in location works");
_check_seqids($v,[qw(atopic)],"one sequenced");

# add another two at end
$n=$base."btopic";
ok(2==$v->sequence_add($n),"adding yet another topic works");
cmp_deeply([$v->where($n)],[1,0],"finding this topic works");
_check_seqids($v,[qw(atopic btopic)],"a and b sequenced");

$n=$base."ctopic";
ok(3==$v->sequence_add($n),"adding yet another topic works");
ok($n eq $v->who(2),"location lookup works");
_check_seqids($v,[qw(atopic btopic ctopic)],"a b c sequenced");

# add another inbetween
$n=$base."dtopic";
ok(4==$v->sequence_add($n,1),"adding topic in location works");
_check_seqids($v,[qw(atopic dtopic btopic ctopic)],
	      "sequence a d b c");

# remove a topic 
ok(3==$v->sequence_remove($n),"topic removal works");
_check_seqids($v,[qw(atopic btopic ctopic)],
	      "sequence a b c");

$v->sequence_add($n,0);
_check_seqids($v,[qw(dtopic atopic btopic ctopic)],
	      "adding at start, sequence d a b c");
ok(3==$v->sequence_remove(0),"removal by index works too");
_check_seqids($v,[qw(atopic btopic ctopic)],
	      "sequence a b c");

ok(!defined $v->sequence_move($n,1),"sequence move balks on nonexistent");
$n=$base."atopic";
ok(!defined $v->sequence_move($n,-1)
   && !defined $v->sequence_move($n,+3),"sequence move balks on bad deltas");

$n=$base."btopic";
ok(2==$v->sequence_move($n,1),"sequence move works");
_check_seqids($v,[qw(atopic ctopic btopic)],
	      "sequence a c b");

# style manipulations
# length
is(4,$v->style_length($base."atopic"),"a default style mentions all relevant");
is(7,$v->style_length($base."btopic"),"b default style mentions all relevant");
is(6,$v->style_length(1),"c default style mentions all relevant");

# modify styles
# movement first
$n=$base."btopic";
my $l=$v->style_length($n);
my @names=map { ($v->style($n,$_))[0]; } (0..$l-1);
ok(!defined $v->style_move($n,0,1),"style 0 can't be moved");
ok(!defined $v->style_move($n,15,-14),
   "movement beyond end of styles detected");
ok(!defined $v->style_move($n,$base."huhu",2),"nonexistent styles detected");

# move second to last
ok($l-1==$v->style_move($n,1,$l-2),"moving styles works");
my @afterwards=map { ($v->style($n,$_))[0]; } (0..$l-1);

cmp_deeply([ map {($v->style($n,$_))[0]}(0..$l-1) ],
		  [@names[0,2..$l-1,1]],"moving styles consistent");
# fourth by id to second 
ok(2==$v->style_move($n,($v->style($n,4))[0],-2),
   "moving styles by name works");

@names=map { ($v->style($n,$_))[0]; } (0..$l-1);

# modification of style attribs
my ($thisname,%os)=$v->style($n,1);
my %ns=%os;
$ns{testattrib}=1;
cmp_deeply([$thisname,%os],[$v->style($n,1,%ns)],"style mod does return the old state");
cmp_deeply([$thisname,%ns],[$v->style($n,1)],"style mod does mod the  state");
$v->style($n,1,%os);		# back to default state for now

# create a listlet
# create many listlets
# change the style of something and look at the resulting listlet
my $xp=XML::LibXML->new();
$l=$v->topic_as_listlet($n);

eval { $xp->parse_string($l); };
ok($l=~/<listlet/i && !$@,"listlet conversion for single topic works");

$l=$v->make_listlet;
eval { $xp->parse_string($l); };
ok($l=~/<listlet/i && !$@,"listlet conversion for the whole map works");

my %owner=(title=>"just a map",author=>"az",email=>"notme",
	   affiliation=>"perl republic",url=>"http://www.perl.org/");
$l=$v->make_listlet(%owner);
eval { $xp->parse_string($l); };
ok($l=~/<metadata/i && $l=~/www.perl.org/ && !$@,"listlet conversion, whole map and authorship works");

# mod a style
# btopic has some stuff to mod, see %os $n
$os{magic}=42;
$v->style($n,1,%os);
$l=$v->topic_as_listlet($n);
ok($l=~/(<listlet[^>]+magic="42"){1}/,"style attributes work");

$os{_on}=0;
$v->style($n,1,%os);
$l=$v->topic_as_listlet($n);
ok($l!~m!http://cpan.org!,"_on attribute works");

$os{_on}=1;			# re-set
$v->style($n,1,%os);


# style index 3 is the typed occ, _type_on is on by default
ok($l=~/<listlet title="search"/,"_type_on produces encapsulation");
(undef,%os)=$v->style($n,3);
$os{_type_on}=0;
$v->style($n,3,%os);
$l=$v->topic_as_listlet($n);
ok($l!~/<listlet title="search"/,"_type_on can be disabled");

# style index 2 is an assoc, 0th is topic itself, 1st is something shown
ok($l=~/<listlet[^>]+title="third \[brole\]"/,"_role_on produces text");
(undef,%os)=$v->style($n,2);
$os{_player_styles}->[1]->{_role_on}=0;

$v->style($n,2,%os);
$l=$v->topic_as_listlet($n);
ok($l=~/<listlet[^>]+title="third"/,"_role_on can be disabled");


# make a "newer" map
# reconcile it
# do we see changes?
$tiny=~s/atopic\n/atopic\nin: something new!/;
my $ntm=TM::Materialized::AsTMa->new(baseuri=>$base,inline=>$tiny);
$ntm->sync_in;

my $diff=$v->reconcile($ntm);
ok(ref($diff)eq"HASH","reconcile runs");
$n=$base."atopic";
(undef,%os)=$v->style($n,0);
ok($os{"_is_changed"}==1,"reconcile flags changed topics");
$l=$v->style_length($n);
(undef,%os)=$v->style($n,$l-1);
ok($os{"_is_changed"}==1,"reconcile flags changed aspects as well");

# clear the whole view
$v->clear;
ok(0==$v->sequence_length,"clearing sequence works");

