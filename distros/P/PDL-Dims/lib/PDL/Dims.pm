#!/usr/bin/perl

package PDL::Dims;


=head1 NAME

PDL::Dims - Enhancement to PDL by using named dimensions. 

If PDL is about arrays, PDL::Dims turns them into hashes

=cut

our $VERSION = '0.013';

use strict;


use parent 'Exporter','PDL';
#use base 'PDL';
#@PDL::Dims::ISA=qw/PDL Exporter/;
use Scalar::Util  qw/looks_like_number/;
use PDL::NiceSlice;
use Storable qw(dclone);
use PDL; 
#use PDL::Lite;
#use PDL::Ufunc qw(min max);
#use PDL::Core qw(approx sclr);
#no PDL::IO::Pic;
use 5.012;
our @EXPORT=qw(diminfo dnumeric vals spacing is_sane i2pos pos2i initdim idx didx dimsize dimname sln rmdim nagg dinc dmin dmax nreduce nop ncop copy_dim  active_slice nsqueeze);


my @keys = qw(pos size num spacing unit min max inc vals index dummy);

sub _fix_old { # This fixes data stored from version <=0.002
	my $self=shift;
	for my $d (@{dimname($self)}) {
		for my $p (keys %{$self->hdr->{$d}}) {
			if ((my $n=$p) =~s/^dim//) {
				#say "$p -> $n ", $self->hdr->{$d}->{$p};
				$self->hdr->{$d}->{$n}=$self->hdr->{$d}->{$p};
				#say "$p -> $n ", $self->hdr->{$d}->{$n};
				delete $self->hdr->{$d}->{$p};
				#say "$p -> $n ", $self->hdr->{$d}->{$n};
			}
		}
		dnumeric($self,$d,1) unless ($d eq 'channel');
		dimsize($self,$d,$self->dim(didx($self,$d)));
		#say "$d size: ",dimsize($self,$d),' ',dmin($self,$d),' min; max: ',dmax($self,$d);
		#say "spacing ",spacing($self,$d);
		spacing($self,$d,1) if ($d eq qw/x y z t/);
		if ($d eq 'channel') {
			#say "Channel";
			#say dimsize($self,$d);
			spacing($self,$d,0);
			dnumeric($self,$d,0);
		}
		if  ($d eq 'channel' and dimsize($self,$d)==1) {
			vals($self,$d,['combined',]);
			#say "channel: ",@{vals($self,$d)};
		}
		if  (!dimsize($self,$d)) {
			#say "$d has size 1!";
			dmax($self,$d,dmin($self,$d));
			dinc($self,$d,0);
		}
		if (spacing($self,$d) and $d ne 't') {
			dinc($self,$d,(dmax($self,$d)-dmin($self,$d))/((dimsize($self,$d)-1)||1)) ;
		}
		if ($d eq 't') {
			#say "t: inc ",dinc($self,$d);
			dmax($self,$d,dmin($self,$d)+(dimsize($self,$d)-1)*dinc($self,$d)); 
		}
		#say "$d size: ",dimsize($self,$d),' ',dmin($self,$d),' min; inc: ',dinc($self,$d),' inc - max ',dmax($self,$d);
	}
}
# returns a list of all dims for one parameter -- intended as an auxillary for internal use only

sub _dimpar {
	my $self=shift;
	my $p=shift; # par
	#say "All of ".%{$self->hdr}.", $p";
	return unless $p;
	my @s;
	for my $i (@{dimname($self)}) {
		#say "name $i $p";
		#next unless chomp $i;
		#say "name $i: ",$self->hdr->{$i}->{$p};
		barf ("Unknown dim $i") unless (ref ($self->hdr->{$i}) eq  'HASH');
		push @s,$self->hdr->{$i}->{$p};
	}
	#say "Dims ".@{dimname($self)}."Par $p: @s";
	return @s;
}

sub dnumeric {
	my $self=shift;
	my $d=shift;
	my $v=shift;
	return [_dimpar($self,'num')] if (!$d and wantarray);
	return [_dimpar($self,'num')] unless ($d);
	return undef  unless (ref ($self->hdr->{$d}) eq  'HASH');
	#warn "numeric? $d $v.", $self->hdr->{num} ;#if ($d eq 'a' and $v==1);
	#barf "numeric? $d $v!", $self->hdr->{num} if ($d eq 'a' and $v==1);
	if (defined $v) {
		#warn "numeric value? $d $v.", $self->hdr->{num} ;#if ($d eq 'a' and $v==1);
		$self->hdr->{$d}->{num}=$v;
	}
	if ($self->hdr->{$d}->{num}) {
		#warn "numeric: $d $v" if ($v and $d eq 'a');
		#barf "Channel is not numeric ! " if ($d eq 'channel');
	#	for (vals($self,$d)) {looks_like_number $_ || barf "$d has non-numeric values";}
	}
	return $self->hdr->{$d}->{num};
}

sub spacing {
	my $self=shift;
	my $d=shift; # dimname
	my $v=shift; # value
	return [_dimpar($self,'spacing')] if (!$d and wantarray);
	return [_dimpar($self,'spacing')] unless ($d) ;
	return undef  unless (ref ($self->hdr->{$d}) eq  'HASH');
	if (defined $v) {
		int $v;
		$self->hdr->{$d}->{spacing}=$v; 
	}
	return $self->hdr->{$d}->{spacing}; #, $r{$d};
}

