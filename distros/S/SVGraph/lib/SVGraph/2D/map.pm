#!/bin/perl
package SVGraph::2D::map;

use SVG;
use strict;
use SVGraph::world;
use SVGraph::colors;
use SVGraph::2D;


our @ISA=("SVGraph::world", "SVGraph::2D", "SVGraph::colors");


# display ranges used, when are not defined 
my %ranges = (
	world =>{
		x_translate => 25,
		y_translate => 0,
		x =>810,
		y =>450
	},
	europe =>{
		x_translate => -345,
		y_translate => -20,
		x =>150,
		y =>130
	},
	america =>{
		x_translate => 0,
		y_translate => 0,
		x =>400,
		y =>360
	},
	africa =>{
		x_translate => -360,
		y_translate => -115,
		x =>170,
		y =>180
	},
	asia =>{
		x_translate => -440,
		y_translate => -25,
		x =>350,
		y =>220
	},
	oceania =>{
		x_translate => -630,
		y_translate => -206,
		x =>150,
		y =>100
	},
	slovakia =>{
		x_translate => -102,
		y_translate => -259,
		x =>450,
		y =>250
	}
);


my ($koef, $min, $max);


sub new
{
	my $class=shift;
	my %env=@_;
	my $self={};
	

	unless($env{continent}){die "Missing map parameter.\n";}

	# australia and oceania is the same
	if($env{continent} eq "australia"){$env{continent} = "oceania";}
	$self->{continent} = $env{continent};


	# do we have parameters?

	if($env{x})
	{
		$self->{ENV}{x} = $env{x};
	}
	else
	{
		$self->{ENV}{x} = $ranges{${env}{continent}}{x};
	}

	if($env{y})
	{
		$self->{ENV}{y} = $env{y};
	}
	else
	{
		$self->{ENV}{y} = $ranges{${env}{continent}}{y};
	}

	if(defined $env{show_legend})
	{
		$self->{ENV}{show_legend} = $env{show_legend};
	}
	else
	{
		$self->{ENV}{show_legend} = 1;
	}

	$self->{ENV}{title} = $env{title};
	$self->{ENV}{x_translate} = $ranges{${env}{continent}}{x_translate};
	$self->{ENV}{y_translate} = $ranges{${env}{continent}}{y_translate};

	return bless $self,$class;
}

