package Schedule::Activity::Node;

use strict;
use warnings;
use List::Util qw/any/;
use Scalar::Util qw/looks_like_number/;

my %property=map {$_=>undef} qw/tmmin tmavg tmmax next finish message attribute note/;

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	return bless(\%opt,$class);
}

sub validate {
	my (%node)=@_;
	if($node{_valid}) { return }
	my (@errors,@invalids);
	foreach my $k (grep {!exists($property{$_})} keys(%node)) { push @errors,"Invalid key:  $k" }
	foreach my $k (map {"tm$_"} qw/min avg max/) {
		if(defined($node{$k})) {
			if   (!looks_like_number($node{$k})) { push @errors,"Invalid value:  $k" }
			elsif($node{$k}<0)                   { push @errors,"Negative value:  $k" }
		}
		else { push @invalids,$k }
	}
	@invalids=sort(@invalids);
	if(@invalids&&($#invalids!=2)) { push @errors,"Incomplete time specification missing:  ".join(' ',@invalids) }
	if(exists($node{next})) {
		if(ref($node{next}) ne 'ARRAY') { push @errors,'Expected array:  next' }
		else {
			@invalids=grep {!defined($_)||ref($_)} @{$node{next}//[]};
			if(@invalids) { push @errors,'Undefined name in array:  next' }
		}
	}
	if(exists($node{finish})) {
		if(!defined($node{finish})||ref($node{finish})) { push @errors,'Expected name:  finish' }
	}
	if(!@errors) { $node{_valid}=1 }
	return @errors;
}

sub slack  { my ($self)=@_; return ($$self{tmavg}//0)-($$self{tmmin}//$$self{tmavg}//0) }
sub buffer { my ($self)=@_; return ($$self{tmmax}//$$self{tmavg}//0)-($$self{tmavg}//0) }

sub increment {
	my ($self,$tm,$slack,$buffer)=@_;
	if(ref($tm))     { $$tm    +=$$self{tmavg}//0 }
	if(ref($slack))  { $$slack +=$self->slack()   }
	if(ref($buffer)) { $$buffer+=$self->buffer()  }
	return $self;
}

sub nextrandom {
	my ($self,%opt)=@_;
	if(!$$self{next}) { return }
	my $N=1+$#{$$self{next}};
	if($N<=0) { return }
	if($N==1) { return $$self{next}[0] }
	my $node=$$self{next}[ int(rand($N)) ];
	if($opt{not}) { while($node eq $opt{not}) { $node=$$self{next}[ int(rand($N)) ] } }
	return $node;
}

sub hasnext {
	my ($self,$node)=@_;
	if(!$$self{next}) { return }
	return (any {$_ eq $node} @{$$self{next}});
}

1;