sub diminfo {
	my $self=shift;
	my $str;
	for my $n (dimname ($self)) {
		$str.="$n\[".didx($self,$n)."]=>".dimsize($self,$n).", ";
	}
	$str.=$self->info;
	return $str;
}
sub is_sane {
	my $self=shift;
	return "piddle" unless $self->isa('PDL');
	return "name" unless dimname($self);
	return "ndims" unless ($self->ndims==1+$#{dimname($self)});
	#say "global done.";
	for my $n (@{dimname($self)}) {
		next unless (chomp $n);
	#	say "Checking dim $n for $self->hdr->{self}";
		return "size ".$n unless ($self->dim(didx($self,$n))==dimsize($self,$n));
		return "index " .$n unless (idx($self,$n)<dimsize($self,$n));
		return "index " .$n unless (idx($self,$n)>=0);
	#	say "size and index";
		if (spacing($self,$n)) {
	#		say "inc";
			return "inc ".$n unless dinc($self,$n);
	#		say dmax($self,$n), dmin($self,$n)+dinc($self,$n)*(dimsize($self,$n)-1);
	#		say "minmax $n";
			return "minmax ".$n unless (approx(dmax($self,$n)),
				dmin($self,$n)+dinc($self,$n)*(dimsize($self,$n)-1));
	#		say "pos: $n";
	#		say (dmax($self,$n),i2pos($self,$n,pos2i($self,$n,dmax($self,$n))));
	#		say "Index: ",(pos2i($self,$n,dmax($self,$n)));
	#		say "Numeric: $n" unless (dnumeric( $self,$n));
			return "pos ".$n unless (approx(dmax($self,$n),i2pos($self,$n,pos2i($self,$n,dmax($self,$n)))));
		} else {
	#		say "vals $n";
			return "vals ".$n unless (dimsize($self,$n)==$#{vals($self,$n)}+1);
	#		say "val_pos $n";
	#		say "Numeric: $n" unless (eval {dnumeric( $self,$n)});
			#say i2pos($self,$n,dimsize($self,$n)-1);
			#say pos2i($self,$n,i2pos($self,$n,dimsize($self,$n)-1))," 1";
			#say (dimsize($self,$n) , 1+
				#pos2i($self,$n,i2pos($self,$n,dimsize($self,$n)-1)));
			return "pos ".$n unless (dimsize($self,$n)-1 == @{
				pos2i($self,$n,i2pos($self,$n,dimsize($self,$n)-1))}-[-1]);
		}
	}
	return 0;
}
sub dimsize { # sets size for a dim
	my $self=shift;
	my $d=shift; # dimname
	my $v=shift; # value
	#say "return all ", _dimpar($self,'size') if (!$d and wantarray);
	return _dimpar($self,'size') if (!$d and wantarray);
	return #([values %{$self->hdr->{dimsize}}]
#		,[keys %{$self->hdr->{dimsize}}],
		#)
		[_dimpar($self,'size')]
	unless ($d) ;
	#barf ("Unknown dim $d") unless (ref ($self->hdr->{$d}) eq  'HASH');
	return undef unless (ref ($self->hdr->{$d}) eq  'HASH');
	#say "size $d $v",$self->info;
	if (defined $v) {
		return undef  unless (ref ($self->hdr->{$d}) eq  'HASH');
		int $v;
		$self->hdr->{$d}->{size}=$v; 
		idx($self,$d,$v-1) if (idx($self,$d)>=$v-1);
	}
	return $self->hdr->{$d}->{size}; #, $r{$d};
}# get/set name of a dim by number

sub dimname {
	my $self=shift;
	my $d=shift; # dim number
	my $n=shift; # new name
	barf "Not a piddle!" unless $self->isa('PDL');
	#say keys %{$self->hdr} unless defined $d;
	return @{$self->hdr->{dimnames}} if (! defined ($d) and wantarray);
	return $self->hdr->{dimnames} unless defined $d;
	#barf "Unknown dim $d" unless (ref $self->hdr->{dimnames} eq  'HASH');
	$self->hdr->{dimnames}->[$d]=$n if $n;
	return $self->hdr->{dimnames}->[$d];
}

sub dinc {
	my $self=shift;
	my $d=shift; # dimname
	my $v=shift; # max 
	return _dimpar($self,'inc') if (!$d and wantarray);
	return [_dimpar($self,'inc')] unless $d;
	if (defined $v) {
		#say "dinc: $d $v";
		return undef  unless (ref $self->hdr->{$d} eq  'HASH');
		$self->hdr->{$d}->{inc}=$v; 
		spacing ($self,$d,1);
		dnumeric ($self,$d,1);
		$self->hdr->{$d}->{vals}=undef; #
	}
	return $self->hdr->{$d}->{inc}; #, $r{$d};
}

sub dmax {
	my $self=shift;
	my $d=shift; # dimname
	my $v=shift; # max 
	return _dimpar($self,'max') if (!$d and wantarray);
	return [_dimpar($self,'max')] unless $d;
	#say "$d ".$self->hdr;
	return undef  if (defined $v and ref $self->hdr->{$d} ne  'HASH');
	$self->hdr->{$d}->{max}=$v if defined ($v);
	return $self->hdr->{$d}->{max}; #, $r{$d};
}

sub dmin {
	my $self=shift;
	my $d=shift; # dimname
	my $v=shift; # min 
	return _dimpar($self,'min') if (!$d and wantarray);
	return [_dimpar($self,'min')] unless $d;
	return undef  if (defined $v and ref $self->hdr->{$d} ne  'HASH');
	#barf "Unknown dim $d" unless (ref $self->hdr->{$d} eq  'HASH');
	$self->hdr->{$d}->{min}=$v if defined ($v);
	return $self->hdr->{$d}->{min}; #, $r{$d};
}


sub didx { # set/get index - complementary to dimname
	my $self=shift;
	my $d=shift; # dimname
	return _dimpar($self,'pos') if (!$d and wantarray);
	return [_dimpar($self,'pos')] unless $d;
	if (ref $d eq 'ARRAY') {
		@$d;
	} else {
		my $n=shift; # new position
		return if (ref $self->hdr->{$d} ne  'HASH');
		barf "Unknown dim $d" unless (ref $self->hdr->{$d} eq  'HASH');
		$self->hdr->{$d}->{pos}=$n if defined $n;
		#say "type $self idx $d ".$self->hdr->{$d}->{pos};
		return $self->hdr->{$d}->{pos};
	}
}

sub initdim {
	my $self=shift;
	my $d=shift || return ; # name
	#say "Init dim $d ...";
	$self->hdr; #ensure the header is intialised.
	my %p=@_;
	for my $k (keys %p) {
		barf "Unkown parameter $k $p{$k}" unless ($k ~~ @keys);
	}
	#say "header: ",(keys %{$self->gethdr},);
	if (ref $self->hdr->{$d} eq  'HASH'){ # dimname exists and is a hash
		my $n= didx($self,$d);
		if (defined $n) {
			$p{pos}=$n; #just to make sure
			barf "$d exists at pos $n! (".%{$self->hdr->{$d}}."\n";
		} else {	
			#say (keys (%{$self->hdr->{$d}}),'-keys');
			warn "$d is defined but not a dim! ",%{$self->hdr->{$d}};
		}
	} else { 
		$self->hdr->{ndims}=0 unless ($self->hdr->{ndims});
		#say keys $self->hdr->{$d};
		#say "pars: ",%p;
		$self->hdr->{$d}=\%p;
		#say "Creating dim $d at pos. $p{pos}; Ndims ".$self->hdr->{ndims};
		if ((!defined $p{pos}) or ($p{pos}>$self->hdr->{ndims})) {
			$p{pos}=$self->hdr->{ndims};
		}
		if ($p{pos}<$self->hdr->{ndims}) {
			for (my $i=$self->hdr->{ndims}-1;$i>=$p{pos};$i--) {
				#say dimname($self,$i)," initdim at pos $p{pos} ndims: ",$self->hdr->{ndims}, " $i";
				dimname($self,$i+1,dimname($self,$i-0)); # shift the position up!
				didx($self,dimname($self,$i),$i+1);
			}		
		}
		didx ($self,$d,$p{pos});
		$self->hdr->{$d}=\%p;
		dimname ($self,$p{pos},$d);
	}
	$p{size}=$self->dim($p{pos}) unless ($p{size});
	warn "initdim, dim $d: Size ($p{size}) does not mnatch piddle dim at pos $p{pos} ",$self->dim($p{pos}) 
		unless ($p{size}==$self->dim($p{pos}));  
	dimsize ($self,$d,($p{size}||1));
	spacing($self,$d,1) unless defined spacing($self,$d);
	#say "P: ",%p;
	#say "Dim $d: ",ref $p{vals},"; ",%p;
	#say "Dim $d: ",@{$p{vals}} if (ref $p{vals}); #,"; ",@{$p{vals}};
		#say "Set values $d",ref($p{vals});
	if (ref ($p{vals}) eq 'ARRAY') {# or (dimsize($self,$d) == 1 and defined $p{val})) {# and !spacing($self,$d)) {
		#say "Set values $d";
		my @v=@{$p{vals}};
		#say "Values: @v";
		#barf "Wrong size of values list! $d " unless ($#{$p{vals}}==dimsize($self,$d)-1);
		vals ($self,$d,$p{vals}); 
		#warn "numeric $d" ,dnumeric($self,$d);#,($p{num}||1));
		#dmin($self,$d,vals($self,$d,0));
		#dmax($self,$d,vals($self,$d,dimsize($self,$d)));
	}
	unless (spacing($self,$d)){
		#barf "$d !";
	} else {
		#say "equal spaced, numeric values $d";
		$p{num}=1 unless defined $p{num};
		if ($p{inc} and $p{max}) {
			barf ("Increment and maximum don't fit! ($d min $p{min} max $p{max} inc $p{inc} "
				.dimsize($self,$d))
				unless (approx(pdl ($p{max}-$p{min}) , pdl((dimsize($self,$d)-1)*$p{inc} )));
		} elsif ($p{inc}) {
			$p{max}=$p{inc}*(dimsize($self,$d)-1)+$p{min};
		} elsif ($p{max}) {
			$p{inc}=($p{max}-$p{min})/((dimsize($self,$d)-1)||1);
		} else {
			$p{max}=dimsize($self,$d)-1;
			$p{inc}=1;
		}
		dmin ($self,$d,$p{min}||0);
		dinc ($self,$d,$p{inc});
		dmax ($self,$d,$p{max}); #||(dimsize($self,$d)-1)*$p{inc};
		spacing($self,$d,1);
		dnumeric($self,$d,);
	}
	$self->hdr->{ndims}++; 
	#say "initdim: ndims ",$self->hdr->{ndims} , diminfo $self;
	idx($self,$d,($p{index}||0));#dmin($self,$d)));
	my $res=$self;
	if ($p{dummy} ) { # insert dummy dimension of size size at pos.
		#say "dummy: $p{pos} $p{size}";
		$res=$res->dummy($p{pos},$p{size});
	}
	$res->sethdr($self->hdr_copy);
	#say diminfo ($res);
	return $res;
	#say "Done. ($d)";
}

sub copy_dim {
	my $old=shift;
	my $new=shift;
	my $dim=shift;
	unless (exists $old->hdr->{$dim}) {
		my $err=is_sane($new);
		warn "copy_dims: inconsistent dims (input), $err ! ",diminfo $old if ($err);
		for my $dim (dimname($old),){ 
			my $d=dclone($old->hdr->{$dim});
			initdim($new,$dim,%$d);
		}
		$err=is_sane($new);
		warn "copy_dims: inconsistent dims (new), $err ! ",diminfo $new if ($err);
	} else {
		my $d=dclone($old->hdr->{$dim});
		$$d{pos}=shift;
		initdim($new,$dim,%$d);
	}
}

sub rmdim {
	my $self=shift;
	my $d=shift;
	return unless defined $d;
	#say "removing $d ".didx($self,$d);;
	my $idx=didx($self,$d);
	#say @{$self->hdr->{dimnames}},didx($self,$d); # cut out the array
	splice @{$self->hdr->{dimnames}},$idx,1; # cut out the array
	#say @{$self->hdr->{dimnames}},didx($self,$d); # cut out the array
	for my $i ($idx..$self->hdr->{ndims}-1) { 
		didx($self,dimname($self,$i),$i);	#update position of following dims
	}
	delete $self->hdr->{$d};
	barf "This should be undefined! ",$self->hdr->{$d} if defined ($self->hdr->{$d});
	#barf "This should be undefined! ",$self->hdr->{dimnamesd} if defined ($self->hdr->{$d});
	$self->hdr->{ndims}--;
	#say "rmdim: ",diminfo $self;
}

sub unit {
	#my $self=shift;
	my $self=shift;
	die "I don't have data to work on (unit)" unless defined $self->hdr;
	#say "$self type array ";
	my $index=shift;
	return _dimpar($self,'unit') if (! defined ($index) and wantarray);
	return [_dimpar($self,'unit')] unless defined $index;
	#barf ("Unknown dim $index") 
	return undef unless (ref ($self->hdr->{$index}) eq  'HASH');
	if (defined (my $v=shift)) {
		$self->hdr->{$index}->{unit}=$v ;
	}
	return $self->hdr->{$index}->{unit}; 
}

sub idx {
	#my $self=shift;
	my $self=shift;
	barf "I don't have data to work on (idx)" unless defined $self->hdr;
	#say "$self type array ";
	my $index=shift;
	return _dimpar($self,'index') if (! defined ($index) and wantarray);
	return [_dimpar($self,'index')] unless defined $index;
	
	return undef unless (ref ($self->hdr->{$index}) eq  'HASH');
	if (defined (my $v=shift)) {
		$v<0? 0: $v;
		$v>=dimsize($self,$index)? dimsize($self,$index)-1 : $v;
		$self->hdr->{$index}->{index}=int $v ;
	}
	return $self->hdr->{$index}->{index}; 
}

sub vals { #individual values of dims -- like the position along an axis in world coords., echo times
	my $self=shift;
	my $d=shift; #dim
	return unless $d;
	$self->hdr->{$d}->{vals}=[] unless defined $self->hdr->{$d}->{vals};
	#say "Vals: $d ",@{$self->hdr->{$d}->{vals}};
	my $i=shift; #index or array ref
	if (defined $i) { # set the whole array or access individual points
		#say "vals: $d $i";
		if (ref $i eq 'ARRAY' and dimsize($self,$d) == $#{$i}+1) { #ref to values array
			barf "Array size does not match dimsize" unless ($#$i==dimsize($self,$d)-1);
			$self->hdr->{$d}->{vals}=$i ;
			spacing ($self,$d,0); #->hdr->{$d}->{spacing}=0;
			$self->hdr->{$d}->{inc}=undef;
			for (vals($self,$d)) {looks_like_number $_ || dnumeric($self,$d,0);} 

			if (dnumeric($self,$d)){
				barf "not numeric @$i" if ($$i[0] eq 'a');
				dmin($self,$d,min(pdl $i));
				dmax($self,$d,max(pdl $i));
			} else {
				$self->hdr->{$d}->{max}=undef;
				$self->hdr->{$d}->{min}=undef;
			}
			#say "$d: setting vals @$i";
		} else { #individual values 
			my $v=shift; #value
			if ( defined $v) { 
				$self->hdr->{$d}->{vals}->[$i]=$v ;
				spacing ($self,$d,0); #->hdr->{$d}->{spacing}=0;
				$self->hdr->{$d}->{inc}=undef;
				for (vals($self,$d)) {looks_like_number $_ || dnumeric($self,$d,0);} 
				if (dnumeric($self,$d)){
				#barf "not numeric $i" if ($i eq 'a');
					dmin($self,$d,min(pdl $i));
					dmax($self,$d,max(pdl $i));
				} else {
					$self->hdr->{$d}->{max}=undef;
					$self->hdr->{$d}->{min}=undef;
				}
			}
			if (spacing($self,$d)) {
				return dmin($self,$d)+$i*dinc($self,$d);
			}
			return $self->hdr->{$d}->{vals}->[$i];
		}
	#} else {
	}
	if (spacing($self,$d)) {
		return (list (dmin($self,$d)+dinc($self,$d)*sequence(dimsize($self,$d)))) if (wantarray);
		return [list (dmin($self,$d)+dinc($self,$d)*sequence(dimsize($self,$d)))] unless wantarray;
	}
	if (wantarray) {
	return @{$self->hdr->{$d}->{vals}};
	} else {
	return $self->hdr->{$d}->{vals};
	}
}


#transformations between piddle and world coords. 
sub i2pos{
	my $self=shift; # dataset
	my $d=shift || return; # dimname
	my $i=shift ; #value
	barf "Unknown dim $d" unless (ref $self->hdr->{$d} eq  'HASH');
	$i=idx($self,$d) unless (defined $i);
	if (spacing($self,$d)) {
		return $i*dinc($self,$d)+dmin($self,$d); 
	} else {
		return vals($self,$d,$i);
	}
}

sub pos2i{
	my $self=shift;
	(my $d=shift) || return;
	my $i=shift ; # value
	barf "Unknown dim $d" unless (ref $self->hdr->{$d} eq  'HASH');
	if (spacing($self,$d)) {
		my $res=rint (($i-dmin($self,$d))/dinc($self,$d)); 
		$res=dimsize($self,$d)-1 if ($res>=dimsize($self,$d));
		$res=0 if ($res<0);
		return $res;
	} else {
		#say "searching for $i ",$self->hdr->{$d}->{num},".";
		#say "Num? ",dnumeric($self,$d,undef);
		my @a=vals($self,$d);
		#say "Num? ",dnumeric($self,$d,undef);
		#say "searching for $i ",$self->hdr->{$d}->{num},".";
		my (@res)=grep { $a[$_] == $i } (0 .. $#a)if (dnumeric($self,$d));
		my (@res)=grep { $a[$_] eq  $i } (0 .. $#a)unless (dnumeric($self,$d));
		#my (@res)=grep { chomp($a[$_]) eq  chomp('c') } (0 .. $#a)unless (dnumeric($self,$d));

		#say "pos2i: returning @res";
		if (wantarray) {
			return @res ;
		} else {
			return $res[0];
		}
	}
}

sub nsqueeze :lvalue {
	my $self=shift;
	#my @except=@_;
	#say $ret->info;
	#ay $ret->info;
#	my $d=shift;
	my $ret;
#	if (defined didx($slf,$d) {
#		barf "size of $d is >1" if (dimsize($sslf,$d)-1);
#		$ret=sln($ret,$d=>'(0)',);
#	}
	$ret=$self->squeeze;
	$ret->sethdr($self->hdr_copy);
	for my $i (@{dimname($self)}) {
		#say "keeping $i ".dimsize($self,$i) unless (dimsize($self,$i)==1);
		#say "Removing $i ".dimsize($self,$i) if (dimsize($self,$i)==1);
		rmdim($ret,$i)  if (dimsize($self,$i)==1);
	}
	#say "names: ",@{dimname($ret)};
	#say "nsqueeze: return ",$ret->info, @{dimname($ret)};
	return $ret;
}

sub nagg { # aggregate function
	#no PDL::NiceSlice;
	my $self=shift;
	barf "nagg: not a piddle!" unless $self->isa('PDL');
	my $op=shift; # 
	my $d=shift; # dimension
	#say "nagg: ",dimname($self);
	return unless (defined didx($self,$d));
	my $res=$self->mv(didx($self,$d),0);
	#say $res->info;
	if (eval {$res->can($op)}) {
		$res=$res->$op(@_);
	} else { 
		$res=&$op($res,@_);
	}
	barf "nagg: Result undefined for $op on $d." unless defined $res;
	if (eval {$res->nelem}  ) {
		barf "not an aggregate function! $op", $self->info,$res->info if ($self->ndims==$res->ndims);
		#if ($res->nelem==$self->nelem-1)
		if ($res->ndims==$self->ndims-1)
		{
			$res->sethdr($self->hdr_copy);
	#		say "nagg: $d ",dimname($self);
			rmdim ($res,$d);
	#		say "nagg: $d ",dimname($res);
		}
	}
	#say "nagg: ",diminfo($res);
	return ($res); 
}
# boundaries of dims in appropriate units (mm, s, ..)

sub active_slice :lvalue { # 
	my $self=shift;
	my @except=@_;
	my @idx=list (rint(pdl idx($self)));
	#say "j  ".idx($img{$type});
	my @n=(dimname($self));
	barf "active_slice: not consistent size $#n ",$self->ndims-1 unless ($#n==$self->ndims-1);
	#say "self: @n";
	my $str;
	my @rm;
	for my $i (0.. $#n) {
		unless (/$n[$i]/ ~~ @except){
			#say "Selecting $i $n[$i] $idx[$i]";
			push @rm,$n[$i];
			$str.="$idx[$i]"; 
		}
		$str.=',' unless ($i==$#n);
	}
	#say "$str ",$self->info;
	my $ret=$self->slice($str); #->nsqueeze;	
	$ret+=0;
	$ret->sethdr($self->hdr_copy);
	#say $ret->info;
	for my $i (0.. $#n) {
		unless (/$n[$i]/ ~~ @except){
			#say "$i $n[$i] ",idx($self,$n[$i]);
			dimsize($ret,'channel',1);
			#say "$i $n[$i] ",idx($self,$n[$i]);
			dimsize($ret,$n[$i],1);
			my $id=idx($ret,$n[$i]);
			idx($ret,$n[$i],0);
			vals($ret,$n[$i],0,vals($self,$n[$i],$id));
			#dmin($ret,$n[$i],vals($self,$n[$i],$id));
			#dmax($ret,$n[$i],vals($self,$n[$i],$id));
		}
	}
	#say "active_slice: ",$self->info," return ",@{dimname($ret)},$ret->info;
	$ret;
}

sub nreduce { # analogue to PDL::Reduce, perform operation on named rather than numbered dims
	my $self=shift;
	my $op=shift; # operation - passed on to reduce
	require PDL::Reduce;
	my @list=@_;
	my @d=map {didx($self,$_)} @list;
	#say "reduce $op @d (@list)";
	my $ret;
	$ret= $self->reduce($op,@d);
	$ret->sethdr($self->hdr_copy);
	for my $d (@list) {
	#	say "removing $d";
		rmdim ($ret,$d);
	}
	#say "nreduce: ",$ret->info, @{dimname($ret)};
	return $ret;
}

sub nop { # wrapper to functions like sin, exp, rotate operating on one named dimension
	my $self=shift;
	my $op=shift;
	my $dim=shift;
	my @a=@_;
	my $res=pdl $self;
	if ($self->isa('PDL')) {
		my @n=@{dimname($self)};
	#say "nop: (self) @n";
	#say "nop: ",diminfo $self;
	#my $arg=shift; # suitably shaped second argument 
	#say $self;
	#say "dim $dim, pos ",didx($self,$dim)," ",%{$self->hdr->{$dim}};

		$dim=dimname($self,0) unless defined $dim; # trivial 
		$res=$res->mv(didx($self,$dim),0);
	}
	if ($op eq 'rotate'){
		my $s=shift;
		#say "schifing $res by $s";
		$res=$res->rotate($s);
		#say "schifing $res by $s";
	} else {
		#say "nop: ",diminfo $self,"op: $op, @a";
		if (eval {$res->can($op)}) {
			$res=$res->$op(@a,);
		} else { 
			$res=&$op($res,@a);
		}
	}
	if ($self->isa('PDL')) {
		$res=$res->mv(0,didx($self,$dim));
		$res->sethdr($self->hdr_copy);
	}
	#say "self $self, op $res, mv ",$res->mv(0,didx($res,$dim));
	#say "nop: return", $self->info,@{dimname($res)},$res->info;
	return ($res);
}

sub ncop { # named combine operation -- +*-/ ... 
	my $self=shift;
	my $other=shift;
	my $op=shift;
	my $res;
	#say "ncop: start self, other, ",$self->info, $other->info;
	unless (eval {$self->isa('PDL')}) { # self is a scalar
		$self=pdl($self);
		if (eval {$self->can($op)}) {
			$res=$self->$op($other,@_);
		} else {
			$res=&$op($self,$other,@_);
		}		
		if (eval {$other->isa('PDL')}) {# both are scalars ?	
			$res->sethdr($other->hdr_copy); 
		#say "ncop: other ",diminfo $other;
			barf "ncop: $op changed dimensions. Use nagg or nreduce for aggregate functions"
				unless ($other->nelem==$res->nelem);
		}
		#say "ncop: res ",diminfo $res;
		return $res;
	}
	unless (eval {$other->isa('PDL')}) { # other is a scalar
		if (eval {$self->can($op)}) {
			$res=$self->$op($other,@_);
		} else {
			$res=&$op($self,$other,@_);
		}
		barf "ncop: $op changed dimensions. Use nagg or nreduce for aggregate functions"
			unless ($self->nelem==$res->nelem);
		$res->sethdr($self->hdr_copy);
		return $res;
	}
	#say $self->info, $other->info;
	my @d=@{dimname($self)};
	my @e=@{dimname($other)};
	#say "self @d other @e";
	my $m=0;
	my @nother=(); # new order in other
	my @nself=(); # new order in self
	my @tself=(); # thread dims
	my @tother=(); 
	my @aself;
	my @aother;
	my @uother; # use other, even though self contains the dim
	my @add;
	my @co=();
	my $i=0;
	my $j=0;
	#say "keys self",keys %{$self->hdr};
	#say "keys other",keys %{$other->hdr};
	for my $ds (@d) { # loop over dims in $self
		my $n=didx($self,$ds);
		#push @aself,$ds;
		if (defined ($m=didx($other,$ds))) { # dim $ds exists also in other
			push @nself,$n;
			push @nother,$m;
			if (dimsize($self,$ds)==1) {
				push @uother,$ds if (dimsize($other,$ds)>1);
			}
	#		say "$ds $m $n";
	#		say "self $ds $m $n i $i";
			push @co,$i+0;
			#say "co sn @co";
			$i++;
		} else {
			push @tself,$n;
	#		say "$ds $m $n i: $i ", ($other->ndims+$i);
			push @co,($other->ndims+$j);
			#say "co st @co";
			$j++;
		}
	}
	for my $ds (@e) { # loop over dims in $other 
		#push @other,$ds;
		my $n=didx($other,$ds);
		if (defined ($m=didx($self,$ds))) { # if present in self, already done
			1;
		} else {
			push @tother,$n;
			push @add,$ds;
			push @co,$i+0;
			#say "co ot @co";
			#say "other $ds $m $n";
			$i++;
		}
	}
	#say "Co: @co";
	# reorder piddles 
	push @aother,@nother if defined ($nother[0]);
	push @aother,@tother if defined ($tother[0]);
	push @aself,@nself if defined ($nself[0]);
	push @aself,@tself if defined ($tself[0]);
	my $ns=$self->reorder(@aself);
	my $no=$other->reorder(@aother);
	#say "keys self",keys %{$self->hdr};
	#say "keys other",keys %{$other->hdr};
	# insert missing dimensions
	for my $n (0..$#tother) { # fill in dummy dims
		$ns=$ns->dummy($#nself+1,1);
	}
	#say "ncop: @aother @aself ",$ns->info,$no->info;
	#say $self->info,$other->info;
	#### perform the operation
	# perform the operation either as method or function
	if (eval {$ns->can($op)}) {
		#unshift  @_,0 if ($op eq "atan2" and $_[0] != 0);
		$res=$ns->$op($no,@_);
	} else{ 
		#unshift  @_,0 if ($op eq "atan2");# and $_[0] != 0);
		$res=&$op($ns,$no,@_) ;
	} #else {
	#	barf "This operation $op is neither a known method or function";
	#say "ncop: ",$ns->info,$res->info;
	#barf "ncop: $op changed dimensions. Use nagg or nreduce for aggregate functions"
		#unless ($ns->nelem==$res->nelem);
	$res=$res->reorder(@co);
	#say "keys res:",keys %{$res->hdr};
	#say %{$res->gethdr},"header.";
	$res->sethdr($self->hdr_copy);
	#say "keys self: ",%{$self->hdr};
	#say "keys other: ",%{$other->hdr};
	#say "keys res: ",%{$res->hdr};
	#say "self: ",$self->hdr->{ndims};
	#say "other ",$other->hdr->{ndims};
	#say "res ",$res->hdr->{ndims};
	#say "self: ",@{dimname($self)};
	#say "other: ",@{dimname($other)};
	#say "res: ",@{dimname($res)};
	#$other->hdr;
	my $i=$self->ndims;
	for my $ds (@uother) {
		my $i=didx($res,$ds);
		rmdim $res,$ds;
		copy_dim($other,$res,$ds,$i);
	}
	for my $ds (0..$#add) {
		#say "copy $add[$ds]",keys %{$res->hdr};
		#initdim($res,$add[$ds]);
		copy_dim($other,$res,$add[$ds],$i);
	#	say @{dimname($res)};
		$i++;
	}
	$res->hdr->{ndims}=$i;
	#say "self",diminfo $res;
	#say @{dimname($res)};
	#say "Co @co";
	#say "ncop: returning ... ".$res->info;
	#my $err=is_sane($res) ;
	#barf "ncop: sanity check failed $err" if $err;
	#say "ncop ",diminfo($res);
	return $res;
}

sub sln  :lvalue { # returns a slice by dimnames and patterns
	my $self=shift;
	my %s=@_; # x=>'0:54:-2', t=>47, ... #
	my $str;
	#say "sln: args @_, ".$self->hdr->{dimnames},%s;
	#say ("dimnames @{$self->dimname}");
	my @n=@{$s{names}||dimname($self)};
	#say "dims @n";
	for my $i (0.. $#n) {
	#	say "$i $n[$i] $s{$n[$i]}";
		$str.=$s{$n[$i]} if defined ($s{$n[$i]});
		$str.=',' unless ($i==$#n);
	}
	#say "sln: slice string $str";
	my $ret=$self->slice($str);
	$ret->sethdr($self->hdr_copy);
	say $ret->info;
	for my $d (@n) {
		$str=$s{$d};
		#say "$d $str";
		next unless defined $str;
		chomp $str;
		if ($str =~/\(\s*\d+\s*\)/) { # e.g. (0) - reduce 
			rmdim ($ret,$d);
			next;
		}
		$str=~m/([+-]?\d+)(:([+-]?\d+)(:([+-]?\d+))?)?/; # regex for a:b:c, a,b,c numbers
		#say "$d: 1 $1 2 $2 3 $3 4 $4 5 $5";
		my $step=int ($5)||1;
		my $size=int abs((($3||$1)-$1)/$step)+1; #
		my $min=int min pdl($1+0,$3+0);
		my $max=int max pdl($1+0,$3+0);
		#say "min $min max $max size $size str $str vals ";
		dimsize($ret,$d,$size);
		if (spacing ($self,$d)) { 
			dinc($ret,$d,$step*dinc($self,$d));
			dmin($ret,$d,dmin($self,$d)+$step*dinc($self,$d)*($min % dimsize($self,$d)));
			dmax($ret,$d,dmin($ret,$d)+$step*dinc($self,$d)*(dimsize($ret,$d)-1));
			#dmax($ret,$d,vals($self,$d,$max % dimsize($self,$d)));
			idx($ret,$d,sclr (pdl(idx($self,$d))->clip(0,dimsize($ret,$d)-1))); 
			#say "sln: idx ($d):",idx($ret,$d);
		} else {
		#say "min $min max $max size $size str $str vals ";
			#say "vals $d: ",vals($self,$d);
			
			if (dnumeric($self,$d)) {
				my $v=pdl([vals($self,$d),])->($str) ;
				vals($ret,$d,[vals($self,$d,[list $v])]);
				idx($ret,$d,sclr (pdl(idx($self,$d))->clip(dmin($ret,$d),dmax($ret,$d)))); 
			} else {
				my $v=sequence(dimsize($self,$d))->($str);
				my @values;
				#say "vals: $d size $size str $str" ,$v->info;
				for my $ix (0.. $v->nelem-1) {
					#say "$ix $v ",$v($ix);
					push @values,vals($self,$d,sclr ($v($ix)));
					#say "$ix $v ",$v($ix);
				}
				vals($ret,$d,[@values]);
				idx($ret,$d,0);
				#say "sln, vals ($d): ", vals($ret,$d);
			}
			#vals($res,$d,list ();

			if (dnumeric($self,$d)) {
				#dmin($ret,$d,min($v));
				#dmax($ret,$d,min($v));
			}
		}
		#dimsize($ret, $n,
	}
	#say "sln: return ",diminfo($ret);
	$ret;

}

1;
#BEGIN {
#        if ($_[0] eq q/-d/) { 
#		require Carp; 
#		$SIG{__DIE__} = sub {print Carp::longmess(@_); die;}; 
#	} 
#}


=head1 SYNOPSIS

If PDL is about arrays, PDL::Dims makes them into hashes. 

What it provides is a framework for addressing data not by numbered indices in 
numbered dimensions but by meaningful names and values. 

In PDL::Dims the user does not need to know the internal structure, i.e. order of
dimensions. It renders calls to functions like mv, reshape, reorder, ... unnecessary.

    use PDL::Dims;
	
	my $data= .... # some way to load data
	print $data->Info;
	#	PDL: Double D [256,256,20,8,30]
	# Now name the first dim x, running from -12 to 12 cm
	initdim ($data, 'x',unit=>'cm',dmin=>-12,dmax=>12); 
	initdim ($data,'y',pos=>1,size=>256, # these are not necessary but you can set them explicitely
		dmin=>-12, dinc=>0.078125, unit=>'cm' # min -12 max 8
	initdim ($data,'n',vals=[@list]); # 20 objects with names in @list
	initdim ($data,'t',spacing=>0,unit=>'s', vals=>[10,15,25,40,90,120,240,480); # sampled at different time points
	initdim ($data,'z',min=>30,max=>28,unit=>'mm'); yet another way 

	# x,y,z are equally spaced numeric, n is non-numeric, t is numeric but at arbitrary distances
	... 

	# load or define $mask with dims x,y,z equal to that of data
	$i=ncop($data,$mask,'mult',0); # multiply mask onto data. 
	# Since mask has only x,y,z, the dims of $data are unchanged.
	# x,y,z, in $mask or $data must be either 1 or equal. 
	
	# Calculate the average over my region of interest:
	$sum=nreduce($i,'avg','x','y','z');
	
	... 

	Now you want to associate your images with other data recorded at each time point:
	# $data2: PDL [8, 100] (t,pars)
	$more_complex=ncop($data,$data2,'plus',0);
	#This will produce a piddle of size [256,256,20,8,30,100]
	
	# if you want to average over every second object between n = 6 - 12:
	$avg=nagg(sln($data,n=>'6:12:2'),'average','n');



=head1 DESCRIPTION

This module is an extension to PDL by giving the dimensions a meaningful name,
values or ranges. The module also provides wrappers to perform most PDL
operations based on named dimensions. Each dimension is supposed to have a unique name.

If you prefer methods over functions, say 

	bless $piddle, "PDL::Dims";

Names of dims can be any string (x,y,z,t,city, country, lattitude, fruit,pet, ...)

Each dim has its own hash with several important keys; 

=cut #my @keys = qw(pos size num spacing min max inc vals index dummy);

=over 

=item * pos - dimension index 0..ndims-1

=item * dimnames - a string by which the dim is accessed

=item * index - current position within a dim. PDL::Dims knows the concept of a current position within a piddle

=item * dummy - if true, initdim creates a dim of size at pos

=item * num - dimension has numeric properties; if false, no min/max/inc are calculated. E.g. a dim pet may have values for dog, cat, fish, rabbit, mouse, parrot, min/max don't make sense in this case.

=item * spacing - if true, values are evenly spaced; inc is undef if false

=item * vals - list all values along a dim, if not evenly spaced each value is stored. Can cause memory issues in very large dims

=item * min/max - minimum and maximum of numeric dimensions

=item * inc - step between two indices in equally spaced dimensions

=item * unit - the unit of vals.

=back


=head1 SUBROUTINES/METHODS



The module has two different types of functions. 

First, there are several utitility functions to manipulate and retrieve the dimension info. 
Currently, they only work on the metadata, no operations on the piddle are performed.
It is your responsibility to call the appropriate function whenever piddle dims change.

Then there are functions to perform most PDL operations based on named dimensions instead
of numbered dims. Wrappers to slice (sln), reduce (nreduce) and other functions 
(nop, ncop) are implemented. 

The following parameters are currently used by PDL::Dims. It is *strongly* discouraged
to access them directly except during calls to initdim. Use the functions listed below
to manipulate and retrieve values.

They are usually called like that:

	func ($piddle , [$dim, [value]]);

if no dim is given, an array reference to all values are returned.

Otherwise, it returns the given value for a particular $dim, setting it to $value if defined.


=head2 diminfo


	$infostr = diminfo($piddle);
	
An extended version of PDLs info, showing dimnames and sizes (from header). 

=head2 dimsize 

	dimsize($piddle,[$dim,[$size]]);

set/get dimension size of piddle by name.

=head2 dimname 

	dimname($piddle,[$position,[$name]]);

set/get dimension size of piddle by name. 

=head2 idx 
	
	idx($piddle,[$name,[$current]])

set/get current index values by name

=head2 didx 

	didx($piddle,[$name,[$pos]]);

get/set position of dims by their names

=head2 i2pos

=head2 pos2i

	i2pso($piddle,$dim,[$index]);
	pso2i($piddle,$dim,$value);

Converts value from/to index. So you can say, for example, if you have a piddle counting stuff in different houses,

	sln($house,pets=>pos2i($house,pets,'dog'),rooms=>pos2i(housee,rooms,'kitchen'));

something more realistic: Imagine you have two images of the same object but with different scaling and resolution or orientation. You want to extract what's between y = 10 and 20 cm of both images

	ya10=pos2i($a,'y',10);
	ya20=pos2i($a,'y',20);
	$slice=sln($a,y=>"$ya10:$ya20");

or if you want to resample something, the index $yb in $b corresponds to the index $ya in $a:

	$ya=pos2i($a,'y',i2pos($b,'y',$yb));



=head2 dmin

	dmin($piddle,[$dim,[$min]]);

get/set minimum value for a dimension

=head2 dmax

	dmax($piddle,[$name,[$max]]);

get/set maximum value for a dimension

=head2 dinc 

	dinc($piddle,[$name,[$increment]]);

get/set maximum value for a dimension

=head2 vals

	vals($piddle,$dim,[$index ,[$val]| $array_ref])

get/set values of an axis. As a third argument you can either supply an index,
then you can access that element or a reference to an array of size dimsize supplying 
values for that dim. 

Please take a look on i2pos, pos2i, spacing and dnumeric to better understand the behaviour.


=head2  unit 
	
	unit($piddle,[$dim,[$unit]]);

get/set the unit parameter. In the future, each assignment or operation
should be units-avare, e.g. converting autmatically from mm to km or feet,
preventing you from adding apples to peas ...

=head2 spacing 

	spacing ($piddle,[$dim,[$spacing]]);

if true, the spacing between indices is assumed to be equal.

=head2 dnumeric
	
	dnumeric ($piddl,[$dim,[$bool]]);

get/set the flag if the piddle dim has numeric or other units. This has influence
on vals, dmin, dmax, dinc.

=head2 initdim  

initializes a dimenson

usage: 
	initdim($piddle,$dimname,[%args]);

Arguments are the fields listed above. This should be called repeatedly after piddle
creation to match the structure. 

If pos is not provided, the next free position is used. If you call 

	initidim ($piddle,$name)

N times on an N-dimensional piddle, it will create N dimensions with sizes corresponding to the
dim of the piddle. 

=head2 rmdim 

removes a dminenso 

	rmdim($piddle,$dim);



=head2 copy_dim 

copies the diminfo from one piddle to the next.

	copy_dim($a,$b,[$dim,[$pos]]);

calls initdim on $b with parameters from $a. You can supply a new position. If you 
call it with just two arguments, all dims are copied.

=head2 sln

	sln ($piddle,%slices);

This replaces slice and it's derivatives.

perform slicing based on names. Returns correct dimension info. Unspecified 
dims are returned fully. If you want to squeeze, use 
	sln($piddle, $dim=>"($value)"); 
	
or nsqueeze on the result, if you want all squeezed. Both will do the necessary rmdim calls for you,


Example:
	$sl=sln($a,x=>'0:10:2',t=>'4:',);

You can omit dims; it parses each key-value pair and constructs a slice string,
so what typically works for slice, works here.

=head2 nop

This is the way to perform non-aggregate operations on one piddle which work only on one dim,
like e.g. rotate. 

usage:
	$res=nop($a,$operation,[@args]);


=head2 ncop

This is the way to perform any operations involving two operands when using PDL::Dims. 

operates on two piddles, combining them by names. Equally named dimensions have
to obey the usual threding rules. For opertators like '+' use the named version
and an additional argument of 0.

usage:
	$c=ncop($a,$b,$operation,[@args]);

=head2 nagg

Use to perform aggregate functions, that reduce the dim by 1.

	nagg($piddle,$operation,$dim,[@args]);

Use this to perform sumover, average, ...


=head2 nreduce

a wrapper around reduce (requires PDL::Reduce) calling with names instead.

	nreduce($piddle,$operations,@dimnames);

=head2 active_slice

A conveniance function, similar to sln, but it returns a slice at the current position (index).

useage 

	$slice=active_slice($piddle,@ignore);

returns the current selection (as accessed by idx) as a slice. Returns full dims on supplied dim list.

Call nsqueeze afterwards if that is what you want.

=head2 nsqueeze

A wrapper to squeeze. It makes the appropriate header updates (i.e. calls to rmdim).


=head2 is_sane

A sanity check for piddles. This is your friend when working with PDL::Dims!

	$err=is_sane($piddle)


returns 0 upon success, otherwise the first inconsisteny found is returned. This may
change in future releases.

=head1 AUTHOR

Ingo Schmid




=head1 LICENSE AND COPYRIGHT

Copyright 2014 Ingo Schmid.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PDL::Dims
