package Schedule::Activity;

use strict;
use warnings;
use Ref::Util qw/is_arrayref is_hashref is_plain_hashref/;
use Schedule::Activity::Annotation;
use Schedule::Activity::Attributes;
use Schedule::Activity::Message;
use Schedule::Activity::Node;
use Schedule::Activity::NodeFilter;

our $VERSION='0.1.6';

sub buildConfig {
	my (%base)=@_;
	my %res;
	while(my ($k,$node)=each %{$base{node}}) {
		if(is_plain_hashref($node)) { $res{node}{$k}=Schedule::Activity::Node->new(%$node) }
		else { $res{node}{$k}=$node }
		$res{node}{$k}{keyname}=$k;
	}
	my $msgNames=$base{messages}//{};
	while(my ($k,$node)=each %{$res{node}}) {
		my @nexts=map {$res{node}{$_}} @{$$node{next}//[]};
		if(@nexts) { $$node{next}=\@nexts }
		else       { delete($$node{next}) }
		if(defined($$node{finish})) { $$node{finish}=$res{node}{$$node{finish}} }
		$$node{msg}=Schedule::Activity::Message->new(message=>$$node{message},names=>$msgNames);
		if(is_plain_hashref($$node{require})) { $$node{require}=Schedule::Activity::NodeFilter->new(%{$$node{require}}) }
	}
	return %res;
}

sub validateConfig {
	my ($attr,%config)=@_;
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
			if(!is_hashref($msga)) { push @errors,"Messages $namea invalid structure" }
			elsif(defined($$msga{attributes})&&!is_hashref($$msga{attributes})) { push @errors,"Messages $namea invalid attributes" }
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
		foreach my $kv (Schedule::Activity::Message::attributesFromConf($$node{message})) { push @nerrors,$attr->register($$kv[0],%{$$kv[1]}) }
		if(@nerrors) { push @errors,map {"Node $k, $_"} @nerrors; next }
		@invalids=grep {!defined($config{node}{$_})} @{$$node{next}//[]};
		if(@invalids) { push @errors,"Node $k, Undefined name in array:  next" }
		if(defined($$node{finish})&&!defined($config{node}{$$node{finish}})) { push @errors,"Node $k, Undefined name:  finish" }
	}
	return @errors;
}

sub nodeMessage {
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
	my $tension=1-($opt{tension}//0.5);
	my ($node,$conclusion)=($opt{start},$opt{finish});
	$opt{attr}->push();
	while($node&&($node ne $conclusion)) {
		push @res,[$tm,$node];
		push @{$res[-1]},nodeMessage($opt{attr},$tm+$opt{tmoffset},$node);
		$node->increment(\$tm,\$slack,\$buffer);
		if(
			($tm+$tension*$buffer>=$opt{goal})
			&&($opt{goal}-$tm<=$buffer)
			&&($node->hasnext($conclusion))
		) {
			push @res,[$tm,$conclusion];
			push @{$res[-1]},nodeMessage($opt{attr},$tm+$opt{tmoffset},$conclusion);
			$conclusion->increment(\$tm,\$slack,\$buffer);
			$node=undef;
		}
		elsif($tm>=$opt{goal}) {
			if($node->hasnext($conclusion)) {
				push @res,[$tm,$conclusion];
				push @{$res[-1]},nodeMessage($opt{attr},$tm+$opt{tmoffset},$conclusion);
				$conclusion->increment(\$tm,\$slack,\$buffer);
				$node=undef;
			}
			elsif($tm-$opt{goal}<$slack) { $node=$node->nextrandom(tm=>$tm,attr=>$opt{attr}{attr}) }
			elsif($opt{backtracks}>0) { $opt{attr}->pop(); return (retry=>1,error=>"No backtracking support") }
			else { die 'this needs to backtrack or retry' }
		}
		else { $node=$node->nextrandom(not=>$conclusion,tm=>$tm,attr=>$opt{attr}{attr}) }
	}
	if($node&&($node eq $conclusion)) {
		push @res,[$tm,$conclusion];
		push @{$res[-1]},nodeMessage($opt{attr},$tm+$opt{tmoffset},$conclusion);
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

# opt{tension} is currently _only_ the percentage of total buffer that can be used
# in achieiving the goal time.  If tension=1, scheduling requires that the action times
# exceed the goal time, and then all adjustments are made using slack time.
# If tension=0, the scheduled action time may be less than the goal time up to the total
# buffer time, in which case the adjustments are made using the buffer time.
#
# Ideally, there should be tension-buffer and tension-slack.

sub scheduler {
	my (%opt)=@_; # goal,node,config
	if(!is_hashref($opt{node})) { die 'scheduler called with invalid node' }
	$opt{retries}//=10; $opt{retries}--;
	if($opt{retries}<0) { die $opt{error}//'scheduling retries exhausted' }
	#
	my %path=findpath(
		start     =>$opt{node},
		finish    =>$opt{node}{finish},
		goal      =>$opt{goal},
		tension   =>$opt{tension},
		retries   =>$opt{retries},
		backtracks=>2*$opt{retries},
		attr      =>$opt{attr},
		tmoffset  =>$opt{tmoffset},
	);
	if($path{retry}) { return scheduler(%opt,retries=>$opt{retries},error=>$path{error}//'Retries exhausted') }
	my @res=@{$path{steps}};
	my ($tm,$slack,$buffer)=@path{qw/tm slack buffer/};
	if($res[-1][1] ne $opt{node}{finish}) { die "Didn't reach finish node" }
	#
	my $excess=$tm-$opt{goal};
	if(abs($excess)>0.5) {
		if(($excess>0)&&($excess>$slack))   { return scheduler(%opt,retries=>$opt{retries},error=>"Excess exceeds slack ($excess>$slack)") }
		if(($excess<0)&&(-$excess>$buffer)) { return scheduler(%opt,retries=>$opt{retries},error=>"Shortage exceeds buffer (".(-$excess).">$buffer)") }
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
		$res[$i][3]=$dt-($res[$i][1]{tmmin}//0);
		$res[$i][4]=($res[$i][1]{tmmax}//0)-$dt;
	}
	#
	# Full materialization of messages and attributes occurs after all
	# slack/buffer adjustments have been made.  Node attributes are
	# the 'defaults', which message attributes applying later.  This
	# means that all attributes will be applied, but 'set' operations in
	# messages will 'win'.
	#
	# In the future, message selection may occur during path construction,
	# to achieve goals of node filtering, but random message selection
	# here will only see the single message in that result.
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

sub buildSchedule {
	my (%opt)=@_;
	my $attr=Schedule::Activity::Attributes->new();
	if(!is_hashref($opt{configuration})) { $opt{configuration}={} }
	if(!is_arrayref($opt{activities}))   { $opt{activities}=[] }
	if(!is_hashref($opt{configuration}{annotations})) { $opt{configuration}{annotations}={} }
	#
	my @errors=validateConfig($attr,%{$opt{configuration}});
	while(my ($k,$notes)=each %{$opt{configuration}{annotations}}) {
		push @errors,map {"Annotation $k:  $_"} map {Schedule::Activity::Annotation::validate(%$_)} @$notes }

	if(@errors) { return (error=>\@errors) }
	my %config=buildConfig(%{$opt{configuration}});
	#
	my ($tmoffset,%res)=(0);
	foreach my $activity (@{$opt{activities}}) {
		foreach my $entry (scheduler(goal=>$$activity[0],node=>$config{node}{$$activity[1]},config=>\%config,attr=>$attr,tmoffset=>$tmoffset)) {
			push @{$res{activities}},[$$entry[0]+$tmoffset,@$entry[1..$#$entry]];
		}
		$tmoffset+=$$activity[0];
		$attr->log($tmoffset); # potentially overwritten by subsequent nodes
	}
	%{$res{attributes}}=$attr->report();
	while(my ($group,$notes)=each %{$opt{configuration}{annotations}}) {
		my @schedule;
		foreach my $note (@$notes) {
			my $annotation=Schedule::Activity::Annotation->new(%$note);
			foreach my $note ($annotation->annotate(@{$res{activities}})) {
				my ($message,$mobj)=Schedule::Activity::Message->new(message=>$$note[1]{message},names=>$opt{configuration}{messages}//{})->random();
				my %node=(message=>$message);
				if($$note[1]{annotations}) { $node{annotations}=$$note[1]{annotations} }
				push @schedule,[$$note[0],\%node,@$note[2..$#$note]];
			}
		}
		@schedule=sort {$$a[0]<=>$$b[0]} @schedule;
		for(my $i=0;$i<$#schedule;$i++) {
			if($schedule[$i+1][0]==$schedule[$i][0]) {
				splice(@schedule,$i+1,1); $i-- } }
		$res{annotations}{$group}{events}=\@schedule;
	}
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

Schedule::Activity - Generate random activity schedules

=head1 VERSION

Version 0.1.6

=head1 SYNOPSIS

  use Schedule::Activity;
  my %schedule=Schedule::Activity::buildSchedule(
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
      annotations=>{...},
      attributes =>{...},
      messages   =>{...},
    },
    activities=>[
      [30,'Activity'],
      ...
    ],
  );
  print join("\n",map {"$$_[0]:  $$_[1]{message}"} @{$schedule{activities}});

=head1 DESCRIPTION

This module permits building schedules of I<activities> each containing randomly-generated lists of I<actions>.  This two-level approach uses explicit I<goal> times to construct the specified list of activities.  Within activities, actions are chosen within configured limits, possibly with randomization and cycling, using I<slack> and I<buffer> timing adjustments to achieve the goal.

For additional examples, see the C<samples/> directory.

Areas subject to change are documented below.  Configurations and goals may lead to cases that currently C<die()>, so callers should plan to trap and handle these exceptions accordingly.

=head1 CONFIGURATION

A configuration for scheduling contains the following sections:

  %configuration=(
    node       =>{...}
    attributes =>...  # see below
    annotations=>...  # see below
    messages   =>...  # see below
  )

Both activities and actions are configured as named C<node> entries.  With this structure, an action and activity may have the same C<message>, but must use different key names.

  'activity name'=>{
    message=>...    # an optional message string or object
    next   =>[...], # list of child node names
    finish =>'activity conclusion',
    #
    (time specification)
    (attributes specification)
  }
  'action name'=>{
    message=>...    # an optional message string or object
    next   =>[...], # list of child node names
    #
    (time specification)
    (attributes specification)
  }

The list of C<next> nodes is a list of names, which must be defined in the configuration.  During schedule construction, entries will be I<chosen randomly> from the list of C<next> nodes.  The conclusion must be reachable from the initial activity, or scheduling will fail.  There is no further restriction on the items in C<next>:  Scheduling specifically supports cyclic/recursive actions, including self-cycles.

There is no functional difference between activities and actions except that a node must contain C<finish> to be used for activity scheduling.  Nomenclature is primarily to support schedule organization:  A collection of random actions is used to build an activity; a sequence of activities is used to build a schedule.

=head2 Time specification

The only time specification currently supported is:

  tmmin=>seconds, tmavg=>seconds, tmmax=>seconds

Values must be non-negative numbers.  All three values may be identical.  Note that scheduling to a given goal may be impossible without I<slack> or I<buffer> within some of the actions:

  slack =tmavg-tmmin
  buffer=tmmax-tmavg

The slack is the amount of time that could be reduced in an action before it would need to be removed/replaced in the schedule.  The buffer is the amount of time that could be added to an action before additional actions would be needed in the schedule.

Providing any time value will automatically set any missing values at the fixed ratios 3,4,5.  EG, specifying only C<tmmax=40> will set C<tmmin=24> and C<tmavg=32>.  If provided two time values, priority is given to C<tmavg> to set the third.

Future changes may support adjusting these ratios, automatic slack/buffering, univeral slack/buffer ratios, and open-ended/relaxed slack/buffering.

=head2 Messages

Each activity/action node may contain an optional message.  Messages are provided so the caller can easily format the returned schedules.  While message attributes may be used during schedule, the message strings themselves are not used during scheduling.  Messages may be:

  message=>'A message string'
  message=>'named message key'
  message=>['An array','of alternates','chosen randomly']
  message=>{name=>'named message key'}
  message=>{
    alternates=>[
      {message=>'A hash containing an array', attributes=>{...}}
      {message=>'of alternates',              attributes=>{...}}
      {message=>'with optional attributes',   attributes=>{...}}
      {message=>'named message key'}
      {name=>'named message key'}
    ]
  }

Message selection is randomized for arrays and a hash of alternates.  Any attributes are emitted with the attribute response values, described below.

=head1 RESPONSE

The response from C<buildSchedule> is:

  %schedule=(
    error=>['list of validation errors, if any',...],
    activities=>[
      [seconds, message],
      ..,
    ],
    annotations=>{
      'group'=>{
        events=>[
          [seconds, message],
        ]
      },
      ...
    },
    attributes=>{
      name=>{
        y  =>(final value),
        xy =>[[tm,value],...],
        avg=>(average, depends on type),
      },
      ...
    },
  )

=head2 Failures

In addition to validation failures returned through C<error>, the following may cause the scheduler to C<die()>:  The activity name is undefined.  The scheduler was not able to reach the named finish node.  The number of retries or backtracking attempts has been exhausted.

The difference between the result time and the goal may cause retries when an excess exceeds the available slack, or when a shortage exceeds the available buffer.

Caution:  While startup/conclusion of activities may have fixed time specifications, at this time it is recommended that actions always contain some slack/buffer.  There is currently no "relaxing mechanism" during scheduling, so a configured with no slack nor buffer must exactly meet the goal time requested.

=head1 ATTRIBUTES

Attributes permit tracking boolean or numeric values during schedule construction.  The result of C<buildSchedule> contains attribute information that can be used to verify or adjust the schedule.

=head2 Types

The two types of attributes are C<bool> or C<int>, which is the default.  A boolean attribute is primarily used as a state flag.  An integer attribute can be used both as a counter or gauge, either to track the number of occurrences of an activity or event, or to log varying numeric values.

=head2 Configuration

Multiple attributes can be referenced from any activity/action.  For example:

  'activity/action name'=>{
    attributes=>{
      temperature=>{set=>value, incr=>value, decr=>value, note=>'comment'},
      counter    =>{set=>value, incr=>value, note=>'comment'},
      flag       =>{set=>0/1, note=>'comment'},
    },
  }

Any attribute may include a C<note> for convenience, but this value is not stored nor reported.

The main configuration can also declare attribute names and starting values.  It is recommended to set any non-zero initial values in this fashion, since calling C<set> requires that activity to always be the first requested in the schedule.  Boolean values must be declared in this section:

  %configuration=(
    attributes=>{
      flagA  =>{type=>'bool'},
      flagB  =>{type=>'bool', value=>1},
      counter=>{type=>'int',  value=>0},
    },
  )

Attributes within message alternate configurations and named messages are identified during configuration validation.  Together with activity/action configurations, attributes are verified before schedule construction, which will fail if an attribute name is referenced in a conflicting manner.

=head2 Response values

The response from C<buildSchedule> includes an C<attributes> section as:

  attributes=>{
    name=>{
      y  =>(final value),
      xy =>[[tm,value],...],
      avg=>(average, depends on type),
    },
    ...
  }

The C<y> value is the final value at the conclusion of the final activity in the schedule.  The C<xy> contains an array of all values and the times at which they changed; see Logging.  The C<avg> is roughly the time-weighted average of the value, but this depends on the attribute type.

If an activity containing a unique attribute is not used during construction, the attribute will still be included in the response with its default and initial value.

=head2 Integer attributes

The C<int> type is the default for attributes.  If initialized in C<%configuration>, it may specify the type, or the value, or both.  The default value is zero, but this may be overwritten if the first activity node specifically calls C<set>.

Integer attributes within activity/actions support all of:  C<set>, C<incr>, C<decr>.  There is no current restriction on values; they may be integers or real numbers, positive or negative.

The reported C<avg> is the overall time-weighted average of the values, computed via a trapezoid rule.  That is, if C<tm=0, value=2> and C<tm=10, value=12>, the average is 7 with a weight of 10.  See Logging for more details about averages over activity boundaries.

=head2 Boolean attributes

The C<bool> type must be declared in C<%configuration>.  The value may be specified, but defaults to zero/false.

Boolean attributes within activity/actions support:  C<set>.  Currently there is no restriction on values, but the behavior is only defined for values 0/1.

The reported C<avg> is the percentage of time in the schedule for which the flag was true.  That is, if C<tm=0, value=0>, and C<tm=7, value=1>, and C<tm=10, value=1> is the complete schedule, then the reported average for the boolean will be C<0.3>.

=head2 Precedence

When an activity/action node and a selected message both contain attributes, the value of the attribute is updated first from the action node and then from the message node.  For boolean attributes, this means the "value set in the message has precedence".  For integer attributes, suppose that the value is initially zero; then, if both the action and message have attribute operators, the result will be:

  Action  Message  Value
  set=1   set=2      2
  incr=3  set=4      4
  set=5   incr=6    11
  incr=7  incr=8    15

=head2 Logging

The reported C<xy> is an array of values of the form C<(tm, value)>, with each representing an activity/action referencing that attribute built into the schedule.  Each attribute will have its initial value of C<(0, value)>, either the default or the value specified in C<configuration{attributes}>.

For integers, attributes may be fixed in the log at their current value by calling C<incr=0>.  There is currently no similar mechanism for booleans.

(Approaching a decision):  As of version 0.1.1, attribute logging will also occur at the end of every activity, so changes in attributes across activity boundaries do not affect the average value calculation.  In particular, the starting value in any given activity is the most recent value in the previous activity, adjusted by any operator in the activity node itself.  For example, suppose two activities go from C<tm=0> to 10, and from C<tm=10> to 20.  If an attribute is set to C<tm=0, value=5> and not set again until C<tm=15, value=0>, then the average in the first activity is five.

Proposed:  Because C<incr=0> can fix the value of an integer attribute in the final action node of an activity, this permits the user to choose the behavior.  For Boolean attributes, they are already fixed until the next C<set> event, so the average value should be equivalent whether these are pinned at the end of the activity or not.


=head1 ANNOTATIONS

A scheduling configuration may contain a list of annotations:

  %configuration=(
    annotations=>{
      'annotation group'=>[
        {annotation configuration},
        ...
      ]
    },
  )

Scheduling I<annotations> are a collection of secondary events to be attached to the built schedule and are configured as described in L<Schedule::Activity::Annotation>.  Each named group can have one or more annotation.  Each annotation will be inserted around the matching actions in the schedule and be reported from C<buildSchedule> in the annotations section as:

  annotations=>{
    'group'=>{
      events=>[
        [seconds, message],
        ...
      ]
    },
  }

Within an individual group, earlier annotations take priority if two events are scheduled at the same time.  Multiple groups of annotations may have conflicting event schedules with event overlap.  Note that the C<between> setting is only enforced for each annotation individually at this time.

Annotations do I<not> update the C<attributes> response from C<buildSchedule>.  Because annotations may themselves contain attributes, they are retained separately from the main schedule of activities to permit easier rebuilding.  At this time, however, the caller must verify that annotation schedules before merging them and their attributes into the schedule.  Annotations may also be built separately after schedule construction as described in L<Schedule::Activity::Annotation>.

Annotations may use named messages, and messages in the annotations response structure are materialized using the named message configuration passed to C<buildSchedule>.

=head1 NAMED MESSAGES

A scheduling configuration may contain a list of common messages.  This is particularly useful when there are a large number of common alternate messages where copy/pasting through the scheduling configuration would be egregious.

  %configuration=(
    messages=>{
      'key name'=>{ any regular message configuration }
			...
    },
  )

Any message configuration within activity/action nodes may then reference the message by its key as shown above.  During message selection, any string message or configured C<name> will return the message configuration for C<key=name>, if it exists, or will return the string message.  If a configured message string matches a referenced name, the name takes precedence.

The configuration of a named message may only create string, array, or hash alternative messages; it cannot reference another name.

This feature is experimental starting with version 0.1.2.

=head1 FILTERING

Experimental starting with version 0.1.6.

Action nodes may include prerequisites before they will be selected during scheduling:

  'action name'=>{
    require=>{
      ...
    }
    ...
  }

During schedule construction, the list of C<next> actions will be filtered by C<require> to identify candidate actions.  The current attribute values at the time of selection will be used to perform the evaluation.  The available filtering criteria are fully described in L<Schedule::Activity::NodeFilter> and include attribute numeric comparison and Boolean operators.

Action filtering may be used, together with attribute setting and increments, to prevent certain actions from appearing if others have not previously occurred, or vice versa.  This mechanism may also be used to specify global or per-activity limits on certain actions.

=head2 Slack and Buffer

During scheduling, filtering is evaluated as a I<single pass> only, per activity:  When finding a sequence of actions to fulfill a scheduling goal for an activity, candidates (from C<next>) are checked based on the current attributes.  Action times during construction are based on C<tmavg>, so any filter using attribute average values will be computed as if the action sequence only used C<tmavg>.  After a solution is found, however, actions are adjusted across the total slack/buffer available, so the "materialized average" attribute values can be slightly different.

This should never affect attributes used for a stateful/flag/counter-based filter, because those value changes will still occur in the same sequence.

=head2 Bugs

Note:  As of version 0.1.6, there is an optimization that a C<next> list of only a single item will I<always> select that as the next action.  See BUGS for more details.  As a workaround, duplicate that entry in the next list to force filtering.

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

Any list identification markers may be used interchangably (number plus period, asterisks, hyphen).  One or more leading whitespace (tabs or spaces) indicates an action; otherwise the line indicates an activity.  Times are specified as C<\d+min> or C<\d+sec>.  If only a single action is included in an activity, its configured time should be equal to the activity time.

The imported configuration permits an activity to be followed by any of its actions, and any action can be followed by any other action within the activity (but not itself).  Any action can terminate the activity.

The full settings needed to build a schedule can be loaded with C<%settings=loadMarkdown(text)>, and both C<$settings{configuration}> and C<$settings{activities}> will be defined so an immediate call to C<%schedule=buildSchedule(%settings)> can be made.

=head1 BUGS

It is possible for some settings to get stuck in an infinite loop:  Be cautious setting C<tmavg=0> for actions.

There is currently a limitation with scheduling to the maximum buffer that is dependent on the behavior that a list of next actions with only a single entry will return that entry (even if it would have been otherwise filtered).  The exceptions need to be updated so that the maximum buffer includes the tmmax of the conclusion node itself, otherwise the conclusion node will get filtered out and scheduling will fail.

=head1 SEE ALSO

L<Schedule::LongSteps> and L<Chronic> address the same type of schedules with slightly different goals.