sub prepare
{

	my $self = shift;
	

	#
	# new svg graphics x*scale, y*scale
	#

	$self->{SVG}=SVG->new(width=>$self->{ENV}{x},height=>$self->{ENV}{y});
	$self->{SVG}->script()->CDATA("setTimeout('reload()', ".($self->{ENV}{reload}*1000).");") if $self->{ENV}{reload};

	# preparing colors of the countries
	$self->prepare_colors();

	# drawing the BLOCK
	$self->prepare_block(color => 205); 
	# adding text
	$self->prepare_title();

	# preparing the columns
	$self->prepare_columns();
	
	$self->prepare_legend();


	# scale
	my $scale_x = (($self->{block_right} - $self->{block_left})/$ranges{$self->{continent}}{x})*0.95;
	my $scale_y = (($self->{block_down} - $self->{block_up})/$ranges{$self->{continent}}{y})*1.09;

	#translations
	my $trans_x = $self->{ENV}{x_translate}*$scale_x + $self->{block_left};
	my $trans_y = $self->{ENV}{y_translate}*$scale_y + $self->{block_up};

	# group countries
	my $continent_group = $self->{SVG}->group(id=>$self->{continent});

	my @columns = keys  %{$self->{columns}};
	
	# we have only one column
	my $column = $columns[0];
	
	my ($h, $s, $v);

	# hue of our color from table
 	if($self->{columns}{$column}->{ENV}{color})
 	{
 		$h = $SVGraph::colors::table_H{$self->{columns}{$column}->{ENV}{color}};
 	}
 	else # color is not defined
 	{
 		$h = $SVGraph::colors::table_H{'green'};
 	}
	
	$v = 255;

	# drawing the whole world
	if($self->{continent} eq 'world')
	{
		foreach (keys %SVGraph::world::countries)
		{

			# saturation defines the value of a country
			$s = $self->{columns}{$column}->{data}{$_}/10;


			if($min < 0)
			{
				if($s <= 0)
				{
					$s = abs(abs($s) - abs(($min*$koef)/100)) * abs(($min*$koef)/100);
				}
				else
				{
					$s = abs(abs($s) + abs(($min*$koef)/100)) * abs(($min*$koef)/100)
				}
			}	

			# all countries have the same color intensity
			if($koef == 0){$s = 1}		
	
			# no white countries
			if($s < 0.05){$s = 0.05}	
	
			my @rgb = SVGraph::colors::HSVtoRGB($h,$s,$v);
			
	
			# color of this country
			my $country_color = 'rgb('. $rgb[0] . ', ' . $rgb[1] . ', ' . $rgb[2] . ')';

	
			$self->{SVG}->path(
					style=>'font-size:12;fill:'.$country_color.
						';stroke:#000000;stroke-width:0.25;stroke-miterlimit:1',
					d=>''.$SVGraph::world::countries{$_}{d}.'',
					transform=>'matrix('.$scale_x.',0,0,'.$scale_y .','.$trans_x.','.$trans_y.')'
			);	
		}

		# end, everything is drawed
		$self->{SVG_OUT} = $self->{SVG}->xmlify;
	
		return $self->{SVG_OUT};
	}

	#drawing slovakia
	elsif($self->{continent} eq 'slovakia')
	{
		foreach (keys %SVGraph::world::slovakia)
		{
		# saturation defines the value of a country
			$s = $self->{columns}{$column}->{data}{$_}/100;


			if($min < 0)
			{
				if($s <= 0)
				{
					$s = abs(abs($s) - abs(($min*$koef)/100)) * abs(($min*$koef)/100);
				}
				else
				{
					$s = abs(abs($s) + abs(($min*$koef)/100)) * abs(($min*$koef)/100)
				}
			}	

			# all countries have the same color intensity
			if($koef == 0){$s = 1}		
	
			# no white countries
			if($s < 0.05){$s = 0.05}	
	
			my @rgb = SVGraph::colors::HSVtoRGB($h,$s,$v);
			
	
			# color of this country
			my $country_color = 'rgb('. $rgb[0] . ', ' . $rgb[1] . ', ' . $rgb[2] . ')';
	
			$self->{SVG}->path(
					style=>'font-size:12;fill:'.$country_color.
						';stroke:#000000;stroke-width:0.25;stroke-miterlimit:1',
					d=>''.$SVGraph::world::slovakia{$_}{d}.'',
					transform=>'matrix('.$scale_x.',0,0,'.$scale_y .','.$trans_x.','.$trans_y.')'
			);	
		}

		# end, everything is drawed
		$self->{SVG_OUT} = $self->{SVG}->xmlify;
	
		return $self->{SVG_OUT};
	}
	
	
	$self->{continent} =~ tr/A-Z/a-z/;
	
	# drawing only one continent
	foreach my $country (@{$SVGraph::world::continents{$self->{continent}}})
	{	

		# saturation defines the value of a country
		my $s = $self->{columns}{$column}->{data}{$country}/100;


		if($min < 0)
		{
			if($s <= 0)
			{
				$s = abs(abs($s) - abs(($min*$koef)/100)) * abs(($min*$koef)/100);
			}
			else
			{
				$s = abs(abs($s) + abs(($min*$koef)/100)) * abs(($min*$koef)/100)
			}
		}

		# all countries have the same color intensity
		if($koef == 0){$s = 1}

		# no white countries
		if($s < 0.05){$s = 0.05}	

		my @rgb = SVGraph::colors::HSVtoRGB($h,$s,$v);	

		# color of this country
		my $country_color = 'rgb('. $rgb[0] . ', ' . $rgb[1] . ', ' . $rgb[2] . ')';

		$continent_group->path(
			style=>'font-size:12;fill:'.$country_color.';stroke:#000000;stroke-width:0.25;stroke-miterlimit:1',
			d=>''.$SVGraph::world::countries{$country}{d}.'',
			transform=> 'matrix('.$scale_x.',0,0,'.$scale_y .','.$trans_x.','.$trans_y.')'
		);
	}
	
	$self->{SVG_OUT} = $self->{SVG}->xmlify;
	
	return $self->{SVG_OUT};
}


#
# preparing colors of the countries
#
sub prepare_colors
{
	my $self = shift;
	$min = 0;
	$max = 0;

	my @columns = keys  %{$self->{columns}};

	# we have only one column
	my $column = $columns[0]; 

	
	
	# finding min and max from inserted values
	foreach my $country (@{$SVGraph::world::continents{$self->{continent}}})
	{
		unless(defined $self->{columns}{$column}->{data}{$country}){next;}	
		
		if ($self->{columns}{$column}->{data}{$country} < $min)
		{
			$min = $self->{columns}{$column}->{data}{$country};
			next;
		}
		
		if ($self->{columns}{$column}->{data}{$country} > $max)
		{
			$max = $self->{columns}{$column}->{data}{$country};
		}
	}

	# all countries are the same color
	if(($max - $min) == 0)
	{
		foreach my $country (keys %{$self->{columns}{$column}->{data}})
		{
			$self->{columns}{$column}->{data}{$country} = 100;
		}
		return;
	}
	
	# or not	
	if($min > 0)
	{
		$koef = 100/(abs($max) - abs($min));
	}
	elsif($min < 0 && $max < 0)
	{
		$koef = 100/(abs($min) - abs($max));
	}
	else
	{
		$koef = 100/(abs($max) + abs($min));
	}

	foreach my $country (keys %{$self->{columns}{$column}->{data}})
	{
		$self->{columns}{$column}->{data}{$country} *= $koef;
	}
}

