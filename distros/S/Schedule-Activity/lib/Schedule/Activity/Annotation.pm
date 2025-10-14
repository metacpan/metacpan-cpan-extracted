package Schedule::Activity::Annotation;

use strict;
use warnings;
use Ref::Util qw/is_hashref is_regexpref/;
use Scalar::Util qw/looks_like_number/;

our $VERSION='0.1.3';

my %property=map {$_=>undef} qw/message nodes before between p limit attributes note/;

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	return bless(\%opt,$class);
}

sub validate {
	my (%node)=@_;
	my @errors;
	foreach my $k (grep {!exists($property{$_})} keys(%node)) { push @errors,"Invalid key:  $k" }
	if(!defined($node{message}))    { push @errors,'Expected:  message' }
	if(!is_regexpref($node{nodes})) { push @errors,'Expected regexp:  nodes' }
	foreach my $k (grep {defined($node{$_})} qw/between p limit/) {
		if(!looks_like_number($node{$k})) { push @errors,"Invalid value:  $k" }
		elsif($node{$k}<0)                { push @errors,"Negative value:  $k" }
	}
	$node{before}//={};
	if(!is_hashref($node{before})) { push @errors,'Before invalid structure' }
	else { foreach my $k (grep {defined($node{before}{$_})} qw/min max/) {
		if(!looks_like_number($node{before}{$k})) { push @errors,"Invalid value:  before{$k}" }
		} }
	return @errors;
}

sub annotate {
	my ($self,@schedule)=@_;
	my %before=%{$$self{before}//{}};
	my %opt=(
		p        =>$$self{p}//1,
		beforemin=>$before{min}//$before{max}//1,
		beforemax=>$before{max}//$before{min}//1,
		between  =>$$self{between}//1,
	);
	my $p=$$self{p}//1;
	my @matchidx=grep {rand()<=$opt{p}} grep {$schedule[$_][1]{keyname}=~$$self{nodes}} (0..$#schedule);
	if(!@matchidx) { return }
	my @notes;
	foreach my $i (@matchidx) {
		my @tmwindow=sort {$a<=>$b} ($schedule[$i][0]-$opt{beforemax},$schedule[$i][0]-$opt{beforemin});
		if($i>0)          { my $tm=$schedule[$i-1][0]+1; if($tmwindow[0]<=$tm) { $tmwindow[0]=$tm } }
		if($i<$#schedule) { my $tm=$schedule[$i+1][0]-1; if($tmwindow[1]>=$tm) { $tmwindow[1]=$tm } }
		if($tmwindow[1]>=$tmwindow[0]) { push @notes,[@tmwindow] }
	}
	if($$self{limit}) { while(1+$#notes>$$self{limit}) {
		my $idx=int(rand(1+$#notes)); splice(@notes,$idx,1) } }
	for(my $i=1;$i<=$#notes;$i++) {
		if($notes[$i][0]-$notes[$i-1][0]<$opt{between}) {
			if($notes[$i][1]-$notes[$i-1][0]<$opt{between}) { splice(@notes,$i,1); $i-- }
			else { $notes[$i][0]=$notes[$i-1][0]+$opt{between} }
		}
	}
	return map {[$$_[0], {map {$_=>$$self{$_}} grep {$$self{$_}} qw/message attributes/}]} @notes;
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity::Annotation - Schedule around other events

=head1 SYNOPSIS

  my $annotation=Schedule::Activity::Annotation->new(
    message=>Schedule::Activity::Message configuration,
    nodes  =>qr/.../,
    before =>{
      min=>30,
      max=>90,
    }
    between=>120,
    p      =>1.00,
    limit  =>3,
    attributes=>{...},
  );
  
  my @notes=$annotation->annotate(@{$schedule{activities}});
  @{$schedule{activities}}=sort {$$a[0]<=>$$b[0]} @{$schedule{activities}},@notes;

  # or as a single step (not yet supported)
  $annotation->insert($schedule{activities});

=head1 DESCRIPTION

A scheduling I<annotation> is a secondary event to be attached to an existing schedule.  The given message will be inserted around the matching action keynames (C<nodes>), with probability C<p>, and may be inserted throughout the schedule up to C<limit> times.  Inserted messages will be C<min> to C<max> seconds before the matching nodes, if the annotation can be placed I<directly adjacent> to the matching node, and the spacing between different instances of the annotation must be at least C<between>.

Annotations permit the scheduling of messages that are not directly associated with activities/actions and can often be helpful to provide the user with reminders, warning messages, or to set the mood, pace, and so forth.  In the example of an exercise schedule where the actions are exercise sets, annotations can be used to choose the music or provide positive/supportive messages.

EXPERIMENTAL:  This syntax is subject to change.

=head1 CONFIGURATION

The C<message>, required, should match any form supported in L<Schedule::Activity>.

The C<nodes>, required, is a regular expression that specifies the matching activity/action I<key names>.  Use alternation to match against more than one candidate key.  Since activities always start and finish with specific nodes, an annotation is unlikely to be needed for an event that follows/precedes each.  One benefit of annotations in such a case is the ability to leverage different annotation configurations with the same scheduling configuration.

The default C<before> values are one, which means an annotation will be placed 1sec before the matching node if there is space in the schedule.  Within a configured range, an annotation will only be placed adjacent to the matching action.  A minimum can be used to ensure the user has time to hear/read the message and react.  Negative values can be used to place the annotation after the matching node.

The C<between> value, default 1sec, limits the total number of annotations based on the proximity of the matching actions.  No more than one annotation will be attached to each action.

The rate C<p> is the probability of the annotation being attached to a matching node.  Default 1.

The C<limit> specifies the maximum number of annotations to attach.  C<limit=0> or undefined is unlimited.

=head1 ATTRIBUTES

Attributes can be attached to the annotation itself and/or within the C<message> object.  Note that the C<annotate> and C<insert> helpers only provide updates to the schedule.  The caller must update any attribute statistics within the schedule as well as the summary statistics for the overall schedule.  Future improvements in C<insert> may support a setting/callback for updating statistics, but there is a benefit to keeping annotation schedules separate from the main list of activities:  Multiple annotations are easier to recompute when not attached to the main schedule, permitting easier adjustment toward attribute goals.

=cut
