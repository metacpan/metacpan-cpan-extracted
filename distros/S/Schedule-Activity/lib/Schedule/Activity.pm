package Schedule::Activity;

use strict;
use warnings;
use List::Util qw/any/;
use Ref::Util qw/is_arrayref is_hashref is_plain_hashref is_ref/;
use Scalar::Util qw/blessed/;
use Schedule::Activity::Annotation;
use Schedule::Activity::Attributes;
use Schedule::Activity::Message;
use Schedule::Activity::Node;
use Schedule::Activity::NodeFilter;

our $VERSION='0.3.0';

sub new {
	my ($ref,%opt)=@_;
	my $class=is_ref($ref)||$ref;
	my %self=(
		config  =>$opt{configuration}//{},
		attr    =>undef,
		valid   =>0,
		built   =>undef,
		reach   =>undef,
		unsafe  =>$opt{unsafe}//0,
		PNA     =>undef, # per node attribute prefix, loaded via config
	);
	return bless(\%self,$class);
}

# validate()
# compile()
# schedule(activities=>[...])

sub _attr {
	my ($self)=@_;
	$$self{attr}//=Schedule::Activity::Attributes->new();
	return $$self{attr};
}

sub validate {
	my ($self,$force)=@_;
	if($$self{valid}&&!$force) { return }
	$$self{config}//={}; if(!is_hashref($$self{config})) { return ('Configuration must be a hash') }
	my @errors=$self->_validateConfig();
	if(!@errors) { $$self{valid}=1 }
	return @errors;
}

