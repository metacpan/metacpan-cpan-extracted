#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib
use PDL;
use strict;

sub PDL::ss {
	my $piddle= shift;
	sum(($piddle - $piddle->avg) **2);
}
sub lm 
{
	use PDL::Slatec;
	my ($X,$Y) = @_;
	my $gram = $X->transpose x $X;
	my $beta_hat = $gram->matinv x $X->transpose x $Y;
	my $TSS = $Y->ss;
	my $err = $Y - ($X x $beta_hat);
	my $RSS = sum(($err * $err) **2);
	my $FSS = $TSS - $RSS;
	my $n = $Y->getdim(1);
	my $p = $X->getdim(0);
	my $S2 = $RSS / ($n-$p - 1);
	
	my $var_covar = $S2 * $gram->matinv;
	my $vc = $var_covar->copy;
	$vc->diagonal(0,1) .= 0;
	#print STDERR "basis not orthogonal!! $var_covar" if sum($vc) != 0;
	my $diag = $var_covar->diagonal(0,1)->transpose;
	my $SE = sqrt($diag);

	return 
	{
		beta_hat	=> $beta_hat,
		SE			=> $SE,
		TSS			=> $TSS,
		RSS			=> $RSS,
		FSS			=> $FSS,
		orthog		=> (sum($vc) == 0 ? 1 : 0)
	}
}

sub adj
{
	my @input = map {PDL::Core::topdl($_)} @_;
	my $rows = max pdl map {$_->getdim(1)} @input;
	my $cols = sum pdl map {$_->getdim(0)} @input;
	my $output = zeroes($cols,$rows);
	$cols=0;
	foreach (@input) 
	{
		my $min = $cols;
		my $max = ($cols = $cols + $_->getdim(0)) - 1;
		my $x ="$min\:$max,:";
		$output->slice($x) .= $_;
	}
	return $output;
}

sub PDL::put 
{
	@_ == 2 or die;
	my $piddle =shift;

	if (ref $_[0] eq 'GLOB') 
	{
		my $fh = shift;
		for my $row (0 .. $piddle->getdim(1)-1) {
			for my $column (0 .. $piddle->getdim(0)-1) {
				printf $fh "%f ", $piddle->at($column,$row);
			}
			print $fh "\n";
		}
		print $fh "\n";
	}

	else # filename passed
	{
		my $filename=shift;
		open OUTPUT, ">$filename" or die $!;
		$piddle->put(\*OUTPUT);
		close OUTPUT;
	}

}

sub get
{
	if (ref $_[0] eq 'GLOB') 
	{
		my $fh= shift;
		my $array_ref;
		while (<$fh>) 
		{
			last unless /\S/;
			push @{$array_ref},[split];
		}
		return pdl $array_ref;
	}

	else # filename passed
	{
		my $filename=shift;
		open INPUT,$filename;
		$_ = get(\*INPUT);
		close INPUT;
		return $_;
	}
	
}

sub get_many
{
	@_ == 1 or die;
	open INPUT,(shift);
	push @_, get(\*INPUT) until eof(INPUT);
	close INPUT;
	return @_;
}
1;
