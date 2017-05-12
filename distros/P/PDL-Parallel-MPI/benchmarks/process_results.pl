#!/usr/bin/perl -w -I/accounts/darin/current/blib/arch -I/accounts/darin/current/blib/lib


sub show 
{
	use PDL::Graphics::PGPLOT;
	dev('/XSERVE') unless $main::started_pgplot;
	$main::started_pgplot =1;
	my $result = shift;
	my $color = shift;
	my $x = $result->{x};
	my $d = sequence($x->getdim(0));
	#$d=$x;
	points $d, $result->{mean},{COLOR => $color};
	errb $d, $result->{mean}, $result->{rms},{COLOR=>$color};
	hold;
	line $d, $result->{'fit'}, {COLOR => $color};
}

sub PDL::grok
{
	my ($mean,$rms,$x,$const,$result,$X);
	my $piddle=shift;
	($mean,$rms) = statsover($piddle);
	$x = sequence($mean->getdim(0));
	$x = 2 ** $x ; 
	$const = ones($x->getdim(0));
	$X = transpose(cat($const,$x));
	$result = lm($X,transpose($mean));
	$result->{'mean'} = $mean;
	$result->{'rms'} = $rms;
	$result->{'x'} = $x;
	$result->{'fit'} = $x * $result->{beta_hat}->at(0,1) + $result->{beta_hat}->at(0,0);
	$result->{'relative_error'} = ($result->{'mean'} - $result->{'fit'}) / $result->{'mean'};
	return $result;
}
