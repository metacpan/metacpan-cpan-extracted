use strict;
use warnings;
use TM::PSI;
use TM::Materialized::AsTMa;
use Test::More qw(no_plan);
use Test::Deep;
use Data::Dumper;

my $base="tm:/";

sub _parse
{
    my ($text)=@_;
    $text.="\n\n";
    my $tm=TM::Materialized::AsTMa->new(baseuri=>$base,inline=>$text);
    $tm->sync_in;
    return $tm;
}

sub _diff
{
    my ($oldt,$newt,$opts)=@_;
    my $tmo=_parse($oldt);
    my $tmn=_parse($newt);
    my ($d1,$d2);
    $d1=$tmn->diff($tmo,$opts);
    $d2=$tmo->diff($tmn,$opts);
    return ($d1,$d2,$tmo,$tmn);
}

sub _tbag
{
    return bag(map{$base."$_"}@_);
}
sub _prfx
{
    return [ map {$base."$_"} @_ ];
}
    
# general function
my ($tmo,$tmn,$d1,$d2);
($d1,$d2,$tmo,$tmn)=_diff(q|
t1

t2

t3

t4
|, q|
t1

t2

t3

t4
|);
ok(ref $d1 eq "HASH","diff runs and produces a hash");
is_deeply($d1,$d2,"same map produces identical hashes");

# modified basename
($d1,$d2,$tmo,$tmn)=_diff(q|
t1 

t2 

oldt

modt
bn: i will be modified
|,q|
t1

t2

newt

modt
bn: that is my new name
|);

#cmp_deeply([keys %{$d1->{plus}}],_tbag("newt"),"new topic by tid is found");
ok ( eq_set ([keys %{$d1->{plus}}], _prfx( "newt" )) ,"new topic by tid is found");

#warn Dumper $d1;
#warn Dumper _tbag("modt");

cmp_deeply([keys %{$d1->{minus}}],_tbag("oldt"),"lost topic by tid is found");
cmp_deeply([keys %{$d1->{modified}}],_tbag("modt"),"modified topic is found");

ok(1==@{$d1->{modified}->{$base."modt"}->{plus}},"modified new basename");
ok(1==@{$d1->{modified}->{$base."modt"}->{minus}},"modified old basename");

# test new/lost/modified oc and inline, scoped attributes topics
($d1,$d2,$tmo,$tmn)=_diff(q|
t1 
in: a
in: b

t2 
oc: file://a
oc: file://b

t3
in@a: something

t4
bn: unscoped orig name
|,q|
t1
in: newa
in: newb

t2
oc: file://c

t3
in@b: something

t4
bn@b: scoped new name
|);

cmp_deeply([keys %{$d1->{plus}}],_tbag("b"),"new scope topic detected");
cmp_deeply([keys %{$d1->{minus}}],_tbag("a"),"removed scope topic detected");

cmp_deeply([keys %{$d1->{modified}}],_tbag(qw(t1 t2 t3 t4)),"topics with modified assertions listed");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t1"}->{plus}})],
	   bag("newa","newb"),"new inlines found");
