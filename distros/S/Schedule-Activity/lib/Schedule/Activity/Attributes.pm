package Schedule::Activity::Attributes;

use strict;
use warnings;
use Schedule::Activity::Attribute;

our $VERSION='0.1.8';

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		attr =>{},
		stack=>[],
	);
	return bless(\%self,$class);
}

sub register {
	my ($self,$attribute,%opt)=@_;
	my @errors;
	if(defined($$self{attr}{$attribute})) {
		if($opt{type}&&($$self{attr}{$attribute}{type} ne $opt{type})) {
			push @errors,"Attribute conflicting types:  $attribute" } }
	else {
		eval { $$self{attr}{$attribute}=Schedule::Activity::Attribute->new(%opt); };
		if($@) { push @errors,$@ }
	}
	push @errors,$$self{attr}{$attribute}->validateConfig(%opt);
	return @errors;
}

# sub get { my ($self,$attribute)=@_; ... } # not yet needed

sub log {
	my ($self,$tm)=@_;
	if(!defined($tm)) { return $self }
	foreach my $A (values %{$$self{attr}}) { $A->change(tm=>$tm,_log=>1) }
	return $self;
}

sub change {
	my ($self,$attribute,%opt)=@_;
	my $A=$$self{attr}{$attribute};
	if(!$A) { return }
	$A->change(%opt);
	return $self;
}

sub report {
	my ($self)=@_;
	my %res;
	while(my ($k,$v)=each %{$$self{attr}}) { %{$res{$k}}=$v->report() }
	return %res;
}

sub push {
	my ($self)=@_;
	my %state;
	while(my ($k,$v)=each %{$$self{attr}}) { %{$state{$k}}=$v->dump() }
	push @{$$self{stack}},\%state;
	return $self;
}

sub pop {
	my ($self)=@_;
	if(!@{$$self{stack}}) { return $self }
	my %state=%{pop @{$$self{stack}}};
	%{$$self{attr}}=();
	while(my ($k,$v)=each %state) { $$self{attr}{$k}=Schedule::Activity::Attribute->restore(%$v) }
	return $self;
}

1;

__END__

=pod

This module is the primary class to track and manage I<all> attributes during schedule configuration and building.  It handles collection of information during the build phase, creation of any specific attribute objects that will be used during schedule building, and (eventual) reporting of attribute statitics.  Not currently clear what responsibilities this module will have related to filtering.

=cut
