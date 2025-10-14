package Schedule::Activity::Attribute;

use strict;
use warnings;

our $VERSION='0.1.3';

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
	my %self=(
		type =>$opt{type}//'int',
		value=>$opt{value}//0,
		log  =>{},
	);
	if(!defined($types{$self{type}})) { die "Attribute invalid type:  $self{type}" }
	$self{log}{$opt{tm}//0}=$self{value};
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
	if(defined($tm)) { $$self{log}{$tm}=$$self{value} }
	return $self;
}

sub change {
	my ($self,@opt)=@_;
	return &{$types{$$self{type}}{change}}($self,@opt);
}

sub report {
	my ($self)=@_;
	return (
		y  =>$$self{value},
		xy =>[$self->xy()],
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
	return &{$types{$$self{type}}{average}}($$self{log});
}

sub xy {
	my ($self)=@_;
	return map {[$_,$$self{log}{$_}]} sort {$a<=>$b} keys %{$$self{log}};
}

# set=>value
# incr=>value
# decr=>value
# tm=>tm # optional, will create a log entry
sub _changeInt {
	my ($self,%opt)=@_;
	if(defined($opt{set})) { $$self{value}=$opt{set} }
	if($opt{incr})         { $$self{value}+=$opt{incr} }
	if($opt{decr})         { $$self{value}-=$opt{decr} }
	if(defined($opt{tm}))  { $self->log($opt{tm}) }
	return $self;
}

# set=>value
# tm=>tm # optional, will create a log entry
sub _changeBool {
	my ($self,%opt)=@_;
	if(defined($opt{set})) { $$self{value}=$opt{set} }
	if(defined($opt{tm}))  { $self->log($opt{tm}) }
	return $self;
}

sub _avgInt {
	my ($log)=@_;
	my ($avg,$weight,$lasttm,$lasty)=(0,0);
	foreach my $tm (sort {$a<=>$b} keys(%$log)) {
		if(!defined($lasttm)) { ($lasttm,$lasty)=($tm,$$log{$tm}); next }
		my $dt=$tm-$lasttm;
		$avg=$weight/($weight+$dt)*$avg+0.5*$dt/($weight+$dt)*($lasty+$$log{$tm});
		$weight+=$dt;
		$lasttm=$tm;
		$lasty=$$log{$tm};
	}
	return $avg;
}

sub _avgBool {
	my ($log)=@_;
	my ($sum,$weight,$lasttm,$lasty)=(0,0);
	foreach my $tm (sort {$a<=>$b} keys(%$log)) {
		if(!defined($lasttm)) { ($lasttm,$lasty)=($tm,$$log{$tm}); next }
		my $dt=$tm-$lasttm;
		$sum+=$lasty*($tm-$lasttm);
		$weight+=$dt;
		$lasttm=$tm;
		$lasty=$$log{$tm};
	}
	return $sum/$weight;
}

1;

__END__

=pod

This module is responsible for individual attributes.  It tracks values for the attribute, facilitates updates, and handles reporting.

Note that attributes are intended to be I<typed>, so, for example, during the configuration phase, if there is a request for C<name=boolean> and for C<name=integer>, there should be a failure.

=cut