sub _validateConfig {
	my ($self)=@_;
	my $attr=$self->_attr();
	my %config=%{$$self{config}};
	my (@errors,@invalids);
	if(!is_hashref($config{node})) { push @errors,'Config is missing:  node'; $config{node}={} }
	if($config{attributes}) {
		if(!is_hashref($config{attributes})) { push @errors,'Attributes invalid structure' }
		else { while(my ($k,$v)=each %{$config{attributes}}) { push @errors,$attr->register($k,%$v) } }
	}
	if($config{messages}) {
		if(!is_hashref($config{messages})) { push @errors,'Messages invalid structure' }
		else {
		while(my ($namea,$msga)=each %{$config{messages}}) {
			if(!is_hashref($msga)) { push @errors,"Messages $namea invalid structure"; next }
			elsif(defined($$msga{attributes})&&!is_hashref($$msga{attributes})) { push @errors,"Messages $namea invalid attributes"; delete($$msga{attributes}) }
			else { foreach my $kv (Schedule::Activity::Message::attributesFromConf($msga)) { push @errors,$attr->register($$kv[0],%{$$kv[1]}) } }
			if(is_hashref($$msga{message})) {
				if(defined($$msga{message}{alternates})&&!is_arrayref($$msga{message}{alternates})) { push @errors,"Messages $namea invalid alternates" }
				else { foreach my $kv (Schedule::Activity::Message::attributesFromConf($$msga{message})) { push @errors,$attr->register($$kv[0],%{$$kv[1]}) } }
			}
		}
	} } # messages
	while(my ($k,$node)=each %{$config{node}}) {
		if(!is_hashref($node)) { push @errors,"Node $k, Invalid structure"; next }
		Schedule::Activity::Node::defaulting($node);
		my @nerrors=Schedule::Activity::Node::validate(%$node);
		if($$node{attributes}) {
			if(!is_hashref($$node{attributes})) { push @nerrors,"attributes, Invalid structure" }
			else { while(my ($k,$v)=each %{$$node{attributes}}) { push @nerrors,$attr->register($k,%$v) } }
		}
		push @nerrors,Schedule::Activity::Message::validate($$node{message},names=>$config{messages});
		foreach my $kv (Schedule::Activity::Message::attributesFromConf($$node{message})) { push @nerrors,$attr->register($$kv[0],%{$$kv[1]}) }
		if(@nerrors) { push @errors,map {"Node $k, $_"} @nerrors; next }
		@invalids=grep {!defined($config{node}{$_})} Schedule::Activity::Node->nextnames(0,$$node{next}//[]);
		if(@invalids) { push @errors,"Node $k, Undefined name in array:  next" }
		if(defined($$node{finish})&&!defined($config{node}{$$node{finish}})) { push @errors,"Node $k, Undefined name:  finish" }
	}
	$config{annotations}//={};
	if(!is_hashref($config{annotations})) { push @errors,'Annotations must be a hash' }
	else { while(my ($k,$notes)=each %{$config{annotations}}) {
		push @errors,map {"Annotation $k:  $_"} map {(
			Schedule::Activity::Annotation::validate(%$_),
			Schedule::Activity::Message::validate($$_{message},names=>$config{messages})
			)} @$notes } }
	return @errors;
}

sub _reachability {
	my ($self)=@_;
	my $changed;
	my %reach=(min=>{},max=>{});
	foreach my $namea (keys %{$$self{built}{node}}) {
		my $nodea=$$self{built}{node}{$namea};
		my @nodes;
		if  (is_arrayref($$nodea{next})) { @nodes=@{$$nodea{next}} }
		elsif(is_hashref($$nodea{next})) { @nodes=map {$$_{node}} values %{$$nodea{next}} }
		foreach my $nodeb (@nodes) {
			$reach{min}{$nodea}{$nodeb}=$$nodea{tmmin};
			$reach{max}{$nodea}{$nodeb}=(($nodea eq $nodeb)?'+':$$nodea{tmmax});
		}
	}
	$changed=1;
	while($changed) { $changed=0;
		foreach my $nodea (keys %{$reach{min}}) {
		foreach my $nodeb (keys %{$reach{min}{$nodea}}) {
		foreach my $nodec (keys %{$reach{min}{$nodeb}}) {
			my $x=$reach{min}{$nodea}{$nodec};
			my $y=$reach{min}{$nodea}{$nodeb}+$reach{min}{$nodeb}{$nodec};
			if(!defined($x)||($x>$y)) {
				$reach{min}{$nodea}{$nodec}=$y;
				$changed=1;
			}
		} } }
	}
	my $triadd=sub {
		my ($x,$y)=@_;
		if($x eq '+') { return '+' }
		if($y eq '+') { return '+' }
		return $x+$y;
	};
	$changed=1;
	while($changed) { $changed=0;
		foreach my $nodea (keys %{$reach{max}}) {
		foreach my $nodeb (keys %{$reach{max}{$nodea}}) {
		foreach my $nodec (keys %{$reach{max}{$nodeb}}) {
			if($nodea eq $nodec) { $reach{max}{$nodea}{$nodec}='+'; next }
			my $x=$reach{max}{$nodea}{$nodec};
			if(defined($x)&&($x eq '+')) { next }
			my $y=&$triadd($reach{max}{$nodea}{$nodeb},$reach{max}{$nodeb}{$nodec});
			if(!defined($x)||($y eq '+')||($x<$y)) {
				$reach{max}{$nodea}{$nodec}=$y;
				$changed=1;
			}
		} } }
	}
	$$self{reach}=\%reach;
	return $self;
}

# These checks ignore any filtering that might be active during construction; these are only sanity checks.
# Recommend stashing the reachability results in $self for later.
#
# Here are the tests and their defined orders.
# 1.  Activity that cannot reach finish
# 2.  Orphaned actions (no activity reaches them)
# 3.  Dual-parent action nodes (with more than a single root activity)  NOT(item2)
# 4.  Dual-finish action nodes  NOT(item3)
# 5.  Dangling actions (cannot reach their finish node)  NOT(item1||item4)
# 6.  Action nodes with tmavg=0  NOT(activity|finish) (this is only a problem if there's a cycle)
#
sub safetyChecks {
	my ($self)=@_;
	my (@errors,$changed);
	$self->_reachability();
	my %reach=%{$$self{reach}};
	#
	# Be very cautious about names versus stringified references.
	my $builtNode=$$self{built}{node};
	my %activities=map {$$builtNode{$_}=>$$builtNode{$_}{finish}} grep {defined($$builtNode{$_}{finish})} keys(%$builtNode);
	my %finishes=map {$_=>1} values(%activities);
	my %actions=map {$_=>$$builtNode{$_}} grep {!exists($activities{$$builtNode{$_}})&&!exists($finishes{$$builtNode{$_}})} keys(%$builtNode);
	my %incompleteActivities=map {$_=>1} grep{!defined($reach{min}{$$builtNode{$_}}{$activities{$$builtNode{$_}}})} grep {defined($$builtNode{$_}{finish})} keys(%$builtNode);
	#
	push @errors,map {"Finish for activity $_ is unreachable"} keys(%incompleteActivities);
	#
	my (%orphans,%dualParent,%dualFinish,%dangling,%infiniteCycle);
	foreach my $action (keys %actions) {
		my $parents=0;
		my $terminals=0;
		foreach my $activity (keys %activities) { if(defined($reach{min}{$activity}{$actions{$action}})) { $parents++ } }
		foreach my $finish   (keys %finishes)   { if(defined($reach{min}{$actions{$action}}{$finish}))   { $terminals++ } }
		if($parents==0)    { $orphans{$action}=1 }
		elsif($parents>1)  { $dualParent{$action}=1 }
		if($terminals>1)   { $dualFinish{$action}=1 }
		elsif(!$terminals) { $dangling{$action}=1 }
		if(($actions{$action}{tmavg}==0)&&(defined($reach{min}{$actions{$action}}{$actions{$action}}))) { $infiniteCycle{$action}=1 }
	}
	push @errors,map {"Action $_ belongs to no activity"} keys(%orphans);
	push @errors,map {"Action $_ belongs to multiple activities"} keys(%dualParent);
	push @errors,map {"Action $_ reaches multiple finish nodes"} keys(%dualFinish);
	push @errors,map {"Dangling action $_"} keys(%dangling);
	push @errors,map {"No progress will be made for action $_"} keys(%infiniteCycle);
	return @errors;
}

sub _buildConfig {
	my ($self)=@_;
	my %base=%{$$self{config}};
	my $attr=$self->_attr();
	my %res;
	if($base{PNA}) { $$self{PNA}=$base{PNA} }
	while(my ($k,$node)=each %{$base{node}}) {
		if(is_plain_hashref($node)) { $res{node}{$k}=Schedule::Activity::Node->new(%$node) }
		elsif(blessed($node))       { $res{node}{$k}=$node }
		else                        { die "Invalid node $k when building config" }
		$res{node}{$k}{keyname}=$k;
		if($$self{PNA}) {
			$res{node}{$k}{attributes}{"$$self{PNA}$k"}={incr=>1};
			$attr->register("$$self{PNA}$k",type=>'int',value=>0);
		}
	}
	my $msgNames=$base{messages}//{};
	while(my ($k,$node)=each %{$res{node}}) {
		$node->nextremap($res{node});
		if(defined($$node{finish})) { $$node{finish}=$res{node}{$$node{finish}} }
		$$node{msg}=Schedule::Activity::Message->new(message=>$$node{message},names=>$msgNames);
		if(is_plain_hashref($$node{require})) { $$node{require}=Schedule::Activity::NodeFilter->new(%{$$node{require}}) }
	}
	$$self{built}=\%res;
	return $self;
}

sub compile {
	my ($self,%opt)=@_;
	if($$self{built}) { return }
	my @errors=$self->validate();
	if(@errors) { return (error=>\@errors) }
	$self->_buildConfig();
	if(!$opt{unsafe}) { @errors=$self->safetyChecks(); if(@errors) { return (error=>\@errors) } }
	return;
}

sub _nodeMessage {
	my ($optattr,$tm,$node)=@_;
	my ($message,$msg)=$$node{msg}->random();
	if($$node{attributes}) {
		while(my ($k,$v)=each %{$$node{attributes}}) {
			$optattr->change($k,%$v,tm=>$tm) } }
	if(is_hashref($msg)) { while(my ($k,$v)=each %{$$msg{attributes}}) {
		$optattr->change($k,%$v,tm=>$tm);
	} }
	#
	return Schedule::Activity::Message->new(message=>$message,attributes=>$$msg{attributes}//{});
}

sub findpath {
	my (%opt)=@_;
	my ($tm,$slack,$buffer,@res)=(0,0,0);
	my %tension=(
		slack =>1-($opt{tensionslack} //$opt{tension}//0.5),
		buffer=>1-($opt{tensionbuffer}//$opt{tension}//0.85659008),
	);
	foreach my $k (qw/slack buffer/) { if($tension{$k}>1){$tension{$k}=1}; if($tension{$k}<0){$tension{$k}=0} }
	my ($node,$conclusion)=($opt{start},$opt{finish});
	$opt{attr}->push();
	while($node&&($node ne $conclusion)) {
		push @res,[$tm,$node];
		push @{$res[-1]},_nodeMessage($opt{attr},$tm+$opt{tmoffset},$node);
		$node->increment(\$tm,\$slack,\$buffer);
		$opt{attr}->push();
		$opt{attr}->log($tm);
		if($tm-$tension{slack}*$slack+rand($tension{buffer}*$buffer+$tension{slack}*$slack)<=$opt{goal}) {
			$node=$node->nextrandom(not=>$conclusion,tm=>$tm,attr=>$opt{attr}{attr})//$node->nextrandom(tm=>$tm,attr=>$opt{attr}{attr}) }
		elsif($node->hasnext($conclusion)) { $node=$conclusion }
		else { $node=$node->nextrandom(not=>$conclusion,tm=>$tm,attr=>$opt{attr}{attr})//$node->nextrandom(tm=>$tm,attr=>$opt{attr}{attr}) }
		$opt{attr}->pop();
	}
	if($node&&($node eq $conclusion)) {
		push @res,[$tm,$conclusion];
		push @{$res[-1]},_nodeMessage($opt{attr},$tm+$opt{tmoffset},$conclusion);
		$conclusion->increment(\$tm,\$slack,\$buffer);
		$node=undef;
	}
	$opt{attr}->pop();
	return (
		steps =>\@res,
		tm    =>$tm,
		slack =>$slack,
		buffer=>$buffer,
	);
}

sub scheduler {
	my (%opt)=@_; # goal,node,config
	if(!is_hashref($opt{node}))      { die 'scheduler called with invalid node' }
	if(!defined($opt{node}{finish})) { die 'scheduler called with non-activity node' }
	$opt{retries}//=10; $opt{retries}--;
	if($opt{retries}<0) { die $opt{error}//'scheduling retries exhausted' }
	#
	my %path=findpath(
		start     =>$opt{node},
		finish    =>$opt{node}{finish},
		goal      =>$opt{goal},
		retries   =>$opt{retries},
		backtracks=>2*$opt{retries},
		attr      =>$opt{attr},
		tmoffset  =>$opt{tmoffset},
		tensionslack =>$opt{tensionslack} //$opt{tension},
		tensionbuffer=>$opt{tensionbuffer}//$opt{tension},
	);
	if($path{retry}) { return scheduler(%opt,retries=>$opt{retries},error=>$path{error}//'Retries exhausted') }
	my @res=@{$path{steps}};
	my ($tm,$slack,$buffer)=@path{qw/tm slack buffer/};
	if($res[-1][1] ne $opt{node}{finish}) { return scheduler(%opt,retries=>$opt{retries},error=>q|Didn't reach finish node|) }
	#
	my $excess=$tm-$opt{goal};
	if(abs($excess)>0.5) {
		if(($excess>0)&&($excess>$slack))   { return scheduler(%opt,retries=>$opt{retries},error=>"Excess exceeds slack ($excess>$slack)") }
		if(($excess<0)&&(-$excess>$buffer)) { return scheduler(%opt,retries=>$opt{retries},error=>'Shortage exceeds buffer ('.(-$excess).">$buffer)") }
		my ($reduction,$rate)=(0);
		if($excess>0) { $rate=$excess/$slack }
		else          { $rate=$excess/$buffer }
		foreach my $entry (@res[0..$#res]) {
			$$entry[0]=$$entry[0]-$reduction;
			my $dt;
			if($excess>0) { $dt=$rate*($$entry[1]->slack()) }
			else          { $dt=$rate*($$entry[1]->buffer()) }
			$reduction+=$dt;
		}
	}
	foreach my $i (0..$#res) {
		my $dt;
		if($i<$#res) { $dt=$res[$i+1][0]-$res[$i][0] }
		else         { $dt=$opt{goal}-$res[$i][0] }
		$res[$i][3]=$res[$i][4]=0;
		$dt-=$res[$i][1]{tmavg}//0;
		if($dt>0) { $res[$i][4]=$dt }
		else      { $res[$i][3]=-$dt }
	}
	#
	# Message selection occurs in _nodeMessage during path construction.
	# Message attributes apply during path construction to permit node
	# filtering, but final materialization occurs after slack/buffer
	# adjustments have been made.
	#
	# Both nodes and their messages may change attributes, but node
	# attributes are applied first, so message attributes will "win" if
	# both contain 'set' operations.  Documented in "/Precedence".
	#
	foreach my $i (0..$#res) {
		my $node=$res[$i][1];
		if($$node{attributes}) {
			while(my ($k,$v)=each %{$$node{attributes}}) {
				$opt{attr}->change($k,%$v,tm=>$res[$i][0]+$opt{tmoffset}) } }
		my ($message,$msg)=$res[$i][2]->random();
		$res[$i][1]=Schedule::Activity::Node->new(%$node,message=>$message);
		if(is_hashref($msg)) { while(my ($k,$v)=each %{$$msg{attributes}}) {
			$opt{attr}->change($k,%$v,tm=>$res[$i][0]+$opt{tmoffset});
		} }
	}
	return @res;
}

sub goalScheduling {
	my ($self,%opt)=@_;
	my %goal=%{delete($opt{goal})};
	if(!is_hashref($goal{attribute})) { return (error=>'goal{attribute} must be hash') }
	{ my $attr=$self->_attr();
		my %validOp=map {$_=>undef} (qw/min max eq ne/);
		my %valueOp=map {$_=>undef} (qw/eq ne/);
		foreach my $k (keys %{$goal{attribute}}) {
			if(!defined($$attr{attr}{$k})) { return (error=>"goal-requested attribute does not exist:  $k") }
			if(!is_hashref($goal{attribute}{$k}))  { return (error=>"goal attribute $k must be a hash") }
			if(!defined($goal{attribute}{$k}{op})) { return (error=>"missing operator in goal $k") }
			if(!exists($validOp{$goal{attribute}{$k}{op}//''})) { return (error=>"invalid operator in goal $k") }
			if(exists($valueOp{$goal{attribute}{$k}{op}})&&!defined($goal{attribute}{$k}{value})) { return (error=>"missing value in goal $k") }
		}
	}
	my $cycles=$goal{cycles}//10;
	my %schedule;
	eval { %schedule=$self->schedule(%opt) };
	my ($bestscore,%best);
	my $notemerge=sub {
		if(!defined($schedule{annotations})) { return }
		my %seen;
		my @activities=@{$schedule{activities}};
		foreach my $group (sort {$a cmp $b} keys(%{$schedule{annotations}})) {
			if($seen{$group}) { next }
			if(!defined($schedule{annotations}{$group})) { next }
			push @activities,@{$schedule{annotations}{$group}{events}};
			$seen{$group}=1;
		}
		if(%seen) {
			@activities=sort {$$a[0]<=>$$b[0]} @activities;
			%{$schedule{attributes}}=$self->computeAttributes(@activities);
		}
	};
	my $score=sub {
		my $res=-1e6;
		if(!defined($schedule{attributes})) { return $res }
		$res=0;
		foreach my $k (keys %{$goal{attribute}}) {
			my %cmp=%{$goal{attribute}{$k}};
			my %attr=%{$schedule{attributes}{$k}//{}};
			my $avg;
			if($$self{PNA}&&($k=~/^\Q$$self{PNA}\E/)) { $avg=$attr{y}//0 }
			else                                      { $avg=$attr{avg}//0 }
			my $weight=$cmp{weight}//1;
			if   ($cmp{op} eq 'max') { $res+=$avg*$weight }
			elsif($cmp{op} eq 'min') { $res-=$avg*$weight }
			elsif($cmp{op} eq 'eq')  { $res-=abs($avg-$cmp{value})*$weight }
			elsif($cmp{op} eq 'ne')  { $res+=abs($avg-$cmp{value})*$weight }
			elsif($cmp{op} eq 'XX')  {
				my $xy=$attr{xy}//[];
				foreach my $i (0..$#$xy-1) {
					$res-=($$xy[1+$i][0]-$$xy[$i][0])*abs(0.5*$$xy[$i][1]+0.5*$$xy[1+$i][1]-$cmp{value})
				}
			}
		}
		return $res;
	};
	&$notemerge();
	$bestscore=&$score(); %best=%schedule;
	my $lasterr;
	#
	while(--$cycles) {
		eval { %schedule=$self->schedule(%opt) };
		if($@) { $lasterr=$@; next }
		&$notemerge();
		my $s=&$score();
		if($s>$bestscore) {
			$bestscore=$s;
			%best=%schedule;
		}
	}
	if(!%best&&$lasterr) { die $lasterr }
	return %best;
}

sub incrementalScheduling {
	my ($self,%opt)=@_;
	my $activities=$opt{activities};
	my $i=0;
	my %after=();
	my %schedule;
	while($i<=$#$activities) {
		my $j=$i;
		while(($j<$#$activities)&&(!is_hashref($$activities[$j][2])||!defined($$activities[$j][2]{goal}))) { $j++ }
		my @acts;
		foreach my $activity (@$activities[$i..$j]) {
			push @acts,[@$activity[0,1]];
			if(is_hashref($$activity[2])) { push @{$acts[-1]},{map {$_=>$$activity[2]{$_}} grep {$_ ne 'goal'} keys(%{$$activity[2]})} }
		}
		%schedule=$self->schedule(%opt,%after,activities=>\@acts,goal=>$$activities[$j][2]{goal});
		if($i<$#$activities) { %after=(after=>{%schedule}) }
		$i=1+$j;
	}
	return %schedule;
}

sub schedule {
	my ($self,%opt)=@_;
	my %check=$self->compile(unsafe=>$opt{unsafe}//$$self{unsafe});
	if($check{error})                  { return (error=>$check{error}) }
	if(!is_arrayref($opt{activities})) { return (error=>'Activities must be an array') }
	if(any {is_hashref($$_[2])&&defined($$_[2]{goal})} @{$opt{activities}}) { return $self->incrementalScheduling(%opt) }
	if($opt{goal}&&%{$opt{goal}})      { return $self->goalScheduling(%opt) }
	my $tmoffset=$opt{tmoffset}//0;
	my %res=(stat=>{slack=>0,buffer=>0});
	if($opt{after}) {
		delete($$self{attr});
		my $attr=$self->_attr();
		push @{$$attr{stack}},$opt{after}{_attr};
		$attr->pop();
		$tmoffset=$opt{after}{_tmmax};
		%{$res{stat}}=(%{$res{stat}},%{$opt{after}{stat}});
	}
	$self->_attr()->push();
	foreach my $activity (@{$opt{activities}}) {
		foreach my $entry (scheduler(goal=>$$activity[0],node=>$$self{built}{node}{$$activity[1]},config=>$$self{built},attr=>$self->_attr(),tmoffset=>$tmoffset,tensionslack=>$opt{tensionslack},tensionbuffer=>$opt{tensionbuffer})) {
			push @{$res{activities}},[$$entry[0]+$tmoffset,@$entry[1..$#$entry]];
			$res{stat}{slack}+=$$entry[3]; $res{stat}{buffer}+=$$entry[4];
			$res{stat}{slackttl}+=$$entry[1]{tmavg}-$$entry[1]{tmmin};
			$res{stat}{bufferttl}+=$$entry[1]{tmmax}-$$entry[1]{tmavg};
		}
		$tmoffset+=$$activity[0];
	}
	$self->_attr()->log($tmoffset);
	if($opt{after}) { unshift @{$res{activities}},@{$opt{after}{activities}} }
	%{$res{attributes}}=$self->_attr()->report();
	if(!$opt{nonote}) { while(my ($group,$notes)=each %{$$self{config}{annotations}}) {
		my @schedule;
		foreach my $note (@$notes) {
			my $annotation=Schedule::Activity::Annotation->new(%$note);
			foreach my $note ($annotation->annotate(@{$res{activities}})) {
				my ($message,$mobj)=Schedule::Activity::Message->new(message=>$$note[1]{message},names=>$$self{config}{messages}//{})->random();
				my %node=(%{$mobj//{}},message=>$message);
				if($$note[1]{annotations}) { $node{annotations}=$$note[1]{annotations} }
				push @schedule,[$$note[0],\%node,@$note[2..$#$note]];
			}
		}
		@schedule=sort {$$a[0]<=>$$b[0]} @schedule;
		for(my $i=0;$i<$#schedule;$i++) {  ## no critic (CStyleForLoops)
			if($schedule[$i+1][0]==$schedule[$i][0]) {
				splice(@schedule,$i+1,1); $i-- } }
		$res{annotations}{$group}{events}=\@schedule;
	} }
	$self->_attr()->push(); $res{_attr}=pop(@{$$self{attr}{stack}}); # store a copy in {_attr}
	$self->_attr()->pop();
	$res{_tmmax}=$tmoffset;
	return %res;
}

sub computeAttributes {
	my ($self,@activities)=@_;
	$self->_attr()->push();
	$self->_attr()->reset();
	foreach my $event (sort {$$a[0]<=>$$b[0]} @activities) {
		my ($tm,$node,$msg)=@$event;
		if($$node{attributes}) {
			while(my ($k,$v)=each %{$$node{attributes}}) {
				$self->_attr()->change($k,%$v,tm=>$tm) } }
		if(is_hashref($msg)) { while(my ($k,$v)=each %{$$msg{attributes}}) {
			$self->_attr()->change($k,%$v,tm=>$tm);
		} }
	}
	my %res=$self->_attr()->report();
	$self->_attr()->pop();
	return %res;
}

sub loadMarkdown {
	my ($text)=@_;
	my $list=qr/(?:\d+\.|[-*])/;
	my (%config,@activities,@siblings,$activity,$tm);
	foreach my $line (split(/\n/,$text)) {
		if($line=~/^\s*$/) { next }
		if($line=~/^$list\s*(.*)$/) {
			$activity=$1; $tm=0;
			if($activity=~/(?<name>.*?),\s*(?<tm>\d+)(?<unit>min|sec)\s*$/) {
				$activity=$+{name}; $tm=$+{tm}; if($+{unit} eq 'min') { $tm*=60 } }
			if(defined($config{node}{$activity})) { die "Name conflict:  $activity" }
			push @activities,[$tm,$activity];
			@siblings=();
			$config{node}{$activity}={
				message=>$activity,
				next=>[],
				tmavg=>0,
				finish=>"$activity, conclude",
			};
			$config{node}{"$activity, conclude"}={tmavg=>0};
		}
		elsif($line=~/^\s+$list\s*(.*)$/) {
			if(!$activity) { die 'Action without activity' }
			my $action=$1; $tm=60;
			if($action=~/(?<name>.*?),\s*(?<tm>\d+)(?<unit>min|sec)\s*$/) {
				$action=$+{name}; $tm=$+{tm}; if($+{unit} eq 'min') { $tm*=60 } }
			$action="$activity, $action";
			push @{$config{node}{$activity}{next}},$action;
			$activities[-1][0]||=$tm;
			if(defined($config{node}{$action})) { die "Name conflict:  $action" }
			$config{node}{$action}={
				message=>$action,
				next=>[@siblings,"$activity, conclude"],
				tmavg=>$tm,
			};
			foreach my $sibling (@siblings) { push @{$config{node}{$sibling}{next}},$action }
			push @siblings,$action;
		}
	}
	return (configuration=>\%config,activities=>\@activities);
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity - Generate activity schedules

=head1 VERSION

Version 0.3.0

=head1 SYNOPSIS

  use Schedule::Activity;
  my $scheduler=Schedule::Activity->new(
    configuration=>{
      node=>{
        Activity=>{
          message=>'Begin Activity',
          next=>['action 1'],
          tmmin=>5,tmavg=>5,tmmax=>5,
          finish=>'Activity, conclude',
        },
        'action 1'=>{
          message=>'Begin action 1',
          tmmin=>5,tmavg=>10,tmmax=>15,
          next=>['action 1','action 2'],
        },
        'action 2'=>{
          message=>'Begin action 2',
          tmmin=>5,tmavg=>10,tmmax=>15,
          next=>['Activity, conclude'],
        },
        'Activity, conclude'=>{
          message=>'Conclude Activity',
          tmmin=>5,tmavg=>5,tmmax=>5,
        },
      },
      annotations=>{...},
      attributes =>{...},
      messages   =>{...},
      PNA        =>...,
    },
  );
  my %schedule=$scheduler->schedule(activities=>[
    [30,'Activity'],
    ...
  ]);
  if($schedule{error}) { die join("\n",@{$schedule{error}}) }
  print join("\n",map {"$$_[0]:  $$_[1]{message}"} @{$schedule{activities}});

=head1 DESCRIPTION

This module permits building schedules of I<activities> each containing randomly-generated lists of I<actions>.  Each activity is scheduled to a target time by selecting randomly selecting actions within the configured graph, which may contain repetition and cycles, and by using I<slack> and I<buffer> timing adjustments.  Attributes may be attached to events and messages, both for reporting and to control scheduling toward a I<goal>.  Annotations permit construction of secondary messages around events.

For additional examples, see the tutorial and the C<samples/> directory.

=head1 CONFIGURATION

=head2 Overview

A configuration for scheduling contains the following sections:

  %configuration=(
    node       =>{...}
    attributes =>{...} # optional
    annotations=>{...} # optional
    messages   =>{...} # optional
  )

The named C<node> entries specify the activities and actions used during schedule construction.  The activity/action keys are used to configure the relationship between nodes, but the I<message> configuration within each node is the primary value used when formatting scheduling results.

All other sections are optional and described below.

=head2 Activities and Actions

Both activities and actions are configured as named C<node> entries.  With this structure, an action and activity may have the same C<message>, but must use different key names.

  'activity name'=>{
    tmavg     =>value, ...,
    finish    =>'activity conclusion',
    next      =>[...],
    next      =>{name=>{weight=>value},...},
    message   =>...    # optional
    attributes=>{...}, # optional
  }
  'action name'=>{
    tmavg     =>value, ...,
    next      =>[...],
    next      =>{...},
    message   =>...    # optional
    attributes=>{...}, # optional
    require   =>{...}, # optional
  }

An array of C<next> nodes is a list of names, which must be defined in the configuration.  During schedule construction, entries will be I<chosen randomly> from the list of C<next> nodes.  The conclusion must be reachable from the initial activity, or scheduling will fail.  Weighting is supported when C<next> is a hash, with keys that are the names of next possible actions and values of C<{weight=E<gt>number}>.  The total weight during scheduling includes only non-filtered nodes; the default weight is one (1).  There is no further restriction on the items in C<next>:  Scheduling specifically supports cyclic/recursive actions, including self-cycles.  

There is no functional difference between activities and actions except that a node must contain C<finish> to be used for activity scheduling.  Nomenclature is primarily to support schedule organization:  A collection of random actions is used to build an activity; a sequence of activities is used to build a schedule.

The C<require> configuration specifies attribute value prerequisites, computed from the current attribute values, that must be met for an action node to be a candidate for random selection.  See L<Schedule::Activity::NodeFilter> for available filtering criteria, but see L</"SCHEDULING ALGORITHM"> regarding attribute value consistency.

=head2 Time specification

The only time specification currently supported is:

  tmmin=>seconds, tmavg=>seconds, tmmax=>seconds

Values must be non-negative numbers.  All three values may be identical.  Note that scheduling to a given goal may be impossible without I<slack> or I<buffer> within some of the actions:

  slack =tmavg-tmmin
  buffer=tmmax-tmavg

The slack is the amount of time that could be reduced in an action before it would need to be removed/replaced in the schedule.  The buffer is the amount of time that could be added to an action before additional actions would be needed in the schedule.

Caution:  While startup/conclusion of activities may have fixed time specifications (including zero time), it is recommended, though not mandatory, that actions always contain some slack/buffer.  There is currently no "relaxing mechanism" during scheduling, so a configuration with no slack nor buffer must exactly meet the goal time requested to succeed.

Providing any time value will automatically set any missing values at the fixed ratios 3,4,5.  EG, specifying only C<tmmax=40> will set C<tmmin=24> and C<tmavg=32>.  If provided two time values, priority is given to C<tmavg> to set the third.

Scheduling may be controlled with the tension settings described below.  Future changes may support automatic slack/buffering, universal slack/buffer ratios, and open-ended/relaxed slack/buffering.

=head2 Messages

See L<Schedule::Activity::Message/CONFIGURATION> for all possible message configurations.

Any activity or action may contain an optional message string or configuration.  Messages permit the caller to easily format generated schedules.  Messages may contain attributes, which can affect subsequent scheduling.  Message attributes are emitted with the attribute response values.

A scheduling configuration may declare a list of named messages, which will be available to all message configurations:

  %configuration=(
    messages=>{
      'key name'=>{ message configuration }
      ...
    },
  )

=head1 RESPONSE

The response from C<schedule(activities=>[...])> is:

  %schedule=(
    error=>['list of validation errors, if any',...],
    activities=>[
      [seconds, event],
      ..,
    ],
    annotations=>{...}
    attributes=>{
      name=>{attribute report},
      ...
    },
  )

=head2 Success Response

When scheduling is successful, the list of events is in the C<activities> array.  Each event is an array containing the timestamp, and an event node containing a C<{message}>.  Scheduling always occurs in order, so activities should appear in non-decreasing timestamp order.  Timestamp units are undefined, so formatting is the responsibility of the caller.

The C<event{message}> is materialized during schedule construction, so the response will only contain the single, chosen message for the event.  Alternate messages attached to the underlying event node, or a referenced name message, are not included in the response.

The "annotations" response is described below in L</ANNOTATIONS>.

For the "attribute report", see L<Schedule::Activity::Attribute/RESPONSE>.

=head2 Validation Errors

If the configuration fails prechecks, findings will be reported in the C<error> array and scheduling will not be attempted.  Configuration errors include invalid type/structures, invalid node keys/values, messages/attributes/annotations, as well as basic activity/action reachability checks.  Note that node filtering (via a "require" configuration) may prevent scheduling despite these basic reachability checks.

=head2 Unhandled Errors

In addition to validation failures returned through C<error>, the following may cause the scheduler to C<die()>:  The requested activity name is undefined.  The scheduler was not able to reach the named finish node.  The number of retries or backtracking attempts has been exhausted.

The difference between the result time and the goal may cause retries when an excess exceeds the available slack, or when a shortage exceeds the available buffer.

=head1 ATTRIBUTES

Attributes permit tracking boolean or numeric values that can be used to affect node selection during schedule construction.  The resulting attribute history can be used to verify the final schedule or compute goal scores.

=head2 Configuration

For a complete description of attribute configuration options, see L<Schedule::Activity::Attribute>.

Attributes may be referenced from an activity, action, or message.  For example:

  'action name'=>{
    attributes=>{
      temperature=>{set=>value, incr=>value, decr=>value, note=>'comment'},
      counter    =>{set=>value, incr=>value},
      flag       =>{set=>0/1},
    },
  }

The scheduling configuration may also declare attribute names and starting values.

  %configuration=(
    attributes=>{
      flagA  =>{type=>'bool'},
      flagB  =>{type=>'bool', value=>1},
      counter=>{type=>'int',  value=>0},
    },
  )

Boolean types must be declared in this section.  It is recommended to set any non-zero initial values in this fashion, since calling C<set> requires that activity to always be the first requested in the schedule.

Attributes within message alternate configurations and named messages are identified during configuration validation.  Together with activity/action configurations, attributes are verified before schedule construction, which will fail if an attribute name is referenced in a conflicting manner.

Automatic, per-node attributes may be enabled by including C<PNA=E<gt>'prefix:'> within the configuration.  Each node, "keyname", will automatically increment an attribute named "prefix:keyname" each time that activity/action appears in the schedule.  These attributes are included in the report and can be used for node filtering.  When used in goals, per-node attributes are compared based on their final y-value/count (not the average).  Per-activity goals should consider the accumulated totals, not just the change of the attribute within that activity; however, per-node attributes are not special and can be reset within an activity/action configuration.  Per-node attributes are disabled by default.

=head2 Precedence

When an activity/action node and a selected message both contain attributes, the value of the attribute is updated first from the action node and then from the message node.  For boolean attributes, this means the "value set in the message has precedence".  For integer attributes, suppose that the value is initially zero; then, if both the action and message have attribute operators, the result will be:

  Action  Message  Value
  set=1   set=2      2
  incr=3  set=4      4
  set=5   incr=6    11
  incr=7  incr=8    15

=head2 Average Values

Attributes are always logged at the beginning and end of the completed schedule, so that all scheduled time affects the weighted average value calculation.  Activities may reset or fix attributes as needed in their beginning or final node; note that the final node is only the "end of the activity" when C<tmavg=0>.

=head2 Reporting

The scheduling response contains a raw report of the C<schedule{attributes}> as defined in L<Schedule::Activity::Attribute/RESPONSE>.  The report can be reformatted as described in L<Schedule::Activity::Attribute::Report>.

Any schedule of activities associated with the initial configuration can generate a standalone attribute report:

  %attributes=$scheduler->computeAttributes(@activities)

This permits manual modification of activities, merging across multiple scheduling runs, or merging of annotations (below) to materialize a final attribute report.  This does not affect the attributes within the C<$scheduler> object itself.

=head1 ANNOTATIONS

=head2 Overview

Annotations are secondary messages and/or attributes that are attached to the scheduling configuration and are inserted around activity/action nodes.  Annotations are divided into named I<groups>, permitting separation by category, and each named group contains a list of annotations (or "notes").

=head2 Configuration

Annotations are configuration in the C<annotations> section of the scheduling configuration:

  %configuration=(
    annotations=>{
      'annotation group'=>[
        {annotation configuration},
        ...
      ],
      ...
    },
  )

Each named group is an array, and each note configuration is a hash, as described in L<Schedule::Activity::Annotation>.  Annotations may use named messages from the scheduling configuration.

Within an individual group, earlier annotations take priority if two events are scheduled at the same time.  Because groups are generated separately, multiple groups of annotations may have conflicting event times in the results.  Note that the C<between> setting is only enforced for each annotation individually at this time, and not for notes within the same group.

=head2 Response

Annotation groups are generated after scheduling is complete and are reported in the annotations section as:

  annotations=>{
    'group'=>{
      events=>[
        [seconds, message],
        ...
      ]
    },
  }

Messages in the response are materialized using any named messages, and have the same structure as the message response for activity/action events.

Annotations do I<not> update the C<attributes> response from C<schedule>.  Because annotations may themselves contain attributes, they are retained separately from the main schedule of activities to permit easier rebuilding.

=head2 Merging

At this time, the caller must merge groups of annotations into C<schedule{activities}> manually.  Group order may matter, and the behavior of overlapping or nearby event times must be prioritized based on needs.  When constructing schedules incrementally, it is recommended to use the C<nonote> option described in L</"Incremental Construction">.

Rudimentary merging mechanisms are provided in C<schedule-activity.pl>.

=head1 SCHEDULING ALGORITHM

=head2 Overview

The configuration of the C<next> actions is the primary contributor to the schedules that can be built.  As with all algorithms of this type, there are many configurations that simply won't work well:  For example, this is not a maze solver, a best path finder, nor a resourcing optimization system.  Scheduling success toward the stated goals generally requires that actions have different C<tmmin>, C<tmmax>, and C<tmavg>, and that actions permit reasonable repetition and recursion.  Highly imbalanced actions, such as a branch of length 10 and another of length 5000, may always fail depending on the goal.  Nevertheless, for the activities and actions so described, how does it work?

The scheduler is a randomized, opportunistic, single-step path growth algorithm.  An activity starts at the indicated node.  At each step, the C<next> entries are filtered and a random action is chosen, then the process repeats.  The selection of the next step is restricted based on the I<current time> (at the end of the action) as follows.

First, a I<random current time> is computed based on the current time, the accumulated slack and buffer, and the tension settings (see below).  If the random current time is less than the goal time, the next action will be a random non-final node, if available, or the final node if all other choices are filtered or unavailable.

If the random current time is greater than the goal time and the final action is listed as a C<next> action, it will be chosen.

In all other cases, a random C<next> action will be chosen.

=head2 Buffer and Slack

Schedule construction proceeds toward the goal time incrementally, with each action appending its C<tmavg> until the goal is reached.  If the accumulated average times were exactly equal to the goal for the activity, schedules would be unambiguous.  For repeating, recursive scheduling, however, it's necessary to consider scenarios where the actions don't quite reach the goal or where they extend beyond the goal.

Each activity node and action has buffer and slack, as defined above, that contributes to the accumulated total buffer and slack.  The amount of buffer/slack that contributes to the random current time is controlled by including C<schedule(tensionbuffer=E<gt>value)> and C<tensionslack=E<gt>value>, each between 0 and 1.  Tension effectively controls how little of each contributes toward randomization around the goal.

In the 'laziest' mode, with C<tension=0.0>, all available buffer/slack is used to establish the random current time, increasing the likelihood that it is greater than the goal.  With a lower buffer tension, for example, scheduling is more likely to reach the final activity node sooner, and thus will contain a smaller number of actions on average, each stretched toward C<tmmax>.  With a higher tension, the goal time must be met (or exceeded) before aggressively seeking the final activity node, so schedules will contain a larger number of actions, each compressed toward C<tmmin>.

The tension for slack is similar, with lower values permitting a larger number of actions beyond the goal, each compressed toward C<tmmin>, whereas with tension near 1, scheduling will seek the final activity node as soon as the schedule time exceeds the goal, resulting in a smaller number of activities.

The random computed time is a uniform distribution around the current time, but because actions are scheduled incrementally, this leads to a skewed distribution that favors a smaller number of actions.  See C<samples/tension.png> for the distributions where exactly 100 repeated actions would be expected.

The default values are 0.5 for the slack tension, and approximately 0.85 for the buffer tension.  This gives an expected number of actions that is very close to C<goal/tmavg> (skewed distribution as plus 10% minus 5%).

The scheduling response contains C<{stat}> that reports the accumulated slack and buffer used for all actions, as well as C<slackttl> and C<bufferttl> which represent the maximum available.  The amount of slack used during scheduling is C<slack/slackttl>, and the same for buffer.  These values can assist with choosing tension settings based on the specific configuration.

=head2 Consistency

Attributes may be used for filtering during schedule construction.  When scheduling an activity, a temporary history of attributes is built and used as action nodes are selected.

Node filtering applies to the last recorded attributes, independent of any actions a candidate node may take on attributes.  Attribute averages values are updated to the "random current time", as if the attribute value was fixed between the last recorded entry and the random current time, prior to node filtering comparisons.

After any filtering and random selection, each activity/action node will update attributes, after which any materialized message will update attributes.

After reaching the target time for an activity, event times are updated based on the total slack/buffer time available.  The actual attribute history is constructed from those adjusted times, and will be visible to the next activity scheduled.  Filtering is evaluated as a I<single pass> only, so average values visible during filtering may be slightly different than averages after slack/buffer adjustments.

Annotations are computed separately by groups.  Attributes arising from merged annotations do not affect attributes retroactively (nor, obviously, any node filtering).  See L</Reporting>.

Scheduling proceeds stepwise, and "consistency" is defined as adherence to the computed values I<at that time>.  No recomputation occurs, except through full retries (such as goal seeking).  All of the following can create paradoxes that are avoided with this approach:  Slack/buffer adjustments can alter attribute average values leading to different node filtering/selection.  Slack/buffer adjustments can produce times that open other action branches that may have be unavailable during scheduling.  Annotations that are merged may adjust attributes such that the nodes they are annotating would disappear.  Nodes may adjust attributes such that the final node is unreachable.

=head2 Incremental Construction

For longer schedules with multiple activities, regenerating a full schedule because of issues with a single activity can be time consuming.  A more interactive approach would be to build and verify the first activity, then review choices for the second activity schedule, append it, and continue.  After full scheduling construction, annotations can be built.

Incremental schedules can be built using the C<after> and C<nonote> options:

  # Use nonote to avoid annotation build at this time
  my %choiceA=$scheduler->schedule(nonote=>1, activities=>[[600,'activity1']]);
  my %choiceB=$scheduler->schedule(nonote=>1, activities=>[[600,'activity1']]);
  #
  # two or more choices are reviewed and one is selected
  my %res=$scheduler->schedule(after=>\%choiceB, activities=>[[600,'activity2']]);

The schedule indicated via C<after> signals that the scheduler should build the activities and extend the schedule.  Attributes are automatically loaded from the earlier part of the schedule and affect node filtering normally.

Annotations, which may apply to any node by name, are dropped when the schedule is extended.  This is because a single annotation may have a limit and match nodes across activities, so full regeneration is necessary.  To make generation more efficient, C<nonote> may be set to skip annotation generation in earlier steps.

The final result above does generate annotations, but it's also possible to pass C<nonote> at each step and then generate annotations without adding activities by calling:

  my %res=$scheduler->schedule(after=>$earlierSchedule, activities=>[]);

=head2 Goals

Goal seeking retries schedule construction and finds the best, I<random> schedule meeting criteria for attribute average values:

  %schedule=$scheduler->schedule(goal=>{
    cycles=>N,
    attribute=>{
      'name'=>{op=>'max', weight=>1},
      'name'=>{op=>'min'},
      'name'=>{op=>'eq', value=>x},
      'name'=>{op=>'ne', value=>x},
    }
  },...)

One or more attributes may be included in the goal, and each of the C<cycles> (default 10) schedules will be scored based on the configured conditions.  The C<max> and C<min> operators seek the largest/smallest attribute I<average value> for the schedule.  The C<eq> and C<ne> operators score near/far from the provided C<value>.  The optional C<weight> is a multiplier for the attribute value in the scoring function; see C<samples/goalweights.pl> for more details.  Note that generated schedules may have a different number of activities, so some attribute goals may be equivalent to finding the shortest/longest action counts.

If no schedule can be generated, the most recent error will raise via C<die()>.  Goals can be different during different invocations of incremental construction.

=head2 Per-Activity Goals

Scheduling goals may be specified per activity when calling C<schedule>:

  my %schedule=$scheduler->schedule(activities=>[
    [30,'Activity A'],
    [30,'Activity B',{goal=>{cycles=>N,attribute=>{...}}],
    [30,'Activity C'],
    ...,
  ]);

Per-activity goals apply to all immediately-preceding activities following the previous goal.  In the above example, Activities A and B will be constructed I<together>, with the overall goal as specified in Activity B.  Then, scheduling will proceed to the chain starting with C, until it encounters another activity with a goal configuration, if any.  This mirrors the behavior of incremental construction:

  my %scheduleAB =$scheduler->schedule(
    activities=>[[30,'Activity A'],[30,'Activity B']],
    goal      =>{...});
  my %scheduleABC=$scheduler->schedule(
    activities=>[[30,'Activity C']],
    after     =>\%scheduleAB,
    goal      =>undef);

When per-activity scheduling is active, any goals specified in the call to C<schedule(goal=>{...})> are unused.  Only activities with (or preceding) a goal will be scheduled with goals.  Any activities after the last specified goal will not perform goal seeking.  Placing a per-activity goal in only the final activity is therefore equivalent to a schedule-wide goal:

  my %schedule=$scheduler->schedule(
    activities=>[[10,'A'],[10,'B'],...,[10,'Z',{goal=>{GOAL}}]]);
  my %schedule=$scheduler->schedule(
    activities=>[[10,'A'],[10,'B'],...,[10,'Z']],
    goal=>{GOAL});

Goal scheduling for an activity may be skipped with the goal C<{cycles=E<gt>1,attribute=E<gt>{}}>, or by calling incremental construction with goals only for the desired activities.

=head1 IMPORT MECHANISMS

=head2 Markdown

Rudimentary markdown support is included for lists of actions that are all equally likely for a given activity:

  * Activity One, 5min
    - Action one, 1min
    - Action two, 2min
    - Action three, 3min
  2. Activity Two, 5min
    * Action one, 1min
    * Action two, 2min
    * Action three, 3min
  - Activity Three, 5min
    * Action one, 5min

Any list identification markers may be used (number plus period, asterisks, hyphen).  One or more leading whitespace (tabs or spaces) indicates an action; otherwise the line indicates an activity.  Times are specified as C<\d+min> or C<\d+sec>.  If only a single action is included in an activity, its configured time should be equal to the activity time.

The imported configuration permits an activity to be followed by any of its actions, and any action can be followed by any other action within the activity (but not itself).  Any action can terminate the activity.

The full settings needed to build a schedule can be loaded with C<%settings=loadMarkdown(text)>, and both C<$settings{configuration}> and C<$settings{activities}> will be defined so an immediate call to C<schedule(%settings)> can be made.

=head1 BUGS

It is possible for some settings to get stuck in an infinite loop:  Be cautious setting C<tmavg=0> for actions.

=head1 SEE ALSO

L<Schedule::LongSteps> and L<Chronic> address the same type of schedules with slightly different goals.
