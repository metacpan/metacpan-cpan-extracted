package Parse::Pyapp::Parser;
use 5.006;
use strict;
our $VERSION = '0.01';
#use Data::Dumper;


sub addrule {
    my $pkg = shift;
    my $lhs = shift;
    foreach (@_){
	my $sub = pop @$_ if ref $_->[-1] eq 'CODE';
	push @{$pkg->{grammar}->{$lhs}}, { rhs => $_, callback => $sub };
	if(ref $sub eq 'CODE'){
	    $pkg->{rcb}->{join q/,/, $lhs, @{$_}[0..$#$_-1]} = $sub;
	}
    }
}

sub addlex {
    my $pkg = shift;
    my $lhs = shift;
    # lexical callback function
    $pkg->{lcb}->{$lhs} = pop @_ if( ref $_[-1] eq 'CODE' );
    foreach (@_){
	$pkg->{lexidx}->{$_->[0]}->{$lhs} = $_->[1];
	push @{$pkg->{grammar}->{$lhs}}, { rhs => $_ };
    }
}

sub start {
    die "Unknown symbol $_[1]\n" unless exists $_[0]->{grammar}->{$_[1]};
    $_[0]->{start} = $_[1];
}

use B::Deparse;

sub stringify {
    my $pkg = shift;
    my $grammar;
    my $deparse = B::Deparse->new();
    foreach my $lhs (keys %{$pkg->{grammar}}){
	my $sum = 0;
	$grammar .=
	    join q//,
	    "$lhs : \n\t",
	    join( qq/\n\t | \n\t/,
		  map {
		      my $body;
		      if(ref( $_->{callback}) eq 'CODE'){
			  $body = $deparse->coderef2text($_->{callback});
			  $body =~ s/^(.+)$/\t$1/mg;
			  $body = "\n$body";
		      }
		      join q/ /, grep{$_}
		      @{$_->{rhs}}[0..$#{$_->{rhs}}-1],
		      "[".$_->{rhs}->[-1]."]",
		      $body;
		  }
		  @{$pkg->{grammar}->{$lhs}})."\n\t;\n",
	    $/
	;
    }
$grammar
}

sub toCNF {
    die unless caller eq __PACKAGE__;
    my $pkg = shift;
    my $maxsym;
    do{
	$maxsym = 0;
	foreach my $lhs (keys %{$pkg->{grammar}}){
	    foreach (@{$pkg->{grammar}->{$lhs}}){
		if(@{$_->{rhs}} > 3){
		    $maxsym = @{$_->{rhs}} if(@{$_->{rhs}} > $maxsym);
		    $pkg->addrule("%%".$pkg->{symcount}, [splice(@{$_->{rhs}}, 1, -1, "%%".$pkg->{symcount}), 1]);
		    $pkg->{symcount}++;
		}
	    }
	}
    }while($maxsym > 3);

    # building rules' index
    foreach my $lhs (keys %{$pkg->{grammar}}){
	foreach (@{$pkg->{grammar}->{$lhs}}){
	    $pkg->{rulidx }->{join q/,/,$lhs, @{$_->{rhs}}[0..$#{$_->{rhs}}-1]} = $_->{rhs}->[-1];
	}
    }


}


sub visit {
    my $pkg = shift;
    $pkg->{var} = {};
    $pkg->{tree} = {};
    @{$pkg->{nonterm}} = ();
    $pkg->_visit(join( q/,/, 0, $pkg->{lastidx}, $pkg->{start}));
}

sub _visit {
    my ($pkg, $key) = @_;

    my @L = split /,/, $key;
    my $root = (split /,/,$key)[-1];
    my @R = split /,/, $pkg->{bp}->{$key};

    if(!defined $pkg->{bp}->{$key} && $L[0] == $L[1]){
	if(ref($pkg->{lcb}->{$root}) eq 'CODE'){
	    $pkg->{lhs} = $root;
	    $pkg->{lcb}->{$root}->($pkg, $pkg->{token}->[$L[0]]);
	}
	return;
    }

    # left
    $pkg->_visit(join( q/,/, $L[0], $R[0], $R[1]));

    # right
    $pkg->_visit(join( q/,/, $R[0]+1, $L[1], $R[2])) if $R[2];

    # root
    if($root !~ /^%%/o){
	$pkg->{pos} = [ $root, $R[1], @{$pkg->{nonterm}} ];
	if(ref($pkg->{rcb}->{join q/,/, @{$pkg->{pos}}}) eq 'CODE'){
	    $pkg->{lhs} = $root;
	    $pkg->{rcb}->{join q/,/, @{$pkg->{pos}}}->($pkg, @{$pkg->{token}}[$L[0]..$L[1]]);
	}
	@{$pkg->{nonterm}} = ();
	@{$pkg->{pos}} = ();
    }
    else{
	unshift @{$pkg->{nonterm}}, grep{$_!~/^%%/o} $R[1], $R[2];
#	print @{$pkg->{nonterm}},$/;
    }
}


sub parse($@) {
    my $pkg = shift;
    $pkg->toCNF;

    my @nont = keys %{$pkg->{grammar}};

    $pkg->{lastidx} = $#_;
    $pkg->{token} = \@_;

    # probability matrix
    $pkg->{pi} = undef;
    # back pointers
    $pkg->{bp} = undef;

    ####################
    # base case
    ####################
    foreach my $i (0..$#_){
	foreach (keys %{$pkg->{grammar}}){
	    $pkg->{pi}->{"$i,$i,$_"} = $pkg->{lexidx}->{$_[$i]}->{$_} if $pkg->{lexidx}->{$_[$i]}->{$_};
	}
    }

    ####################
    # recursive case
    ####################
    foreach my $span (0..$#_){
	foreach my $begin (0..$#_-$span){
	    my $end = $begin + $span;
	    foreach my $m ($begin..$end){
		foreach my $A (@nont){
		    foreach my $B (@nont){
			foreach my $C (@nont){
			    my $prob = $pkg->{pi}->{"$begin,$m,$B"} *
				$pkg->{pi}->{join q/,/,$m+1,$end,$C} *
				    $pkg->{rulidx}->{join q/,/, $A, $B, $C};
			    if($prob && $prob > $pkg->{pi}->{"$begin,$end,$A"}){
				$pkg->{pi}->{"$begin,$end,$A"} = $prob;
				$pkg->{bp}->{"$begin,$end,$A"} = "$m,$B,$C";
			    }
			}
			########################################
			# for a single right hand derivation
			########################################

			if($pkg->{rulidx}->{join q/,/, $A, $B}){
			    my $prob = $pkg->{pi}->{"$begin,$m,$B"} * $pkg->{rulidx}->{join q/,/, $A, $B};
			    if($prob && $prob > $pkg->{pi}->{"$begin,$end,$A"}){
				$pkg->{pi}->{"$begin,$end,$A"} = $prob;
				$pkg->{bp}->{"$begin,$end,$A"} = "$begin,$B";
			    }
			}
		    }
		}
	    }
	}
    }
    return unless ($pkg->{bp}->{join(q/,/,0,$pkg->{lastidx},$pkg->{start})});
    $pkg->visit;
    1;
}




1;

__END__
