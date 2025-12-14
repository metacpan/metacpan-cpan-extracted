package Schedule::Activity::Attribute;

use strict;
use warnings;

our $VERSION='0.2.6';

my %types=(
	int=>{
		change =>\&_changeInt,
		average=>\&_avgInt,
		changes=>{map {$_=>undef} qw/type value set incr decr tm note/},
	},
	bool=>{
		change =>\&_changeBool,
		average=>\&_avgBool,
		changes=>{map {$_=>undef} qw/type value set tm note/},
	},
);

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my ($tm,$y)=($opt{tm}//0,$opt{value}//0);
	my %self=(
		type =>$opt{type}//'int',
		value=>$y,
		log  =>{$tm=>$y},
		aog  =>{$tm=>$y},
		tmmax=>$tm,
		avg  =>$y,
		tmsum=>0,
	);
	if(!defined($types{$self{type}})) { die "Attribute invalid type:  $self{type}" }
	return bless(\%self,$class);
}

sub validateConfig {
	my ($self,%opt)=@_;
	my $C=$types{$$self{type}}{changes};
	my @errors=grep {!exists($$C{$_})} keys %opt;
	if(@errors) { return "Invalid attribute options/commands:  ".join(' ',@errors) }
	return;
}

sub log {
	my ($self,$tm)=@_;
	if(defined($tm)&&($tm>=$$self{tmmax})) { $$self{log}{$tm}=$$self{value}; $$self{aog}{$tm}=$$self{avg}//$$self{value}; $$self{tmmax}=$tm }
	# historic entry is not currently supported
	return $self;
}

sub change {
	my ($self,%opt)=@_;
	my $tm=$opt{tm}//$$self{tmmax};
	if($tm<$$self{tmmax}) { return $self } # historic entry is not currently supported
	#
	&{$types{$$self{type}}{change}}($self,%opt);
	$self->log($tm); # updates tmmax
	if(!defined($$self{avg})) { $self->average() }
	return $self;
}

sub report {
	my ($self)=@_;
	return (
		y  =>$$self{value},
		xy =>[$self->_xy()],
		avg=>$self->average(),
	);
}

sub value {
	my ($self)=@_;
	if($$self{type} eq 'int')  { return 0+$$self{value} }
	if($$self{type} eq 'bool') { return !!$$self{value} }
}

sub average {
	my ($self)=@_;
	if(defined($$self{avg})) { return $$self{avg} }
	($$self{avg},$$self{tmsum})=&{$types{$$self{type}}{average}}($$self{log});
	return $$self{avg};
}

sub reset {
	my ($self)=@_;
	foreach my $tm (sort {$a<=>$b} keys %{$$self{log}}) { $$self{tmmax}=$tm; $$self{value}=$$self{log}{$tm}; last }
	my ($y,$tm)=@$self{qw/value tmmax/};
	%{$$self{log}}=($tm=>$y);
	%{$$self{aog}}=($tm=>$y);
	$$self{avg}=$y;
	$$self{tmsum}=0;
	return $self;
}

sub dump {
	my ($self)=@_;
	my %res=(
		log=>{ %{$$self{log}} },
		aog=>{ %{$$self{aog}} },
		(map {$_=>$$self{$_}} qw/type value tmmax avg tmsum/),
	);
	return %res;
}

sub restore {
	my ($ref,%opt)=@_;
	if(ref($ref)) {
		foreach my $k (keys %opt) { $$ref{$k}=$opt{$k} }
		return $ref;
	}
	my $y=$opt{value}//0;
	my %self=(
		type =>$opt{type}//'int',
		value=>$y,
		log  =>$opt{log}//{},
		aog  =>$opt{aog}//{},
		tmmax=>$opt{tmmax}//0,
		avg  =>$opt{avg}//$y,
		tmsum=>$opt{tmsum}//0,
	);
	return bless(\%self,$ref);
}

sub _xy {
	my ($self)=@_;
	return map {[$_,$$self{log}{$_},$$self{aog}{$_}]} sort {$a<=>$b} keys %{$$self{log}};
}

# set=>value
# incr=>value
# decr=>value
# tm=>tm # optional, will create a log entry
sub _changeInt {
	my ($self,%opt)=@_;
	my $ya=$$self{value};
	if(defined($opt{set})) { $$self{value}=$opt{set} }
	if($opt{incr})         { $$self{value}+=$opt{incr} }
	if($opt{decr})         { $$self{value}-=$opt{decr} }
	if($opt{_log})         { }
	#
	my $dt=($opt{tm}//$$self{tmmax})-$$self{tmmax};
	if($dt==0) { $$self{avg}=$$self{tmsum}=undef; $self->log($$self{tmmax})->average() }
	elsif(defined($$self{avg})) {
		$$self{avg}=$$self{avg}*($$self{tmsum}/($$self{tmsum}+$dt))+0.5*($ya+$$self{value})*($dt/($$self{tmsum}+$dt));
		$$self{tmsum}+=$dt;
	}
	else { $$self{avg}=0.5*($ya+$$self{value}); $$self{tmsum}+=$dt }
	return $self;
}

# set=>value
# tm=>tm # optional, will create a log entry
sub _changeBool {
	my ($self,%opt)=@_;
	my $ya=$$self{value};
	if(defined($opt{set})) { $$self{value}=$opt{set} }
	if($opt{_log})         { }
	#
	my $dt=($opt{tm}//$$self{tmmax})-$$self{tmmax};
	if($dt==0) { $$self{avg}=$$self{tmsum}=undef; $self->log($$self{tmmax})->average() }
	elsif(defined($$self{avg})) {
		$$self{avg}=$$self{avg}*$$self{tmsum}/($$self{tmsum}+$dt)+$dt*$ya/($$self{tmsum}+$dt);
		$$self{tmsum}+=$dt;
	}
	else { $$self{avg}=$ya; $$self{tmsum}+=$dt }
	return $self;
}

sub _avgInt {
	my ($log)=@_;
	my ($avg,$weight,$lasttm,$lasty)=(0,0);
	foreach my $tm (sort {$a<=>$b} keys(%$log)) {
		if(!defined($lasttm)) { ($lasttm,$lasty,$avg,$weight)=($tm,$$log{$tm},$$log{$tm},0); next }
		my $dt=$tm-$lasttm;
		$avg=$weight/($weight+$dt)*$avg+0.5*$dt/($weight+$dt)*($lasty+$$log{$tm});
		$weight+=$dt;
		$lasttm=$tm;
		$lasty=$$log{$tm};
	}
	return ($avg,$weight);
}

sub _avgBool {
	my ($log)=@_;
	my ($sum,$weight,$lasttm,$lasty)=(0,0);
	foreach my $tm (sort {$a<=>$b} keys(%$log)) {
		if(!defined($lasttm)) { ($lasttm,$lasty,$sum,$weight)=($tm,$$log{$tm},$$log{$tm},0); next }
		my $dt=$tm-$lasttm;
		$sum+=$lasty*($tm-$lasttm);
		$weight+=$dt;
		$lasttm=$tm;
		$lasty=$$log{$tm};
	}
	if($weight==0) { return ($sum,$weight) }
	return ($sum/$weight,$weight);
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity::Attribute - Updating, tracking, and reporting numeric values.

=head1 SYNOPSIS

  my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>0,tm=>0);
  $attr->change(tm=>10,set=>10);
  $attr->change(tm=>20,set=>20);
  print $attr->value();
  print $attr->average();

=head1 DESCRIPTION

This module is responsible for individual attributes.  It tracks values for the attribute, facilitates changes, and handles reporting.

Attributes are intended to be I<typed>, so cross-type requests may produce failures.

=head1 CONFIGURATION

=head2 Declaration

Named attributes in scheduling configurations may provide the following:

  type =>'bool' or 'int'
  value=>numeric
  note =>'any comment'

Attributes are integers initialized to zero by default.  An initialization may include a C<note> for convenience, but this value is not stored nor reported.

=head2 Changes

Attribute changes within scheduling configurations may include the following:

  set =>value
  incr=>value (only for int)
  decr=>value (only for int)
  note=>'any comment'

A change may include a C<note> for convenience, but this value is not stored nor reported.

=head1 TYPES

The two types of attributes are C<bool> or C<int>, which is the default.  A boolean attribute is primarily used as a state flag.  An integer attribute can be used both as a counter or gauge, either to track the number of occurrences of an activity or event, or to log varying numeric values.

=head2 Integer attributes

The C<int> type is the default.  The default initial value is zero.

Integer attributes may change with any of:  C<set>, C<incr>, C<decr>.  There is no actual restriction on numeric type so any Perl L<number> is valid, integers or real numbers, positive or negative.

The reported C<avg> is the overall time-weighted average of the values, computed via a trapezoid rule.  That is, if C<tm=0, value=2> and C<tm=10, value=12>, the average is 7 with a weight of 10.  See L</Logging> for more details.

=head2 Boolean attributes

The C<bool> type must be declared.  The default initial value is zero/false.

Boolean attributes may change with any of:  C<set>.  Currently there is no restriction on values, but the behavior is only defined for values 0/1.

The reported C<avg> is the percentage of time in the schedule for which the flag was true.  That is, if C<tm=0, value=0>, and C<tm=7, value=1>, and C<tm=10, value=1> is the complete schedule, then the reported average for the boolean will be C<0.3>.

=head1 RESPONSE

Each named attribute in a scheduling configuration uses the C<report> function, described below, to build an attribute report that includes:

  y  =>(final value)
  xy =>[[tm,value,average],...]
  avg=>(average, depends on type)

The C<y> value is the last recorded value.  The C<xy> contains an array of all values, averages, and the times at which they changed.  The C<avg> is roughly the time-weighted average of the value, but this depends on the attribute type.

=head2 Logging

The reported C<xy> is an array of values of the form C<(tm, value, average)>, with each timestamped entry indicating that a scheduling activity, action, or message, included an attribute change configuration.  Each attribute has an initial entry of C<(0, value)>, either the default or the value specified in the declaration.  Note that the starting time may be a value other than zero.

Any attribute may be "fixed" in the log at its current value by passing the change as C<{}>, which is equivalent to C<incr=0> for integers.  (Internally this may also be invoked with C<_log=1>, but this is subject to change.)

=head1 FUNCTIONS

The C<Attribute> object provides the following functions.

=head2 change

Ideally called as C<$attr->change(tm=>tm,options)>, this updates the value of the attribute and logs at the given timestamp.  Change options must be type-appropriate.  The specified time must exceed (or be the same as) the maximum logged time for the attribute to have any effect.  That is, historical requests are a no-op:  They don't update the current value, nor do they create an entry in the log.

Called without a timestamp, the maximum time will be assumed, the value changed, and the logged entry overwritten.

Historic entry is proposed by not yet defined, since it must support C<set> and C<incr> options and handle updates to the rolling average.

=head2 value

The value of the attribute associated with the logged event having the maximum time.

=head2 average

Computes the type-specific time-weighted "average value" over all entries in the log.  Averages are maintained for integers and booleans on the fly, so they can be referenced at any time without performance impact.

=head2 report

Returns a hash of

  y    the value
  xy   this list of logged (time,value)
  avg  the time-weighted average

=head2 C<_xy>

An internal helper to build the list of values from the log.

=head2 validateConfig

Returns errors if any of the keys in an attribute configuration are unavailable for the type.  By default, the type is 'int'.

=head2 log

Called with a timestamp as C<$attr->log(tm)> to create a log entry of the current value.  This is public so callers can establish a "checkpoint" where the value is known/unchanged, typically at boundaries of events or scheduling windows.

Does nothing if the indicated time is below the maximum logged time.  Historic entry is proposed by not defined (see 'change' above).

=head2 dump

Return a hash of values that can be used to restore the state of the attribute.

=head2 restore

Called either as a static function or C<$attr->restore(%copy)>, loads the state of the attribute from the given hash.

=cut
