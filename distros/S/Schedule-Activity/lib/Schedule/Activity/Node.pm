package Schedule::Activity::Node;

use strict;
use warnings;
use List::Util qw/any/;
use Scalar::Util qw/looks_like_number/;

our $VERSION='0.1.1';

my %property=map {$_=>undef} qw/tmmin tmavg tmmax next finish message attribute note attributes/;

my %defaults=(
	'tmmax/tmavg'=>5/4,
	'tmavg/tmmin'=>4/3,
	'tmmax/tmmin'=>5/3,
);

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	return bless(\%opt,$class);
}

sub defaulting {
	my ($node)=@_;
	my $mult=sub { my ($x,$y)=@_; if(defined($y)) { return $x*$y } return };
	my @lln=map {looks_like_number($$node{$_})} qw/tmmin tmavg tmmax/;
	if(any {!$_} @lln) {
		if($lln[1]) {
			$$node{tmmax}//=$$node{tmavg}*$defaults{'tmmax/tmavg'};
			$$node{tmmin}//=$$node{tmavg}/$defaults{'tmavg/tmmin'};
		}
		elsif($lln[0]&&$lln[2]) {
			$$node{tmavg}=0.5*($$node{tmmin}+$$node{tmmax})
		}
		elsif($lln[0]) {
			$$node{tmmax}//=$$node{tmmin}*$defaults{'tmmax/tmmin'};
			$$node{tmavg}//=$$node{tmmin}*$defaults{'tmavg/tmmin'};
		}
		elsif($lln[2]) {
			$$node{tmavg}//=$$node{tmmax}/$defaults{'tmmax/tmavg'};
			$$node{tmmin}//=$$node{tmmax}/$defaults{'tmmax/tmmin'};
		}
	}
}

sub validate {
	my (%node)=@_;
	if($node{_valid}) { return }
	my (@errors,@invalids,@tmseq);
	foreach my $k (grep {!exists($property{$_})} keys(%node)) { push @errors,"Invalid key:  $k" }
	foreach my $k (map {"tm$_"} qw/min avg max/) {
		if(defined($node{$k})) {
			if   (!looks_like_number($node{$k})) { push @errors,"Invalid value:  $k" }
			elsif($node{$k}<0)                   { push @errors,"Negative value:  $k" }
			else                                 { push @tmseq,$node{$k} }
		}
		else { push @invalids,$k }
	}
	@invalids=sort(@invalids);
	if(@invalids&&($#invalids!=2)) { push @errors,"Incomplete time specification missing:  ".join(' ',@invalids) }
	if($#tmseq==2) {
		if($tmseq[0]>$tmseq[1]) { push @errors,"Invalid:  tmmin>tmavg" }
		if($tmseq[1]>$tmseq[2]) { push @errors,"Invalid:  tmavg>tmmax" }
	}
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
