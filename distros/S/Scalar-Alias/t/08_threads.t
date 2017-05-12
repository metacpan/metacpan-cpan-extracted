#!perl -w

use strict;
use constant HAS_THREADS => eval{ require threads };
use Test::More HAS_THREADS ? (tests => 10) : (skip_all => 'Testing threads');

use Scalar::Alias;
use threads;


sub inc{
	if(@_){
		my alias $x = shift;
		$x++;
	}
	return;
}

sub inc2{
	foreach (@_){
		my alias $x = $_;
		$x++;
	}
	return;
}

sub inc3{
	my $foo = 'foo';
	$foo =~ s/foo/my alias $x = shift; $x++/e;
	return;
}

sub inc4{
	my alias $x = shift;
	eval q{
		my alias $y = $x;
		$y++;
	};
	return;
}

sub inc5{
	eval q{
		if(@_){
			if(@_){
				{
					my alias $x = $_[0];
					my alias $y = $x;
					$y++;
				}
			}
		}
	};
	return;
}


my $i = 0;
my $j = 10;

async{
	inc($i);
	inc($j);

	is $i, 1;
	is $j, 11;

	inc2($i);
	inc2($j);

	is $i, 2;
	is $j, 12;

	inc3($i);
	inc3($j);

	is $i, 3;
	is $j, 13;

	inc4($i);
	inc4($j);

	is $i, 4;
	is $j, 14;

	async{
		inc5($i);
		inc5($j);

		is $i, 5;
		is $j, 15;
	}->join;
}->join;
