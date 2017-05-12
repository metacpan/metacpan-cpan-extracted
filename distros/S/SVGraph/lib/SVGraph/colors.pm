#!/bin/perl
package SVGraph::colors;
use strict;

sub HSVtoRGB {
	my ($hue, $saturation, $v) = @_;
	my ($red, $green, $blue);

	# If there's no saturation, then we're a grey
	unless ($saturation) {
		$red = $green = $blue = $v;
		return ($red, $green, $blue);
	}

	#print $hue . " " . $saturation . " " . $v ."\n";

	$hue /= 60;
	my $i = int( $hue );
	my $f = $hue - $i;
	my $p = $v * ( 1 - $saturation );
	my $q = $v * ( 1 - $saturation * $f );
	my $t = $v * ( 1 - $saturation * ( 1 - $f ) ); 


	if ($i == 0) { return( $v, $t, $p ) }
	elsif ($i == 1) { return( $q, $v, $p ) }
	elsif ($i == 2) { return( $p, $v, $t ) }
	elsif ($i == 3) { return( $p, $q, $v ) }
	elsif ($i == 4) { return( $t, $p, $v ) }
	           else { return( $v, $p, $q ) }
}


our %table_SV=
(
	'N0' => [99,99],
	'N1' => [82,86],
	'N2' => [72,79],
	'N3' => [59,71],
	'N4' => [33,59],
	'L0' => [80,99],
	'L1' => [60,99],
	'L2' => [40,99],
	'L3' => [30,99],
	'B0' => [99,80],
	'B1' => [99,60],
	'B2' => [99,40],
	'B3' => [99,30],
);

our %table_H=
(
	'red'		=>1,
	'vermillion'	=>15,
	'amber'	=>24,
	'gold'		=>45,
	'yellow'	=>60,
	'apple'	=>75,
	'chartreuse'=>90,
	'lime'		=>100,
	'green'	=>115,
	'mint'		=>135,
	'jade'		=>145,
	'turquoise'	=>160,
	'cyan'	=>180,
	'azure'	=>195,
	'sapphire'	=>210,
	'cobalt'	=>220,
	'blue'		=>240,
	'purple'	=>260,
	'violent'	=>270,
	'orchid'	=>290,
	'magenta'	=>300,
	'fuchsia'	=>315,
	'carmine'	=>330,
	'scarlet'	=>340,
);

our %table;

foreach my $H_name(keys %table_H)
{
	foreach my $SV_name(keys %table_SV)
	{
		my ($H,$S,$V)=($table_H{$H_name},$table_SV{$SV_name}[0],$table_SV{$SV_name}[1]);
		$S/=100;$V=($V/100)*255;  
		$table{$H_name}{$SV_name}=int((&HSVtoRGB($H,$S,$V))[0]).
			",".(int((&HSVtoRGB($H,$S,$V))[1])).
			",".(int((&HSVtoRGB($H,$S,$V))[2]));
	}
}

# add black color
foreach my $SV_name(keys %table_SV){$table{black}{$SV_name}="0,0,0";}


# searching for contrast colors
our @table_C;
my $count;
my $c=1;
my $contrast=2;


do
{

	local %table_H=%table_H;

	while ($c)
	{
		$c=0;
		foreach my $key(sort {$table_H{$a} <=> $table_H{$b}} keys %table_H)
		{
			$c=1;
			$count++;
	
			if ($count/$contrast == int($count/$contrast))
			{
			#   $lastvalue=$table_H{$key};
				push @table_C,$key;delete $table_H{$key};#$count=0;
			}
		}
	}

};





1;