#
# prepare of the legend
#
# overrided method

sub prepare_legend
{
	my $self=shift; 
	
	return undef unless $self->{ENV}{show_legend};

	my @columns = keys  %{$self->{columns}};

	# we have only one column
	my $column = $columns[0];

	# color
	my ($h, $s, $v);

	# hue of our color from table
 	if($self->{columns}{$column}->{ENV}{color})
 	{
 		$h = $SVGraph::colors::table_H{$self->{columns}{$column}->{ENV}{color}};
 	}
 	else # color is not defined
 	{
 		$h = $SVGraph::colors::table_H{'green'};
 	}
	
	$v = 255;

	my $width=(($self->{ENV}{x}-$self->{block_right})*0.07);
	my $height=($self->{ENV}{y}*0.03);
	my $x=($self->{block_right}+(($self->{ENV}{x}-$self->{block_right})*0.15));

	my (@rgb,$text);

	my @values;

	if($koef == 0)
	{
		foreach (keys %{$self->{columns}{$column}->{data}})
		{
			push (@values, $self->{columns}{$column}->{data}{$_});
		}
	}
	else
	{
		foreach (keys %{$self->{columns}{$column}->{data}})
		{
			push (@values, $self->{columns}{$column}->{data}{$_}/$koef);
		}
	}
	
	my @legend;

	my $step;

	if($min > 0)
	{
		$step = $max - $min;
	}
	elsif($min < 0 && $max < 0)
	{
		$step = abs($min) - abs($max);
	}
	else
	{
		$step = abs($min) + $max;
	}

	if((scalar @values) < 6 && (scalar @values)>0)
	{
		$step = $step/(scalar @values);
		$s = 1/(scalar @values+1);

		my $tmp;

		for (0 .. $#values)
		{
			$tmp = $max - $_ * $step;
			push (@legend, $tmp);
		}
		@legend = reverse @legend;
	}
	elsif((scalar @values)<=0)
	{
		# there are no values of countries, the legend will be not displayed
		return;
	}
	# only 5 things in legend
	else
	{
		$s = 1/5;
		$step = $step/5;

		my $tmp;

		for (0 .. 4)
		{
			$tmp = $max - $_ * $step;
			push (@legend, $tmp);
			
		}
		@legend = reverse @legend;
	}


	my $previous_num;

	for (0 .. $#legend+1)
	{
		# adjustment of the range for the legend
		my $divider = 2 - $_/($#legend+2);	
		
		# first loop
		if ($_ == 0)
		{
			@rgb = SVGraph::colors::HSVtoRGB($h,0.05,$v);
				
			$text = $min . " - ". int($legend[$_]/$divider);
		}
		# last loop
		elsif($_ == $#legend+1)
		{

			if($min > 0)
			{
				@rgb = SVGraph::colors::HSVtoRGB($h,1,$v);
				
				$text = $previous_num . " - " . $max;
			}
			else
			{
				@rgb = SVGraph::colors::HSVtoRGB($h,1,$v);
				
				$text = $max;
			}
		}		
		else
		{
			@rgb = SVGraph::colors::HSVtoRGB($h,$s*$_,$v);
				
			$text = $previous_num . " - ". int($legend[$_]/$divider+1);
		}

		$previous_num = int($legend[$_]/$divider);

		my $color = 'rgb('. $rgb[0] . ', ' . $rgb[1] . ', ' . $rgb[2] . ')';

		$self->{SVG}->rect(
			x=>int($x),
			y=>int($self->{block_up}+($_*($height*1.7)-$height)),
			rx=>"2pt",
			ry=>"2pt",
			width=>$width,
			height=>$height,
			'stroke-width'	=>"1pt" ,
			'stroke'       =>$color,
			'fill'         =>$color,
			'stroke-linecap'	=>"round",
			'stroke-linejoin'	=>"round",
		);

		my $textsize=$height*0.6;
		

		$self->{SVG}->text
		(
			x=>int($x+($width*1.5)),
			y=>int($self->{block_up}+($_*($height*1.7)-$height)+($textsize/2)+($height/4)),
			style =>
			{
				'text-anchor'	=>	'start',
				'font-family'	=> 'Verdana',
				'font-size'	=> int($textsize).'px',
				'font-weight'	=> "600",
				'fill'		=> "black",
			},
		)->cdata($text);
	}
 
	return 1;
}

1;