cmp_deeply([map { ($tmo->get_x_players($tmo->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t1"}->{minus}})],
	   bag("a","b"),"removed inlines found");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t2"}->{plus}})],
	   bag("file://c"),"new occs found");
cmp_deeply([map { ($tmo->get_x_players($tmo->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t2"}->{minus}})],
	   bag("file://a","file://b"),"removed occs found");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t3"}->{plus}})],
	   bag("something"),"rescoped occurrence found");
cmp_deeply([map { ($tmo->get_x_players($tmo->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t3"}->{minus}})],
	   bag("something"),"rescoped original occurrence found");
is($base."b",$tmn->retrieve($d1->{modified}->{$base."t3"}->{plus}->[0])->[TM->SCOPE],"rescope new occ");
is($base."a",$tmo->retrieve($d1->{modified}->{$base."t3"}->{minus}->[0])->[TM->SCOPE],"rescope original occ");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t4"}->{plus}})],
	   bag("scoped new name"),"rescoped basename found");
cmp_deeply([map { ($tmo->get_x_players($tmo->retrieve($_),"value"))[0]->[0] } 
	    (@{$d1->{modified}->{$base."t4"}->{minus}})],
	   bag("unscoped orig name"),"unscoped original basename found");
is($base."b",$tmn->retrieve($d1->{modified}->{$base."t4"}->{plus}->[0])->[TM->SCOPE],"rescoped new bn");
is("us",$tmo->retrieve($d1->{modified}->{$base."t4"}->{minus}->[0])->[TM->SCOPE],"unscoped original bn");

# typed topics
($d1,$d2,$tmo,$tmn)=_diff(q|
t1
bn: some topic

t2(othertype)
|,q|
t1(sometype)
bn: some topic

t2(sometype)
|);

cmp_deeply([keys %{$d1->{plus}}],_tbag("sometype"),"new type topic detected");

cmp_deeply([keys %{$d1->{minus}}],_tbag("othertype"),"removed type topic detected");

cmp_deeply([map { $tmn->retrieve($_)->[TM->TYPE] } 
	    (@{$d1->{modified}->{$base."t1"}->{plus}}, @{$d1->{modified}->{$base."t2"}->{plus}})],
	   set("isa"),"found new type assertions");
cmp_deeply([map { $tmo->retrieve($_)->[TM->TYPE] } 
	    (@{$d1->{modified}->{$base."t1"}->{minus}}, @{$d1->{modified}->{$base."t2"}->{minus}})],
	   set("isa"),"found removed type assertions");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"class"))[0] } 
	    (@{$d1->{modified}->{$base."t1"}->{plus}})],
	   _tbag("sometype"),"found correct new topic type");
ok(0==@{$d1->{modified}->{$base."t1"}->{minus}},"properly detected non-existent old topic type");

cmp_deeply([map { ($tmn->get_x_players($tmn->retrieve($_),"class"))[0] } 
	    (@{$d1->{modified}->{$base."t2"}->{plus}})],
	   _tbag("sometype"),"found correct modified topic type");
cmp_deeply([map { ($tmo->get_x_players($tmo->retrieve($_),"class"))[0] } 
	    (@{$d1->{modified}->{$base."t2"}->{minus}})],
	   _tbag("othertype"),"found correct original for modified topic type");


# reification, subject identifiers as attributes
($d1,$d2,$tmo,$tmn)=_diff(q|
t1 reifies file://a

t2
sin: file://b

t3

t4
|,q|
t1 reifies file://b

t2

t4 is-reified-by t3
|,{include_changes=>0});

ok(!%{$d1->{plus}} && !%{$d1->{minus}},"subject identities detected");
cmp_deeply([keys %{$d1->{modified}}],_tbag(qw(t1 t2 t3)),"found precisely the modified identities");
cmp_deeply([values(%{$d1->{modified}})],set({plus=>[],minus=>[],'identities'=>1}),"only identities were changed");

cmp_deeply($tmn->midlet($base."t1"), [$base."t1",'file://b',[]],"t1 new sloc ok");
cmp_deeply($tmn->midlet($base."t2"), [$base."t2",undef,[]],"t2 removed sin ok");
cmp_deeply($tmn->midlet($base."t3"), [$base."t3",$base."t4",[]],"t3 new sloc ok");

cmp_deeply($tmo->midlet($base."t1"), [$base."t1",'file://a',[]],"t1 old sloc ok");
cmp_deeply($tmo->midlet($base."t2"), [$base."t2", undef,                                        [
                                               'file://b'
                                             ]
                                           ], "t2 old sin ok");
cmp_deeply($tmo->midlet($base."t3"), [$base."t3",undef,[]],"t3 old sloc ok");

# include_changes option
($d1,$d2,$tmo,$tmn)=_diff(q|
t1 
bn: me

t2
oc: http://somewhere
|, q|
t1
in: oi!

t3
bn: a new topic
|,{include_changes=>1});

ok(exists $d1->{plus_midlets} && exists $d1->{minus_midlets} && keys %{$d1->{plus_midlets}}==2
   && keys %{$d1->{minus_midlets}}==2 && exists $d1->{assertions},
   "include changes does include midlets/assertions");

ok(exists $d1->{plus_midlets}->{$base."t3"},"new midlet is included in changes");
ok(exists $d1->{minus_midlets}->{$base."t2"},"lost midlet is included in changes");
is(4,keys %{$d1->{assertions}},"only modified assertions are included");


# assoc: new assoc of same/different type, removed sole assoc of a type, removed assoc but not type
($d1,$d2,$tmo,$tmn)=_diff(q|
(at1)
r1: p1
r2: p2

(losttype)
r1: p1
r2: p2

(existingtype)
r1: p1
r2: p2

(existingtype)
r1: p2
r2: p1
|, q|
(at2)
r1: p2
r2: p3

(at1)
r1: p3
r2: p2

(at1)
r1: p1
r2: p2

(existingtype)
r1: p1
r2: p2
|,{include_changes=>0});

cmp_deeply([keys %{$d1->{plus}}],_tbag(qw(at2 p3)),"new assoc of new type found");
cmp_deeply($d1->{modified},{$base."at1"=>{plus=>[ignore]},
			$base."existingtype"=>ignore},"new assoc of existing type found");

cmp_deeply($d1->{minus},{$base."losttype"=>[ignore]},"removed sole assoc of a type is found");
cmp_deeply($d1->{modified},{$base."existingtype"=>{minus=>[ignore]},
			$base."at1"=>ignore},"removed assoc of surviving type is found");

# assoc of same type and layout but different/extra role/players is different
($d1,$d2,$tmo,$tmn)=_diff(q|
(ass)
r1: p1
r2: p2
|, q|
(ass)
r1: p1
r2: p2
r2: p3
|,{include_changes=>0});

cmp_deeply($d1,{identities=>{},plus=>{$base."p3"=>[]},minus=>{},
		modified=>{$base."ass"=>{plus=>[ignore],
			     minus=>[ignore]}}},"new assoc with extra players detected");


# trivial identity matching: things id'd directly
my $mold=q|
told reifies file://somewhere
# the old topic is the new topic (no occs yet)

# another identity, this time only ONE of the indicators matches
tfirst
sin: file://matches
sin: file://lost

(bla) is-reified-by assocold
r1: p1
r2: p2
|;
my $mnew=q|
tnew reifies file://somewhere

tsecond
sin: file://matches
sin: file://a_new_one

(bla) is-reified-by assocnew
r1: p1
r2: p2
|;

($d1,$d2,$tmo,$tmn)=_diff($mold,$mnew,
			  {consistency=>undef});

cmp_deeply($d1,{identities=>{},	modified=>{},
		minus=>{$base."tfirst"=>[],$base."told"=>[],
		    $base."assocold"=>[]},
		plus=>{$base."tnew"=>[],$base."tsecond"=>[],
		       $base."assocnew"=>[]}},
	   "without consistency parameter, subject identifier and locators are ignored");

($d1,$d2,$tmo,$tmn)=_diff($mold,$mnew,
			  {consistency=>[TM->Subject_based_Merging,TM->Indicator_based_Merging]});

cmp_deeply($d1,{plus=>{},minus=>{},modified=>ignore,
		identities=>{$base."told"=>$base."tnew",
			     $base."tfirst"=>$base."tsecond",
			     $base."assocold"=>$base."assocnew"}},
	   "subject locator and identifier identify identical topics"); 
cmp_deeply($d1->{modified},{$base."tfirst"=>{plus=>[],minus=>[],
					     identities=>1}},
	   "removed and added subject identifiers are detected");

# non-trivial identity matching: assertions that apply to renamed-and-identified topics
($d1,$d2,$tmo,$tmn)=_diff(q|
told reifies file://somewhere
in: the old topic is the new topic
bn: some name for it
oc: http://location

(some-assoc)
arole: told
brole: other
|, q|
tnew reifies file://somewhere
in: the old topic is the new topic
bn: some name for it
oc: http://location

(some-assoc)
arole: tnew
brole: other
|,{consistency=>[TM->Subject_based_Merging,TM->Indicator_based_Merging]});

# the topic characteristics, cheeeesily sorted by value (to quickly find the matches)
my @oldass=sort { $a->[TM->PLAYERS]->[1]->[0] cmp $b->[TM->PLAYERS]->[1]->[0] } $tmo->match(TM->FORALL,topic=>$base."told",char=>1);
my @newass=sort { $a->[TM->PLAYERS]->[1]->[0] cmp $b->[TM->PLAYERS]->[1]->[0] } $tmn->match(TM->FORALL,topic=>$base."tnew",char=>1);
my @xlats= map { $oldass[$_]->[TM->LID]=>$newass[$_]->[TM->LID] } (0..$#oldass);

# and the one assoc
my $oldass=($tmo->match(TM->FORALL,type=>$base."some-assoc"))[0]->[TM->LID];
my $newass=($tmn->match(TM->FORALL,type=>$base."some-assoc"))[0]->[TM->LID];
push @xlats, $oldass=>$newass;

cmp_deeply($d1,{plus=>{},minus=>{},modified=>{},
		identities=>{$base."told"=>$base."tnew", # the topic
			     @xlats}}, # and the stuff that applies to it
	   "assertions applying to identical topics are found"); 


