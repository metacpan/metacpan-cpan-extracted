#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity;
use Test::More tests=>19;

subtest 'validation'=>sub {
	plan tests=>2;
	my ($scheduler,@errors);
	$scheduler=Schedule::Activity->new(
			configuration=>{
				node=>{
					'1'=>{
						next=>['3',[],{}],
						finish=>'4',
					},
					'2'=>{},
				},
			});
	is_deeply({$scheduler->schedule()},{error=>['Node 1, Undefined name in array:  next']},'node:  invalid next entry');
	$scheduler=Schedule::Activity->new(
			configuration=>{
				node=>{
					'1'=>{
						next=>['2'],
						finish=>'4',
					},
					'2'=>{},
				},
			});
	is_deeply({$scheduler->schedule()},{error=>['Node 1, Undefined name:  finish']},'node:  invalid finish entry');
};

subtest 'Simple scheduling'=>sub {
	plan tests=>5;
	my %schedule;
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>['Begin action 1'],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
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
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	%schedule=$scheduler->schedule(activities=>[[30,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[15,'Begin action 2'],
			[25,'Conclude Activity'],
		],
		'No slack/buffer');
	%schedule=$scheduler->schedule(activities=>[[32,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[16,'Begin action 2'],
			[27,'Conclude Activity'],
		],
		'With slack');
	%schedule=$scheduler->schedule(activities=>[[40,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[20,'Begin action 2'],
			[35,'Conclude Activity'],
		],
		'Maximum slack');
	%schedule=$scheduler->schedule(activities=>[[28,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[14,'Begin action 2'],
			[23,'Conclude Activity'],
		],
		'With buffer');
	%schedule=$scheduler->schedule(activities=>[[20,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[10,'Begin action 2'],
			[15,'Conclude Activity'],
		],
		'Maximum buffer');
};

subtest 'Failures'=>sub {
	plan tests=>2;
	my %schedule;
	my %configuration=(
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
				next=>['action 2'],
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
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	eval { %schedule=$scheduler->schedule(activities=>[[18,'Activity']]) };
	like($@,qr/(?i:excess exceeds slack)/,'Insufficient slack');
	eval { %schedule=$scheduler->schedule(activities=>[[42,'Activity']]) };
	like($@,qr/(?i:shortage exceeds buffer)/,'Insufficient buffer');
};

subtest 'cycles'=>sub {
	plan tests=>1;
	my $scheduler=Schedule::Activity->new(configuration=>{node=>{
		'root'=>{finish=>'terminate',next=>['cycle'],tmmin=>0,tmavg=>0,tmmax=>0},
		'cycle'=>{tmmin=>100,tmavg=>200,tmmax=>400,next=>['cycle','terminate']},
		'terminate'=>{tmmin=>0,tmavg=>0,tmmax=>0},
	}});
	my %schedule=$scheduler->schedule(unsafe=>1,activities=>[[4321,'root']]);
	ok($#{$schedule{activities}}>10,'Self-cycle');
};

subtest 'edge cases'=>sub {
	plan tests=>2;
	#
	# Improvement:  A timeout flag that permits bailout instead of hanging.
	#
	my $scheduler=Schedule::Activity->new(configuration=>{node=>{
		'root'=>{finish=>'terminate',next=>['cycle','spin'],tmmin=>0,tmavg=>0,tmmax=>0},
		'spin' =>{tmmin=>0,tmavg=>0,tmmax=>0,next=>['spin']},
		'cycle'=>{tmmin=>100,tmavg=>200,tmmax=>400,next=>['cycle','terminate']},
		'terminate'=>{tmmin=>0,tmavg=>0,tmmax=>0},
	}});
	my %schedule=$scheduler->schedule(unsafe=>0,activities=>[[3000,'root']]);
	like($schedule{error}[0],qr/Dangling/,   'Dangling action');
	like($schedule{error}[1],qr/No progress/,'No progress message');
};

subtest 'Attributes'=>sub {
	plan tests=>5;
	my $rnd=sub { my ($x)=@_; return int($x*1e6)/1e6 };
	my $scheduler=Schedule::Activity->new(configuration=>{node=>{
		root=>{
			next=>['step1'],
			tmavg=>5,
			finish=>'finish',
			attributes=>{
				counter=>{incr=>1},
				score  =>{set=>5},
				enabled=>{set=>1},
			},
		},
		'step1'=>{
			tmavg=>5,
			next=>['finish'],
			attributes=>{
				counter=>{incr=>1},
				score  =>{incr=>4},
				enabled=>{set=>0},
			},
		},
		'finish'=>{
			tmavg=>5,
			next=>['finish'],
			attributes=>{
				counter=>{incr=>1},
			},
		}},
		attributes=>{
			counter=>{type=>'int',value=>0},
			enabled=>{type=>'bool'},
		},
	});
	my %schedule=$scheduler->schedule(activities=>[[15,'root']]);
	is($#{$schedule{attributes}{score}{xy}},                2,'Score:  N');
	is(&$rnd($schedule{attributes}{score}{avg}),  &$rnd(25/3),'Score:  avg');
	is($#{$schedule{attributes}{enabled}{xy}},              2,'Enabled:  N');
	is(&$rnd($schedule{attributes}{enabled}{avg}),&$rnd( 1/3),'Enabled:  avg');
	is($schedule{attributes}{counter}{y},                   3,'Counter:  count');
};

subtest 'Message randomization'=>sub {
	plan tests=>2;
	my %schedule;
	my %configuration=(
		node=>{
			Activity=>{
				message=>[map {'act0.'.$_} (0..3)],
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>[map {'act1.'.$_} (0..3)],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
			},
			'action 2'=>{
				message=>[map {'act2.'.$_} (0..3)],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['Activity, conclude'],
			},
			'Activity, conclude'=>{
				message=>[map {'act3.'.$_} (0..3)],
				tmmin=>5,tmavg=>5,tmmax=>5,
			},
		},
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	my ($countdown,@needed,%seen,%expect)=(2e3);
	foreach my $i (0..3) {
	foreach my $j (0..3) {
		$expect{"act$i.$j"}=1;
	} }
	@needed=keys(%expect);
	while($countdown&&@needed) {
		$countdown--;
		%schedule=$scheduler->schedule(activities=>[[30,'Activity']]);
		foreach my $msg (map {$$_[1]{message}} @{$schedule{activities}}) { $seen{$msg}=1; if($msg eq ($needed[0]//'')) { shift(@needed) } }
	}
	is_deeply(\%seen,\%expect,'All combinations observed');
	is_deeply($configuration{node}{Activity}{message},[map {'act0.'.$_} (0..3)],'verify non-mutation of configuration');
};

subtest 'Message attributes'=>sub {
	plan tests=>4;
	my %configuration=(
		node=>{
			Activity=>{
				message=>{alternates=>[{message=>'Activity',attributes=>{messages=>{incr=>1}}}]},
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'finish',
				attributes=>{activity=>{incr=>1}},
			},
			'action 1'=>{
				message=>{alternates=>[{message=>'Activity',attributes=>{messages=>{incr=>1}}}]},
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
				attributes=>{action=>{incr=>1}},
			},
			'action 2'=>{
				message=>{alternates=>[{message=>'Activity',attributes=>{messages=>{incr=>1},attr2=>{incr=>1}}}]},
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['Activity, conclude'],
				attributes=>{action=>{incr=>1}},
			},
			'Activity, conclude'=>{
				message=>{alternates=>[{message=>'Activity',attributes=>{messages=>{incr=>1}}}]},
				tmmin=>5,tmavg=>5,tmmax=>5,
				next=>['finish'],
				attributes=>{activity=>{incr=>1}},
			},
			'finish'=>{
				tmmin=>0,tmavg=>0,tmmax=>0,
				attributes=>{activity=>{},action=>{},messages=>{}},
			},
		},
		attributes=>{
			messages=>{type=>'int',value=>0},
			activity=>{type=>'int',value=>0},
			action  =>{type=>'int',value=>0},
		},
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	my %schedule=$scheduler->schedule(activities=>[[30,'Activity']]);
	is_deeply($schedule{attributes}{activity}{xy},[[0,1],[25,2],[30,2]],'Activities');
	is_deeply($schedule{attributes}{action}{xy},  [[0,0],[5,1],[15,2],[30,2]],'Actions');
	is_deeply($schedule{attributes}{messages}{xy},[[0,1],[5,2],[15,3],[25,4],[30,4]],'Messages');
	is($schedule{attributes}{attr2}{y},1,'Message-only attributes');
};

subtest 'Node+Message attributes'=>sub {
	plan tests=>6;
	my $scheduler=Schedule::Activity->new(configuration=>{node=>{
		root=>{
			next=>['step1'],
			message=>{alternates=>[{message=>'One',attributes=>{boolA=>{set=>0},intA=>{set=>8}}}]},
			tmavg=>5,
			finish=>'finish',
			attributes=>{
				boolA=>{set=>1},
				intA =>{set=>9},
			},
		},
		step1=>{
			next=>['step2'],
			message=>{alternates=>[{message=>'Two',attributes=>{boolA=>{set=>1},intA=>{incr=>1}}}]},
			tmavg=>5,
			attributes=>{
				boolA=>{set=>0},
				intA =>{set=>9},
			},
		},
		step2=>{
			next=>['finish'],
			message=>{name=>'named1'},
			tmavg=>5,
			attributes=>{
				boolA=>{set=>0},
				intA =>{incr=>9},
			},
		},
		'finish'=>{
			message=>{alternates=>[{message=>'Four',attributes=>{boolA=>{set=>0},intA=>{incr=>3}}}]},
			tmavg=>5,
			attributes=>{
				boolA=>{set=>1},
				intA =>{incr=>2},
			},
		}},
		attributes=>{
			boolA=>{type=>'bool'},
			intA =>{type=>'int',value=>0},
		},
		messages=>{
			named1=>{message=>'Three',attributes=>{boolA=>{set=>1},intA=>{set=>7}}},
		},
	});
	my %schedule=$scheduler->schedule(activities=>[[20,'root']]);
	is_deeply($schedule{attributes}{boolA}{xy},
		[
			[ 0,0],
			[ 5,1],
			[10,1],
			[15,0],
			[20,0],
		],'Boolean:  set/set operations');
	is_deeply($schedule{attributes}{intA}{xy}[0],[ 0,8], 'Integer:  set/set');
	is_deeply($schedule{attributes}{intA}{xy}[1],[ 5,10],'Integer:  set/incr');
	is_deeply($schedule{attributes}{intA}{xy}[2],[10,7], 'Integer:  incr/set');
	is_deeply($schedule{attributes}{intA}{xy}[3],[15,12],'Integer:  incr/incr');
	is_deeply($schedule{attributes}{intA}{xy}[4],[20,12],'Integer:  end of activity');
};

subtest 'Attribute recomputation'=>sub {
	plan tests=>2;
	my $scheduler=Schedule::Activity->new(configuration=>{
		node=>{
			root=>{
				message=>{alternates=>[{message=>'root',attributes=>{A=>{set=>0}}}]},
				next=>['step1'],
				tmavg=>5,
				finish=>'finish',
			},
			step1=>{
				message=>{alternates=>[{message=>'step1',attributes=>{A=>{incr=>1}}}]},
				next=>['finish'],
				tmavg=>5,
			},
			finish=>{
				message=>{alternates=>[{message=>'finish',attributes=>{A=>{incr=>2}}}]},
				tmavg=>5,
			},
		},
		annotations=>{
			group=>[
				{
					message=>{alternates=>[{message=>'note1',attributes=>{A=>{incr=>1}}}]},
					nodes=>qr/step1|finish/,
					before=>{min=>1,max=>2},
				}
			],
		},
	});
	my %schedule=$scheduler->schedule(activities=>[[15,'root']]);
	my %attrScheduler=$$scheduler{attr}->report();
	my $avgSchedule=$schedule{attributes}{A}{avg};
	my %attrNotes=$scheduler->computeAttributes(@{$schedule{activities}},@{$schedule{annotations}{group}{events}});
	is_deeply({$$scheduler{attr}->report()},\%attrScheduler,'Scheduler attributes are unaltered');
	ok($avgSchedule!=$attrNotes{A}{avg},'Computed attribute differs');
};

subtest 'Annotations'=>sub {
	plan tests=>1;
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>['Begin action 1'],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
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
		annotations=>{
			'apple'=>[
				{
					message=>{alternates=>[{message=>'annotation 1',attributes=>{thing=>{incr=>1}}}]},
					nodes=>qr/action 1/,
					before=>{min=>-5,max=>-5},
				},
				{
					message=>'annotation 2',
					nodes=>qr/action 2/,
					before=>{min=>5,max=>5},
				},
			],
		},
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	my %schedule=$scheduler->schedule(activities=>[[30,'Activity']]);
	is_deeply($schedule{annotations},{apple=>{events=>[[10,{message=>'annotation 1',attributes=>{thing=>{incr=>1}}}]]}},'Annotations created, overlap removed');
};

subtest 'Named messages'=>sub {
	plan tests=>2;
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>[qw/named1 named2/],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2','Activity, conclude'],
			},
			'action 2'=>{
				message=>[qw/named1 named2/],
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 1','Activity, conclude'],
			},
			'Activity, conclude'=>{
				message=>'Conclude Activity',
				tmmin=>5,tmavg=>5,tmmax=>5,
			},
		},
		messages=>{
			named1=>{
				message=>['Named one one','Named one two'],
				attributes=>{attr1=>{incr=>1}},
			},
			named2=>{
				message=>{alternates=>[
					{message=>'Named two one',attributes=>{attr21=>{incr=>1}}},
					{message=>'Named two two',attributes=>{attr22=>{incr=>1}}},
				]},
			},
		},
	);
	my $scheduler=Schedule::Activity->new(configuration=>\%configuration);
	my %schedule=$scheduler->schedule(activities=>[[500,'Activity']]);
	my %result;
	foreach my $message (map {$$_[1]{message}} @{$schedule{activities}}) { $result{string}{$message}=1 }
	foreach my $attr (qw/attr1 attr21 attr22/) { $result{attr}{$attr}=($schedule{attributes}{$attr}{y}>0?1:0) }
	is_deeply(
		[sort keys %{$result{string}}],
		['Begin Activity','Conclude Activity','Named one one','Named one two','Named two one','Named two two'],
		'All messages');
	is_deeply($result{attr},{attr1=>1,attr21=>1,attr22=>1},'All attributes');
};

subtest 'Node filtering'=>sub {
	plan tests=>3;
	my (%schedule,$scheduler,%seen,$pass);
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1','action 2'],
				tmmin=>0,tmavg=>0,tmmax=>0,
				finish=>'Activity, conclude',
				attributes=>{act1=>{set=>0},act2=>{set=>0}},
			},
			'action 1'=>{
				message=>['Begin action 1'],
				tmmin=>4,tmavg=>5,tmmax=>6,
				next=>['action 1','action 2','Activity, conclude'],
				attributes=>{act1=>{incr=>1}},
			},
			'action 2'=>{
				message=>'Begin action 2',
				tmmin=>0,tmavg=>10,tmmax=>30,
				next=>['Activity, conclude'],
				require=>{attr=>'act1',op=>'ge',value=>4},
			},
			'Activity, conclude'=>{
				message=>'Conclude Activity',
				tmmin=>0,tmavg=>0,tmmax=>0,
			},
		},
	);
	$pass=1;
	%seen=();
	$scheduler=Schedule::Activity->new(configuration=>\%configuration);
	foreach (1..20) {
		eval { %schedule=$scheduler->schedule(unsafe=>1,activities=>[[15,'Activity']]) };
		if(!%schedule) { next }
		foreach my $msg (map {$$_[1]{message}} @{$schedule{activities}}) { $seen{$msg}=1 }
	}
	if(!defined($seen{'Begin action 1'})||defined($seen{'Begin action 2'})) { $pass=0 }
	ok($pass,'Blocked node never appears');
	#
	$pass=1;
	$configuration{node}{'action 2'}{require}{value}=4;
	$scheduler=Schedule::Activity->new(configuration=>\%configuration);
	foreach (1..20) {
		if(!$pass) { next }
		eval { %schedule=$scheduler->schedule(activities=>[[40,'Activity']]) };
		if(!%schedule) { next }
		%seen=();
		foreach my $message (map {$$_[1]{message}} @{$schedule{activities}}) {
			if($message eq 'Begin action 2') { if($seen{'Begin action 1'}<3) { $pass=0 } }
			else { $seen{$message}++ }
		}
	}
	ok($pass,'Require prereq node count');
	#
	$pass=1;
	%seen=();
	$configuration{node}{'action 1'}{next}=['Activity, conclude','action 1',map {'action 2'} (1..99)];
	$configuration{node}{'action 2'}{require}={attr=>'act2',op=>'ge',value=>1};
	$scheduler=Schedule::Activity->new(configuration=>\%configuration);
	foreach (1..20) {
		if(!$pass) { next }
		eval { %schedule=$scheduler->schedule(activities=>[[40,'Activity']]) };
		if(!%schedule) { next }
		foreach my $msg (map {$$_[1]{message}} @{$schedule{activities}}) { $seen{$msg}=1 }
	}
	if($seen{'Begin action 2'}) { $pass=0 }
	ok($pass,'Always blocked node never appears');
};

subtest 'Reachability'=>sub {
	plan tests=>8;
	my $reach=sub {
		my ($A)=@_;
		Schedule::Activity::_reachability($A);
		foreach my $va (values %{$$A{reach}}) {
			foreach my $ka (keys %$va) {
				foreach my $kb (keys %{$$va{$ka}}) { $$va{$ka}{$$A{pam}{$kb}}=delete($$va{$ka}{$kb}) }
				$$va{$$A{pam}{$ka}}=delete($$va{$ka});
			}
		}
	};
	my $builder=sub {
		my (%nodes)=@_;
		my %pam=map {$nodes{$_}=>$_} keys(%nodes);
		foreach my $k (keys %nodes) { @{$nodes{$k}{next}}=map {$nodes{$_}} @{$nodes{$k}{next}} }
		return (pam=>\%pam,built=>{node=>\%nodes});
	};
	my %activity;
	#
	%activity=&$builder(
		A=>{next=>[qw/B/],tmmin=>1,tmmax=>2},
		B=>{next=>[],tmmin=>1,tmmax=>2});
	&$reach(\%activity);
	is_deeply($activity{reach}{min}{A},{B=>1},'Single step:  min A->B');
	is_deeply($activity{reach}{max}{A},{B=>2},'Single step:  max A->B');
	is_deeply($activity{reach}{min}{B},{},    'Single step:  min B->nothing');
	is_deeply($activity{reach}{max}{B},{},    'Single step:  max B->nothing');
	#
	%activity=&$builder(
		A=>{next=>[qw/B C/],tmmin=>1,tmmax=>2},
		B=>{next=>[qw/D/],tmmin=>3,tmmax=>4},
		C=>{next=>[qw/D/],tmmin=>5,tmmax=>6},
		D=>{next=>[],tmmin=>7,tmmax=>8},
	);
	&$reach(\%activity);
	is_deeply($activity{reach}{min}{A},{B=>1,C=>1,D=>4},'Branch:  min A');
	is_deeply($activity{reach}{max}{A},{B=>2,C=>2,D=>8},'Branch:  max A');
	#
	%activity=&$builder(
		A=>{next=>[qw/B/],  tmmin=>1,tmmax=>2},
		B=>{next=>[qw/A C/],tmmin=>3,tmmax=>4},
		C=>{next=>[qw/B D/],tmmin=>5,tmmax=>6},
		D=>{next=>[],       tmmin=>7,tmmax=>8},
	);
	&$reach(\%activity);
	is_deeply($activity{reach}{min}{A},{A=>4,B=>1,C=>4,D=>9},        'lfsr:  min A');
	is_deeply($activity{reach}{max}{A},{A=>'+',B=>'+',C=>'+',D=>'+'},'lfsr:  max A');
	#
};

subtest 'Sanity checks'=>sub {
	plan tests=>7;
	my ($scheduler,@errors);
	$scheduler=Schedule::Activity->new(configuration=>{node=>{
		activity=>{
			tmavg=>5,
			next=>['action1'],
			finish=>'finish',
		},
		'action1'=>{
			tmavg=>0,
			next=>['action1','action2'],
		},
		'action2'=>{
			tmavg=>5,
			next=>[],
		},
		finish=>{
			tmavg=>5,
		},
		'activityB'=>{
			tmavg=>5,
			next=>['actionA'],
			finish=>'finishB',
		},
		'actionA'=>{
			tmavg=>5,
			next=>['finishB','action2','finish'],
		},
		finishB=>{
			tmavg=>5,
		},
		orphan=>{
			tmavg=>5,
			next=>['finishB'],
		},
	}});
	$scheduler->compile();
	@errors=$scheduler->safetyChecks();
	like($errors[0],qr/unreachable/,                    'Activity finish unreachable');
	like($errors[1],qr/orphan belongs to no activity/,  'orphan');
	like($errors[2],qr/action2 .*multiple activities/,  'dual parents');
	like($errors[3],qr/actionA .*multiple finish/,      'dual finish');
	like($errors[4],qr/Dangling action/,                'Dangling node');
	like($errors[5],qr/Dangling action/,                'Dangling node');
	like($errors[6],qr/No progress/,                    'tmavg=0');
};

subtest 'tension control'=>sub {
	plan tests=>7;
	my %schedule;
	my $scheduler=Schedule::Activity->new(
		configuration=>{
			node=>{
				root=>{next=>['A'],tmavg=>0,finish=>'finish'},
				A=>{tmmin=>25,tmavg=>30,tmmax=>35,next=>['A','finish']},
				finish=>{tmavg=>0},
			},
		});
	my @tests=(
		# slack, buffer, goal, label, validator, negate, test count (0=default), # probability of test failure over all cycles
		[1.0,1.0,299,'=12',sub { return $_[0]!=12},1,200],  # 0
		[0.0,1.0,300,'>13',sub { return $_[0]>13 },0,100],  # 1e-26 = (100*l(1-45/99))/l(10)
		[1.0,0.0,279,'<11',sub { return $_[0]<11 },0,2e3],  # 1e-22 = (2000*l(1-0.025))/l(10)
		[0.0,0.0,312,'<12',sub { return $_[0]<12 },0,2e3],  # 1e-29 = (2000*l(1-1/30))/l(10)
		[0.0,0.0,300,'>13',sub { return $_[0]>13 },0,500],  # 1e-21 = (500*l(1-69/99000-94/1000))/l(10)
		[0.0,0.7,300,'>11',sub { return $_[0]<=11 },1,200], # 0
		[0.7,0.0,300,'<14',sub { return $_[0]>=14 },1,200], # 0
	);
	foreach my $test (@tests) {
		my ($limit,$pass)=($$test[6]||1000,$$test[5]);
		my ($total,%count)=(0);
		while($limit>0) { $limit--;
			$total++;
			eval { %schedule=$scheduler->schedule(tensionslack=>$$test[0],tensionbuffer=>$$test[1],activities=>[[$$test[2],'root']]) };
			if(!%schedule) { $count{0}++; next }
			$count{1+$#{$schedule{activities}}}++;
			if(&{$$test[4]}(1+$#{$schedule{activities}})) { $pass=1-$$test[5]; $limit=0 }
		}
		if(!$pass) {
			foreach my $k (keys %count) { $count{$k}/=$total }; use Data::Dumper; print Dumper(\%count);
		}
		ok($pass,"(non-deterministic) Slack $$test[0], Buffer $$test[1], Goal $$test[2], count$$test[3]");
	}
};

subtest 'Markdown loading'=>sub {
	plan tests=>7;
	my %settings=Schedule::Activity::loadMarkdown(q|
1. Group one, 5min
	1. action one, 1min
  - action two, 2min
 * action three, 3min
-  Group two, 5min
	* action one, 3min
	* action two, 2min
	* action three, 1min
*  Group three, 5min
	* action one, 2min
	* action two, 3min
	* action three, 1min
	|);
	my $scheduler=Schedule::Activity->new(%settings);
	my %schedule=$scheduler->schedule(%settings);
	my @materialized=map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}};
	my @expect=(
		[  0,qr/Group one/],
		[  0,qr/action (one|two|three)/],
		[300,qr/Group two/],
		[300,qr/action (one|two|three)/],
		[600,qr/Group three/],
		[600,qr/action (one|two|three)/],
		[900,qr/^$/], # group three conclude
	);
	my $i=0;
	foreach my $match (@expect) {
		while(($i<$#materialized)&&($materialized[$i][0]<$$match[0])) { $i++ }
		if(($materialized[$i][1]!~$$match[1])&&($i<$#materialized)&&($materialized[$i][0]==$materialized[1+$i][0])) { $i++ }
		like($materialized[$i][1],$$match[1],"At $$match[0], $$match[1]");
	}
};

subtest 'Incremental build'=>sub {
	plan tests=>6;
	my (%config,$scheduler,$fullscheduler,$choice,@choices,%res,%fullres);
	%config=(node=>{
		'activity'=>{
			next=>['node1a','node1b'],
			tmavg=>5,
			finish=>'finish',
			attributes=>{counter=>{incr=>+1}},
		},
		'node1a'=>{
			next=>['finish'],
			tmavg=>5,
			attributes=>{counter=>{incr=>+1}},
		},
		'node1b'=>{
			next=>['finish'],
			tmavg=>5,
			attributes=>{counter=>{incr=>+1}},
		},
		'finish'=>{
			tmavg=>5,
			attributes=>{counter=>{incr=>+1}},
		},
	},
	annotations=>{
		general=>[
			{
				nodes=>qr/node1[ab]/,
				message=>'note',
				before=>{min=>-2,max=>-2},
				p=>1.0,
				limit=>1,
			},
		],
	});
	$fullscheduler=Schedule::Activity->new(configuration=>\%config);
	%fullres=$fullscheduler->schedule(activities=>[[15,'activity'],[18,'activity']]);
	#
	$scheduler=Schedule::Activity->new(configuration=>\%config);
	#
	# choose the first activity schedule
	@choices=();
	foreach (1..10) { push @choices,{$scheduler->schedule(nonote=>1,activities=>[[15,'activity']])} }
	@choices=grep {$_ && !$$_{error}} @choices;
	$choice=$choices[int(rand(1+$#choices))];
	#
	# and the second activity extends the first
	%res=$scheduler->schedule(nonote=>1,after=>$choice,activities=>[[18,'activity']]);
	#
	# separately construct annotations
	$choice={%res};
	%res=$scheduler->schedule(after=>$choice,activities=>[]);
	$res{annotations}{general}{events}[0][0]=$fullres{annotations}{general}{events}[0][0]; # actual timestamp doesn't matter
	#
	# fake the names for comparison
	foreach my $activity (grep {$$_[1]{keyname} eq 'node1b'} @{$res{activities}},@{$fullres{activities}}) { $$activity[1]{keyname}='node1a' }
	#
	is_deeply($res{activities},$fullres{activities},'activities');
	is_deeply($res{attributes},$fullres{attributes},'attributes');
	is_deeply($res{annotations},$fullres{annotations},'annotations');
	is_deeply($res{stat},$fullres{stat},'stat');
	is_deeply($res{_attr},$fullres{_attr},'_attr');
	is_deeply(\%res,\%fullres,'Two activities');
};

# Goals aren't yet available in Schedule::Activity, but the prototype is working.
# When that code provides automated searching against this optimization function,
# then this test can be updated.  Prior to that, however, score maximization should
# still be possible, and this test establishes the mechanism of testing and the
# associated probabilities.
# 
subtest 'Goal seeking'=>sub {
	plan tests=>1;
	my ($scheduler,%schedule);
	$scheduler=Schedule::Activity->new(configuration=>{node=>{
		start=>{next=>[qw/A B/],finish=>'finish',tmavg=>0,attributes=>{bee=>{set=>0}}},
		finish=>{tmavg=>0},
		A=>{attributes=>{bee=>{incr=>-1}},tmavg=>1,next=>[qw/A B finish/]},
		B=>{attributes=>{bee=>{incr=>+1}},tmavg=>1,next=>[qw/A B finish/]},
	}});
	#
	# Probability of bee=10 is 1/2^10.
	# Probability of failure in N trials is (1023/1024)^N
	# If you want to make this succeed faster, run only 5-step schedules, 1/2^5, and maxouter=436.
	#
	my ($pass,$steps,$maxouter)=(0,0,14141); # pfail<=1e-6
	for(my $outer=0;$outer<=$maxouter;$outer++) {
		$steps++;
		%schedule=$scheduler->schedule(activities=>[[10,'start']],tensionbuffer=>1,tensionslack=>1);
		if(1+$#{$schedule{activities}}!=12) { next }
		if($schedule{attributes}{bee}{y}>=10) { $pass=1; $outer=$maxouter }
	}
	ok($pass,"Goal scheduling maximized attribute ($steps steps)");
};
