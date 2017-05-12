#!/bin/perl
package SVGraph::2D::lines;
use SVGraph::2D;
use strict;


our @ISA=("SVGraph::2D");



sub new
{
	my $class=shift;
	my %env=@_;
	my $self={};

	%{$self->{ENV}}=%env;

	$self->{grid_y_scale_minimum}=$env{grid_y_scale_minimum};
	$self->{grid_y_scale_maximum}=$env{grid_y_scale_maximum};
	$self->{grid_y_main_spacing}=$env{grid_y_main_spacing};
 
	$self->{type}="lines";
	
	return bless $self,$class;
}





sub prepare
{ 
	my $self=shift;
	
	$self->{SVG}=SVG->new(width=>$self->{ENV}{x},height=>$self->{ENV}{y});
	$self->{SVG}->script()->CDATA("setTimeout('reload()', ".($self->{ENV}{reload}*1000).");") if $self->{ENV}{reload};
	
	# draw the block
	$self->prepare_block();

	# add the text
	$self->prepare_title();

	# prepare the columns
	$self->prepare_columns();
	
	#
	# VYPOCITANIE POCTU ROWSOV - $self->{grid_x_main_lines}
	# VYPOCITANIE MAX VALUE - $self->{value_max}
	#
	$self->prepare_axis_calculate();
	$self->prepare_axis_x_markArea(front=>0);
	$self->prepare_axis_x(); 
	$self->prepare_axis_x_mark(front=>0);
	
	$self->prepare_axis_y_markArea(front=>0);
	$self->prepare_axis_y();
	$self->prepare_axis_y_mark(front=>0);
	
	$self->prepare_legend();
	
		
		
		
	
	foreach my $color(keys %SVGraph::colors::table)
	{		
		my $g = $self->{SVG}->gradient
		(
			'-type' => "linear",
			'id'    => "gr_".$color."_0",
			'x1'=>"0%",'y1'=>"0%",'x2'=>"0%",'y2'=>"100%",
		);
		$g->stop(offset=>"0%",style=>"stop-color:rgb(".$SVGraph::colors::table{$color}{'B0'}.");stop-opacity:1");
		#$g->stop(offset=>"50%",style=>"stop-color:rgb(".$SVGraph::colors::table{$color}{'L1'}.");stop-opacity:1");
		$g->stop(offset=>"100%",style=>"stop-color:rgb(".$SVGraph::colors::table{$color}{'L1'}.");stop-opacity:1");
	}
	
	
	# drawing the lines
	
	my @data_stacked;
	# foreach my $column(keys %{$self->{columns}})
	foreach my $column(@{$self->{columnsA}})
	{
		my $color=$self->{columns}->{$column}{ENV}{color};
		my %colors=%{$SVGraph::colors::table{$color}};
		
		#  foreach (keys %colors)
		#  {
		#   print "C:$_ $colors{$_}[0]\n";
		#  }
		
		
		my $count;
		my $points;
		my ($point_x,$point_y);
		my (@points_x,@points_y,@points_data);
		#  my ();
		
		#$points_data[$_]="0" unless $points_data[$_];
		
		#  foreach my $data($self->{columns}{$column}->GetValues())
		foreach my $row(@{$self->{row}{label}})
		{
			my $data=$self->{columns}{$column}->{data}{$row};
						
			#next unless defined $self->{columns}{$column}->{data}{$row};
			
			my $data_o=$data; # data original
			my $data_w=$data; # data for display;
			$count++;
			
			#$data=$data/($self->GetRowSum($count-1)/100) if $self->{ENV}{type}=~/percentage/;
			$data=$data/($self->GetRowSum($row)/100) if $self->{ENV}{type}=~/percentage/;
			
			$data_stacked[$count]+=$data;
			#$data=$data_stacked[$count] if $self->{ENV}{type}=~/stacked/;
			if ($self->{ENV}{type}=~/stacked/)
			{
				if ($self->{ENV}{type}=~/percentage/)
				{
					#$data_w="$data_o(".((int($data*100))/100)."%)";
					$data_w=((int($data*100))/100)."%";
					$data=100-$data_stacked[$count]+$data;
				}
				else
				{
					#$data=$self->GetRowSum($count-1)-$data_stacked[$count]+$data;
					$data=$self->GetRowSum($row)-$data_stacked[$count]+$data;
				}
			}
			
			#   print "$column - $count - $data (".($self->GetRowSum($count-1)).") $self->{value_max_all}\n"
			#   if $self->{value_max_all}==$self->GetRowSum($count-1);
			
			my $height=(($data-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
			$height=int($height*100)/100;
			$height=0 if $height < 0;
			$height=$self->{block_height} if $height > $self->{block_height};
			my $width=($count-1)*($self->{block_width}/($self->{grid_x_main_lines}-1));
			$width=int($width*100)/100;   
			
			$points.=($self->{block_left}+$width).",".($self->{block_down}-$height)." ";
			push @points_x,($self->{block_left}+$width);
			push @points_y,($self->{block_down}-$height);
			push @points_data, $data_w;
		}
		
		if ($self->{ENV}{show_lines_smooth_range})
		{
			for my $sin_koef(3,4,6,10)
			{
				my $points_sin;  
				$points_sin.="M$points_x[0],$points_y[0] ";
				for (1..@points_x-2)
				{
					$points_sin.="S".($points_x[$_]+($points_x[$_-1]-$points_x[$_+1])/$sin_koef).",".($points_y[$_]+($points_y[$_-1]-$points_y[$_+1])/$sin_koef)." $points_x[$_],$points_y[$_] ";   
				}
				$points_sin.="S$points_x[-1],$points_y[-1] $points_x[-1],$points_y[-1]";
				$self->{SVG}->path(
					d=>$points_sin,
					'stroke-width'	=>"0.5pt" ,
					'stroke'		=>"rgb(".$colors{G0}.")",
					style	=>
					{
						'fill'			=>"white",
						'fill-opacity'	=>"0",
					}
				);
			}
		}
		
		if (
			$self->{ENV}{show_lines_smooth} ||
			$self->{ENV}{show_areas} ||
			$self->{columns}{$column}->{ENV}{show_area} ||
			$self->{columns}{$column}->{ENV}{show_line_smooth}
			)
		{
			
			my $min=$self->{grid_y_scale_minimum};$min=0 if $min<0;
			my $height=
			(
				($min-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100)
			)*($self->{block_height}/100);
			
			my $opacity="0";
			my $points_sin;
			my $sin_koef=6;
			
			my $first=-1;
			my $last;
			for (0..@points_x-2)
			{
				next unless defined $points_data[$_];
				
				$last=$_;
				if ($first == -1)
				{
					$points_sin.="M$points_x[$_],$points_y[$_] ";
					$first=$_;
					next;
				}
				
				my $x=int($points_x[$_]+($points_x[$_-1]-$points_x[$_+1])/$sin_koef);
				my $y=int($points_y[$_]+($points_y[$_-1]-$points_y[$_+1])/$sin_koef);
				
				if ($y>$self->{block_down}){$y=$self->{block_down}}
				
				# nebudem ohybat krivku pokial je buduca hodnota "undefined"
				if (not defined $points_data[$_+1])
				{
					$x=$points_x[$_];
					$y=$points_y[$_];
				}
				
				$points_sin.="S".
					($x).",".
					($y)." $points_x[$_],$points_y[$_] ";
				
			}
			
			$last=@points_x-1 if defined $points_data[@points_x-1];
			
			$points_sin.="S$points_x[$last],$points_y[$last] $points_x[$last],$points_y[$last]";
			
			if
			(
				(
					($self->{ENV}{show_areas})||
					($self->{columns}{$column}->{ENV}{show_area})
				)&&
				(!$self->{columns}{$column}->{ENV}{show_line})
			)
			{
				my $points_sin=$points_sin;
				$points_sin.=
				" S".$points_x[$last].",".($self->{block_down}-$height)." ".$points_x[$last].",".($self->{block_down}-$height).
				" S".$points_x[$first].",".($self->{block_down}-$height)." ".$points_x[$first].",".($self->{block_down}-$height);
#				$points_sin.=
#				" S".$self->{block_right}.",".($self->{block_down}-$height)." ".$self->{block_right}.",".($self->{block_down}-$height).
#				" S".$self->{block_left}.",".($self->{block_down}-$height)." ".$self->{block_left}.",".($self->{block_down}-$height);
				$opacity="1";
				$opacity=$self->{ENV}{show_areas_opacity} if $self->{ENV}{show_areas_opacity};
				$opacity=$self->{columns}{$column}->{ENV}{show_area_opacity} if $self->{columns}{$column}->{ENV}{show_area_opacity};
				$self->{SVG}->path(
					d=>$points_sin,
					'stroke-width'	=>"0pt" ,
					'fill'			=>"url(#gr_".$color."_0)",
					'fill-opacity'	=>$opacity,
				);
			}
			
			if
			(
				($self->{ENV}{show_lines_smooth})||
				($self->{columns}{$column}->{ENV}{show_line_smooth})
			)
			{
				my %plus;
				
				$plus{'stroke-dasharray'}=$self->{'ENV'}{'show_line_dasharray'}
					if $self->{'ENV'}{'show_line_dasharray'};
				$plus{'stroke-dasharray'}=$self->{'columns'}{$column}->{'ENV'}{'show_line_dasharray'}
					if $self->{'columns'}{$column}->{'ENV'}{'show_line_dasharray'};
				
				$self->{SVG}->path(
					d=>$points_sin,
					'stroke-width'	=>"2pt" ,
					'stroke'		=>"rgb(".$colors{N0}.")",
#					'stroke-linecap'	=>"round",
					'stroke-linejoin'	=>"round",
					'fill-opacity'	=>"0",
#					'stroke-dasharray' => "5,5",
					#'stroke-dashoffset' => 5,
					%plus
				);
			}
			
			
		}
		
		
		
		if ($self->{ENV}{show_lines})
		{
			my $min=$self->{grid_y_scale_minimum};$min=0 if $min<0;
			my $height=(($min-$self->{grid_y_scale_minimum})/($self->{grid_y_scale}/100))*($self->{block_height}/100);
			my @points_x=@points_x;
			my @points_y=@points_y;
			my $opacity="0";
			
			
			
			if(
				(
					($self->{ENV}{show_areas})||
					($self->{columns}{$column}->{ENV}{show_area})
				)&&
				(!$self->{columns}{$column}->{ENV}{show_line})
			)
			{
				$opacity="1";
				$opacity=$self->{ENV}{show_areas_opacity} if $self->{ENV}{show_areas_opacity};
				$opacity=$self->{columns}{$column}->{ENV}{show_area_opacity} if $self->{ENV}{show_area_opacity};
				push @points_x,$self->{block_right},$self->{block_left};
				push @points_y,($self->{block_down}-$height),($self->{block_down}-$height);
			}
			
			my $points=$self->{SVG}->get_path(
				x => [@points_x],
				y => [@points_y],
				-type   => 'path',
			);
			
			$self->{SVG}->path(
				%$points,
				'stroke-width'	=>"1pt" ,
				'stroke'		=>"rgb(".$colors{N0}.")",
				'stroke-linecap'	=>"round",
				'stroke-linejoin'	=>"round",
			#	style	=>
			#	{
				#'fill'			=>"rgb(".$colors{B1}.")",
				'fill'			=>"url(#gr_".$color."_0)",
				'fill-opacity'	=>$opacity,
			#	}
			);
		}
		
		for (0..@points_x-1)
		{
			
			
			if ($self->{ENV}{show_points} || $self->{columns}{$column}->{ENV}{show_points})
			{
				
				my $circle=$self->{SVG}->circle
				(
					cx	=>	$points_x[$_],
					cy	=>	$points_y[$_],
					r	=>	2,
					'fill'			=>	"white",
					'stroke'		=>	"rgb(".$colors{N0}.")",
					'stroke-width'	=>	"1pt",
				) if $points_y[$_] ne $self->{block_down};
				
=head1
				if ($self->{ENV}{show_points_animate} || $self->{columns}{$column}->{ENV}{show_points_animate})
				{
					
					my $circle2=$self->{SVG}->circle
					(
						cx	=>	$points_x[$_],
						cy	=>	$points_y[$_],
						r	=>	10,
						'fill'			=>	"white",
						'stroke'		=>	"rgb(".$colors{N0}.")",
						'stroke-width'	=>	"1pt",
						'fill-opacity'	=>	"0",
						'stroke-opacity'	=>	"0",
					);
					
					$circle2->animate
					(
						'attributeName'=>"r",
						'begin'=>"mouseover",
						'end'=>"mouseout",
						'from'=>10,
						'to'=>30,
#						'values'=>"30",
						'dur'=>"2s",
	#					'repeatDur'=>"freeze"
						'restart'=>"whenNotActive"
					);
					$circle2->animate
					(
						'attributeName'=>"fill-opacity",
						'begin'=>"mouseover",
						'end'=>"mouseout",
						'from'=>0,
						'to'=>0.5,
#						'values'=>"30",
						'dur'=>"2s",
	#					'repeatDur'=>"freeze"
						'restart'=>"whenNotActive"
					);
					$circle2->animate
					(
						'attributeName'=>"stroke-opacity",
						'begin'=>"mouseover",
						'end'=>"mouseout",
						'from'=>0,
						'to'=>0.9,
#						'values'=>"30",
						'dur'=>"2s",
	#					'repeatDur'=>"freeze"
						'restart'=>"whenNotActive"
					);
					
				}
=cut
				
			}
			
			$self->{SVG}->circle(
				cx=>(($points_x[$_]+$points_x[$_-1])/2),
				cy=>(($points_y[$_]+$points_y[$_-1])/2),r=>2,
				'fill'		=>	"rgb(".$colors{B1}.")",
				'stroke'		=>	"rgb(".$colors{L0}.")",
				'stroke-width'	=>	"1pt",
			) if $self->{ENV}{show_points_middle};
			
			
			if ($points_data[$_])
			{
				
				if (
						$self->{ENV}{show_data_background} ||
						$self->{columns}{$column}->{ENV}{show_data_background}
					)
				{
					my $width=length($points_data[$_])*5;
					
					my $rect=$self->{SVG}->rect(
						'x' => ($points_x[$_]+2),
						'y' => ($points_y[$_]-11),
						'width' => $width+3,
						'height' => 10,
						'fill'	=>"rgb(255,255,255)",
						'fill-opacity'	=>"1",
						'stroke'		=>"rgb(125,125,125)",
						'stroke-width'	=>"1pt",
						'stroke-linecap'	=>"round",
						'stroke-linejoin'	=>"round",
						'rx' => "2pt",
						'ry' => "2pt",
					);
=head1
					if ($self->{ENV}{show_data} || $self->{columns}{$column}->{ENV}{show_data})
					{
						$rect->text
						(
							x	=>	10,
							y	=>	10,
							style =>
								{
									'font-family'	=> 'Verdana',
									'font-size'		=> 8,
									'font-weight'	=> 400,
							#		'fill'		=>	"rgb(".$colors{B3}.")",
									'fill'	=>	"rgb(0,0,0)",
							#		'stroke'		=>	"rgb(0,0,0)",
							#		'stroke-width'	=>	"1pt",
									'stroke-linecap'	=>"round",
									'stroke-linejoin'	=>"round",
								},
						)->cdata($points_data[$_]);
					}
=cut
				}
				if ($self->{ENV}{show_data} || $self->{columns}{$column}->{ENV}{show_data})
				{
					$self->{SVG}->text
					(
						x	=>	$points_x[$_]+3,
						y	=>	$points_y[$_]-3,
						style =>
							{
								'font-family'	=> 'Verdana',
								'font-size'		=> '8px',
								'font-weight'	=> 400,
						#		'fill'		=>	"rgb(".$colors{B3}.")",
								'fill'	=>	"rgb(0,0,0)",
						#		'stroke'		=>	"rgb(0,0,0)",
						#		'stroke-width'	=>	"1pt",
								'stroke-linecap'	=>"round",
								'stroke-linejoin'	=>"round",
							},
					)->cdata($points_data[$_]);
				}
				
			}
			
			
#=head1
			# animated
			if
			(
				($self->{'ENV'}{'show_data_SMIL'} || $self->{columns}{$column}->{'ENV'}{'show_data_SMIL'})
				&&($points_data[$_])
			)
			{
			
				my $width=length($points_data[$_])*5;
				
				my $box=$self->{SVG}->polyline(
					'points'	=>
								($points_x[$_]-3).",".($points_y[$_]-5)." ".
								($points_x[$_]+$width).",".($points_y[$_]-5)." ".
								($points_x[$_]+$width).",".($points_y[$_]+5)." ".
								($points_x[$_]-3).",".($points_y[$_]+5)." ".
								($points_x[$_]-3).",".($points_y[$_]-5)." ",
					'fill'			=>"rgb(255,255,255)",
					'fill-opacity'	=>"0.7",
					'stroke'		=>"rgb(0,0,0)",
					'stroke-width'	=>"1",
					'stroke-opacity' => "0",
					'fill-opacity' => "0",
					'stroke-linecap'	=>"round",
					'stroke-linejoin'	=>"round",
				);
				
				$box->animate
				(
					'attributeName'=>"fill-opacity",
					'begin'=>"mouseover",
					'end'=>"mouseout",
#					'from'=>"0",
					'values'=>"1",
#					'dur'=>"0.5s",
#					'repeatDur'=>"freeze"
					'restart'=>"whenNotActive"
				);
			}
#=cut
			
		}

=head1
  	$self->{SVG}->polyline(
		points	=>	$points
	#		.$self->{block_right}.",".$self->{block_down}." "
	#		.$self->{block_left}.",".$self->{block_down}
		,
			'stroke-width'	=>"1pt" ,
			'stroke'		=>"black",
		style	=>
		{
	  		'fill'			=>"white",
	  '		fill-opacity'	=>"0",
		}
  	);
=cut

	}

	$self->prepare_axis_x_markArea(front=>1);
	$self->prepare_axis_x_mark(front=>1);
	$self->prepare_axis_y_markArea(front=>1);
	$self->prepare_axis_y_mark(front=>1);


	$self->prepare_axis();

	$self->prepare_legend_label();

 # output 
	$self->{SVG_out}=$self->{SVG}->xmlify
	(
#	-namespace => "svg",
#	-pubid => "-//W3C//DTD SVG 1.0//EN",
		-inline   => 1
	);

	return $self->{SVG_out};
}







