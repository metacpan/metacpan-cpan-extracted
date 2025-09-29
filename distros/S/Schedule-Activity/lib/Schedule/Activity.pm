package Schedule::Activity;

use strict;
use warnings;
use Ref::Util qw/is_arrayref is_hashref is_plain_hashref/;
use Schedule::Activity::Node;

our $VERSION='0.1.0';

sub buildConfig {
	my (%base)=@_;
	my %res;
	while(my ($k,$node)=each %{$base{node}}) {
		if(is_plain_hashref($node)) { $res{node}{$k}=Schedule::Activity::Node->new(%$node) }
		else { $res{node}{$k}=$node }
	}
	while(my ($k,$node)=each %{$res{node}}) {
		my @nexts=map {$res{node}{$_}} @{$$node{next}//[]};
		if(@nexts) { $$node{next}=\@nexts }
		else       { delete($$node{next}) }
		if(defined($$node{finish})) { $$node{finish}=$res{node}{$$node{finish}} }
	}
	return %res;
}

sub validateConfig {
	my (%config)=@_;
	my (@errors,@invalids);
	if(!is_hashref($config{node})) { push @errors,'Config is missing:  node'; $config{node}={} }
	while(my ($k,$node)=each %{$config{node}}) {
		if(!is_hashref($node)) { push @errors,"Node $k, Invalid structure"; next }
		my @nerrors=Schedule::Activity::Node::validate(%$node);
		if(@nerrors) { push @errors,map {"Node $k, $_"} @nerrors; next }
		@invalids=grep {!defined($config{node}{$_})} @{$$node{next}//[]};
		if(@invalids) { push @errors,"Node $k, Undefined name in array:  next" }
		if(defined($$node{finish})&&!defined($config{node}{$$node{finish}})) { push @errors,"Node $k, Undefined name:  finish" }
	}
	return @errors;
}

sub findpath {
	my (%opt)=@_;
	my ($tm,$slack,$buffer,@res)=(0,0,0);
	my $tension=1-($opt{tension}//0.5);
	my ($node,$conclusion)=($opt{start},$opt{finish});
	while($node&&($node ne $conclusion)) {
		push @res,[$tm,$node];
		$node->increment(\$tm,\$slack,\$buffer);
		if(
			($tm+$tension*$buffer>=$opt{goal})
			&&($opt{goal}-$tm>=$buffer)
			&&($node->hasnext($conclusion))
		) {
			push @res,[$tm,$conclusion];
			$conclusion->increment(\$tm,\$slack,\$buffer);
			$node=undef;
		}
		elsif($tm>=$opt{goal}) {
			if($node->hasnext($conclusion)) {
				push @res,[$tm,$conclusion];
				$conclusion->increment(\$tm,\$slack,\$buffer);
				$node=undef;
			}
			elsif($tm-$opt{goal}<$slack) { $node=$node->nextrandom() }
			elsif($opt{backtracks}>0) { return (retry=>1,error=>"No backtracking support") }
			else { die 'this needs to backtrack or retry' }
		}
		else { $node=$node->nextrandom(not=>$conclusion) }
	}
	if($node&&($node eq $conclusion)) {
		push @res,[$tm,$conclusion];
		$conclusion->increment(\$tm,\$slack,\$buffer);
		$node=undef;
	}
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
		$res[$i][2]=$dt-($res[$i][1]{tmmin}//0);
		$res[$i][3]=($res[$i][1]{tmmax}//0)-$dt;
	}
	return @res;
}

sub buildSchedule {
	my (%opt)=@_;
	if(!is_hashref($opt{configuration})) { $opt{configuration}={} }
	if(!is_arrayref($opt{activities}))   { $opt{activities}=[] }
	my @errors=validateConfig(%{$opt{configuration}});
	if(@errors) { return (error=>\@errors) }
	my %config=buildConfig(%{$opt{configuration}});
	#
	my ($tmoffset,%res)=(0);
	foreach my $activity (@{$opt{activities}}) {
		foreach my $entry (scheduler(goal=>$$activity[0],node=>$config{node}{$$activity[1]},config=>\%config)) {
			push @{$res{activities}},[$$entry[0]+$tmoffset,@$entry[1..$#$entry]];
		}
		$tmoffset+=$$activity[0];
	}
	return %res;
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity - Generate random activity schedules

=head1 VERSION

Version 0.1.0

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
    },
    activities=>[
      [30,'Activity'],
    ],
  );
  print join("\n",map {"$$_[0]:  $$_[1]{message}"} @{$schedule{activities}});

=head1 DESCRIPTION

EXPERIMENTAL:  This module is currently experimental and subject to change.  Core functionality is safe for use in this version, but there are still some exceptional cases that may C<die()>; callers should plan to trap and handle these exceptions accordingly.  Documentation per option below may note other areas subject to change.

This module permits building schedules of I<activities> each containing randomly-generated lists of I<actions>.  This two-level approach uses explicit I<goal> times to construct the specified list of activities.  Within activities, actions are chosen within configured limits, possibly with randomization and cycling, using I<slack> and I<buffer> timing adjustments to achieve the goal.

For additional examples, see the C<samples/> directory.

=head1 CONFIGURATION

A configuration for scheduling contains the following sections:

  %configuration=(
    node=>{...}
    message  =>... # not yet supported
    insertion=>... # not yet supported
  )

Both activities and actions are configured as named C<node> entries.  With this structure, an action and activity can share a C<message>, but must use different key names.  

  'activity name'=>{
    message=>... # an optional message string or object
    next=>[...], # list of child node names
    finish=>'activity conclusion',
    (time specification)
  }
  'action name'=>{
    message=>... # an optional message string or object
    next=>[...], # list of child node names
    (time specification)
  }

The list of C<next> nodes is a list of names, which must be defined in the configuration.  During schedule construction, entries will be I<chosen randomly> from the list of C<next> nodes.  The conclusion must be reachable from the initial activity, or scheduling will fail.  There is no further restriction on the items in C<next>:  Scheduling specifically supports cyclic/recursive actions, including self-cycles.

There is no functional difference between activities and actions, except that a node must contain C<finish> to be used for activity scheduling.  Nomenclature is primarily to support schedule organization:  A collection of random actions is used to build an activity; a sequence of activities is used to build a schedule.

=head2 Time specification

The only time specification currently supported is:

  tmmin=>seconds, tmavg=>seconds, tmmax=>seconds

Values must be non-negative numbers.  All three values may be identical.  Note that scheduling to a given goal may be impossible without I<slack> or I<buffer> within some of the actions:

  slack =tmavg-tmmin
  buffer=tmmax-tmavg

The slack is the amount of time that could be reduced in an action before it would need to be removed/replaced in the schedule.  The buffer is the amount of time that could be added to an action before additional actions would be needed in the schedule.

Future changes may support abbreviated time specifications, automatic slack/buffering, univeral slack/buffer ratios, and open-ended/relaxed slack/buffering.

=head2 Messages

Each activity/action node may contain an optional message string.  Nothing in the scheduler uses these messages; they are provided so the caller can easily handle the returned schedules.

Future changes may support an array of messages, with each entry being a string or object.  This would support configured random message selection.  A message hash may also be supported.  One proposal links the string in the C<message>, to the collection of top-level C<configuration{message}> keys; while this structure has not been fully defined, carefully choose message strings that are unlikely to clash with potential future keynames.

=head1 RESPONSE

The response from C<buildConfig> is:

  %schedule=(
    error=>['list of validation errors, if any',...],
    activities=>[
      seconds, message],
      ..,
    ],
  )

=head2 Failures

In addition to validation failures returned through C<error>, the following may cause the scheduler to C<die()>:  The activity name is undefined.  The scheduler was not able to reach the named finish node.  The number of retries or backtracking attempts has been exhausted.

The difference between the result time and the goal may cause retries when an excess exceeds the available slack, or when a shortage exceeds the available buffer.

Caution:  While startup/conclusion of activities may have fixed time specifications, at this time it is recommended that actions always contain some slack/buffer.  There is currently no "relaxing mechanism" during scheduling, so a configured with no slack nor buffer must exactly meet the goal time requested.

=head1 SEE ALSO

L<Schedule::LongSteps> and L<Chronic> address the same type of schedules with slightly different goals.
