package SVGraph::Core;

1;

package SVGraph;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

SVGraph::Core

=head1 DESCRIPTION

Library that generates cool SVG graphs

=cut

BEGIN
{
	# allow to log events when function is available
	eval{main::_log("<={LIB} ".__PACKAGE__);};
	if ($@)
	{
		eval "package main; sub _log{}";
	}
}

=head1 DEPENDS

libraries:

	SVG
	SVGraph::columns
	SVGraph::colors

=cut

use SVGraph::columns;
use SVGraph::colors;
use SVG;


sub GetAVG
{
	my $self=shift; 
	my ($num,$all);
	
	foreach (keys %{$self->{row}{labelH}})
	{
		if ($self->GetRowAVG($_))
		{
			$num+=$self->GetRowAVG($_);
			$all++;
		}
	}

	return 0 unless $all;
	return $num/$all;
}


sub GetMax
{
	my $self=shift; 
	my $max;

	foreach (keys %{$self->{row}{labelH}})
	{
		$max=$self->GetRowMax($_) if $max<$self->GetRowMax($_);
	}

	return $max;
}


sub GetMaxSum
{
	my $self=shift; 
	my $max;

	foreach (keys %{$self->{row}{labelH}})
	{
		$max=$self->GetRowSum($_) if $max<$self->GetRowSum($_);
	}

	return $max;
}


sub GetMin
{
	my $self=shift; 
	my $min;

	foreach (keys %{$self->{row}{labelH}})
	{
		my $rowmin=$self->GetRowMin($_);
		next unless defined $rowmin;
		$min=$rowmin if ($min>$rowmin || !$min);
	}

	return undef unless defined $min;
	return $min;
}




#
# count of rows added trought addRowLabel, other rows are not counted
#
sub GetNumRows
{
	my $self=shift;
	
	return undef unless $self->{row}{label};
	
	return @{$self->{row}{label}};
}

#
# count of columns
#
sub GetNumColumns
{
	my $self=shift;
	my $null;
 
	foreach (keys %{$self->{columns}})
	{
		$null++;
	}
	
	return $null;
}

#
# number of added row by label
#
sub GetNumRow
{
	my ($self,$var)=@_;
	
	die "In this chart is none row! " unless $self->{row}{label};
	my $null;
	
	foreach (@{$self->{row}{label}}){return $null if $_ eq $var;$null++;} 
	main::_log("row with label='$var' not exist!",1);
	return undef;
}

#
# sum of the values of all columns in one row
#
sub GetRowSum
{
	my $self=shift; 
	my $label=shift;
	my $num;

	foreach (keys %{$self->{columns}}){$num+=$self->{columns}{$_}->{data}{$label};}
	
	return $num;
}

#
# average value from all columns in one row
#
sub GetRowAVG
{
	my $self=shift; 
	my $label=shift;
	my $num;
	my $null;

	foreach (keys %{$self->{columns}})
	{
		if (exists $self->{columns}{$_}->{data}{$label})
		{
			$num+=$self->{columns}{$_}->{data}{$label};$null++;
		}
	}
	
	return undef unless $null;
	return $num/$null;
}

#
# maximal value from all columns in one row
#
sub GetRowMax
{
	my $self=shift; 
	my $label=shift;
	my $max;

	foreach (keys %{$self->{columns}})
	{
		$max=$self->{columns}{$_}->{data}{$label} if $max<$self->{columns}{$_}->{data}{$label};
	}
	
	return $max;
}

#
# minimal value from all columns in one row
#
sub GetRowMin
{
	my $self=shift;
	my $label=shift;
	my $min;

	foreach (keys %{$self->{columns}})
	{
		next unless defined $self->{columns}{$_}->{data}{$label};
		$min=$self->{columns}{$_}->{data}{$label} if ($min>$self->{columns}{$_}->{data}{$label} || !$min);
	}

	return undef unless defined $min;
	return $min;
}



sub addRowLabel
{
	my ($self,$null)=@_;

	return undef if $self->{row}{labelH}{$null};

	$self->{row}{labelH}{$null}=1;
	push @{$self->{row}{label}},$null;

	return 1;
}




sub addRowMark
{
	my ($self,$null,%env)=@_;

	%{$self->{row}{markH}{$null}}=%env;
	print "mam $null $env{front}\n";

	return 1;
}

sub addRowMarkArea
{
	my ($self,$null,%env)=@_;
  
	if (!$null)
	{
		$null="_start";
	} 
 
	%{$self->{row}{markAH}{$null}}=%env;

	return 1;
}

sub addValueMark
{
	my ($self,$null,%env)=@_;
	
	%{$self->{ValueMarkH}{$null}}=%env;
	
	return 1;
}

sub addValueMarkArea
{
	my ($self,$null,%env)=@_; 
	
	if (!$null)
	{
		$null="_start";
	}

	%{$self->{ValueMarkAH}{$null}}=%env;
 
	return 1;
}





#
# PREPARING THE COLORS OF THE COLUMNS
#
sub prepare_columns
{
	my $self=shift;
 
	# color control
	
	foreach (@{$self->{columnsA}})
	{
		next unless $self->{columns}{$_}->{ENV}{color};
		
		# if there is no color in the table, we delete it
		# or if there is a column, which uses this color
		
		if (!$SVGraph::colors::table{$self->{'columns'}{$_}->{'ENV'}{'color'}} ||
		   $self->{'colors_used'}{$self->{'columns'}{$_}->{'ENV'}{'color'}})
		{
			delete $self->{'columns'}{$_}->{'ENV'}{'color'};next;
		}
		$self->{'colors_used'}{$self->{'columns'}{$_}->{'ENV'}{'color'}}=1;
	}
 
	
	# color assigning to columns which have not assigned any color
	
	foreach (@{$self->{columnsA}})
	{
		next if $self->{columns}{$_}->{ENV}{color};
		reass:
		foreach my $color(@SVGraph::colors::table_C)
		{
			next if $self->{colors_used}{$color};
			$self->{colors_used}{$color}=1;
			$self->{columns}{$_}->{ENV}{color}=$color;
			last;
		}
		if (!$self->{columns}{$_}->{ENV}{color})
		{
			# color table reassing;
			delete $self->{colors_used};
			goto reass;
		}
	}
	
}





# TITLE
sub prepare_title
{
	my $self=shift;
	
	my $font_size=calc_fontsize(
		$self->{block_up},
		s_from => 10,
		s_to => 100,
		o_from => 6,
		o_to => 25
	);
	
	main::_log("title: $self->{block_up} = $font_size");
	
	$self->{SVG}->text
	(
		x=>$self->{block_left},
		y=>int(($self->{block_up}*0.33)+($font_size/2)),
        	style => {
			'font-family'	=> 'Verdana',
			'font-size'	=> $font_size.'px',
			'font-weight'=> "900",
			'fill'		=> $self->{'ENV'}{'title.color'} || "black",
#			'fill-opacity'=>(0.5+0.5*rand()),
#			'fill'=>"$colour_map[$index]",
#			'stroke'=>"#808080"
		},	
	)->cdata($self->{ENV}{title}) if $self->{ENV}{title};

	return 1;
}





sub prepare_legend
{
	my $self=shift; 
	
	return undef unless $self->{ENV}{show_legend};
 
	my $count;
	foreach (keys %{$self->{columns}}){$count++};
 
=cut
 my $block=$self->{SVG}->polyline(
	points	=>	
		($self->{ENV}{x}).",".$self->{block_up}." ".
		($self->{block_right}+10).",".$self->{block_up}." ".
		($self->{block_right}+10).",".($self->{block_up}+(20*$count))." ".
		($self->{ENV}{x}).",".($self->{block_up}+(20*$count))." ",
	'stroke-width'	=>"0.5pt" ,
	'stroke'		=>"rgb(150,150,150)",
	'fill'			=>"rgb(240,240,240)",
	'fill-opacity'	=>"0.7",
	'stroke-linecap'	=>"round",
	'stroke-linejoin'	=>"round",
 ); 
=cut

	my $count;
	my $freq=20;
 #foreach (keys %{$self->{columns}})
 #@{$self->{columnsA}} = reverse @{$self->{columnsA}};
 
 
	if ($self->{ENV}{show_legend_reverse})
	{
		@{$self->{columnsA}} = reverse @{$self->{columnsA}};
	}
 
	foreach (@{$self->{columnsA}})
	{
		my $color=$self->{columns}->{$_}{ENV}{color};
		my %colors=%{$SVGraph::colors::table{$color}};  
		$count++;
 
		my $width=(($self->{ENV}{x}-$self->{block_right})*0.07);
		#my $height=int(($self->{ENV}{x}-$self->{block_right})*0.05);
		my $height=($self->{ENV}{y}*0.03);
		my $x=($self->{block_right}+(($self->{ENV}{x}-$self->{block_right})*0.15));
 
		$self->{SVG}->rect(
			x=>int($x),
			y=>int($self->{block_up}+($count*($height*1.7)-$height)),
			rx=>"2pt",
			ry=>"2pt",
			width=>$width,
			height=>$height,
			'stroke-width'	=>"1pt" ,
			'stroke'       =>"rgb(0,0,0)",
			'fill'         =>"rgb(".$colors{N0}.")",
			'stroke-linecap'	=>"round",
			'stroke-linejoin'	=>"round",
		);
		
		
		my $font_size=calc_fontsize(
			$self->{ENV}{y},
			s_from => 100,
			s_to => 500,
			o_from => 6,
			o_to => 13
		);
		
		$self->{SVG}->text
		(
			x=>int($x+($width*1.5)),
			y=>int($self->{block_up}+($count*($height*1.7)-$height)+($font_size/2)+($height/4)),
			style =>
			{
				'text-anchor'	=>	'start',
				'font-family'	=> 'Verdana',
				'font-size'	=> $font_size.'px',
				'font-weight'	=> "600",
				'fill'		=> "black",
			},
		)->cdata($_);
	
	}
 
 
	if ($self->{ENV}{show_legend_reverse})
	{
		@{$self->{columnsA}} = reverse @{$self->{columnsA}};
	}
 
	return 1;
}







#
# adding columns to the graph
#
sub addColumn
{
	my ($self,%env)=@_; 

	return undef if $self->{columns}{$env{title}};	

	$self->{columns}{$env{title}}=new SVGraph::columns(%env);
	push @{$self->{columnsA}},$env{title};

	return ($self->{columns}{$env{title}});
}










#
# CALCULATION OF THE RANGE
#


sub CalculateMinMax
{
	my($self,$minimal,$maximal,$div_min,$div_max)=@_;
	my $log=0;
	my $scale=$maximal-$minimal;
	# my $div_min=9;
	# my $div_max=15;
	# my $minimal=0;
	# my $maximal=849;
	my $what; # min/max;
	
	print "<=$minimal $maximal ($scale)\n" if $log;
	
	
	#my $number=$maximal;$what="max";
	#if ((-$minimal)>$maximal){$number=(-$minimal);$what="min"}
	
	my $number=$scale;
	
	print "<=$number\n" if $log;
	
	#=head1
	
	my $del=1;

	while ($number>100)
	{
		$number=$number/10;
		$del=$del/10;
	}
	while ($number<10)
	{
		$number=$number*10;
		$del=$del*10;
	}
	
	print "\t$number / $del (presun na 2 desatinne miesta)\n" if $log;
	
	my $number2=$number;

	if ($number2!=int($number2)){$number2=int($number2+1);}
	
	print "\t$number2 (zaokruhlenie nahor)\n" if $log;
	print "\tprocessing...\n" if $log;

	my $cislo;
	my %hash;
	
	
	for my $plus(0..10)
	{
		$cislo=$number2+$plus;
		print "\t$cislo\n" if $log;
		for my $delitel($div_min..$div_max)
		{
			next if $cislo/$delitel != int($cislo/$delitel);
			print "\t\tdelitelne $delitel\n" if $log;
			$hash{$cislo}{$delitel}=$plus;
			for my $test(0..$delitel)
			{
				my $out=($cislo*((1/$delitel)*($delitel-$test)));
				
				print "\t\t\t".$out."\t" if $log;
				
				while($out=~s|0$||){$hash{$cislo}{$delitel}--};
				if($out=~/5$/){$hash{$cislo}{$delitel}-=0.5};
				
				print $out."\n" if $log;
				$hash{$cislo}{$delitel}+=(length($out)*1);
			}
		}
	}

	print "\tcalculating\n" if $log;

	my ($del0,$cis0,$min0);

	foreach my $cislo(keys %hash)
	{
		foreach my $delitel(keys %{$hash{$cislo}})
		{
			print "\t\t$cislo / $delitel $hash{$cislo}{$delitel} \n " if $log;

			if ($min0>$hash{$cislo}{$delitel} || !$min0)
			{
				$del0=$delitel;
				$cis0=$cislo;
				$min0=$hash{$cislo}{$delitel};
			}
		}
	}

	my ($minimal0,$maximal0);
	
	print "\tnormalizing\n" if $log;
	print "\t\not localize color at SVGraph.pm line t$cis0 $del0 (best selected)\n" if $log;
	
	$scale=$cis0/$del;
	print "\t\t".($scale)." $del0 (scale returned from 2 digits to normal)\n" if $log;
	
	my $div=$scale/$del0;
	print "\t\t".($div)." (divider)\n" if $log;
	
	print "\t\t$minimal (minimal to normalization)\n" if $log;
	
	if ((int($minimal/$div) > ($minimal/$div)) && ($minimal<0))
	{
		print "som tu\n" if $log;
		$minimal0=(int($minimal/$div)-1)*$div;
	}
	else
	{
#		print "int($minimal/$div)*$div\n";
		$minimal0=int($minimal/$div)*$div;
#		$minimal0=$minimal;
	}
 
 
	print "\t\t$minimal0 (normalized minimal)\n" if $log;
	
 
	print "\t\t$maximal (maximal to normalization)\n" if $log;
	if ((int($maximal/$div) < ($maximal/$div)) && ($maximal>0))
	{
		$maximal0=(int($maximal/$div)+1)*$div;
	}
	else
	{
		$maximal0=int($maximal/$div)*$div;
	}
	
	print "\t\t$maximal0 (normalized maximal)\n" if $log;
	
#	$minimal0=$minimal;
#	$maximal0=$maximal;
	
	my $del1=($maximal0-$minimal0)/$div;$del1.="";
	#my $del1=int((0.75-0.54)/0.03);
	#print "($maximal0-$minimal0)/$div\n";
	
	print "\t\t$del1 (normalized lines)\n" if $log;
	
	print "\t\t".($maximal0-$minimal)." (rozdiel)\n" if $log;
	
	
	print "\toutput\n" if $log;
	print "\t\t$maximal0 (maximal)\n" if $log;
	print "\t\t$minimal0 (minimal)\n" if $log;
	print "\t\t$del1 (divider)\n" if $log;
 
	return ($minimal0,$maximal0,$del1);
}



sub calc_fontsize
{
	my $height=shift;
	my %env=@_;
	
	my $pi=3.1415689;
	
	# rozsah velkosti grafu
	my $s_from=$env{'s_from'} || 10;
	my $s_to=$env{'s_to'} || 100;
	
	# rozsah velkosti pisma
	my $o_from=$env{'o_from'} || 6;
	my $o_to=$env{'o_to'} || 25;
	
	my $rel=($height-$s_from)/($s_to-$s_from);
	my $quadrant=($pi/2)*$rel;
	my $cc=int(cos(($pi/2)*3+$quadrant)*1000)/1000;
	my $size=int($o_from+($cc*($o_to-$o_from)));
#	print "$height=$size\n";
	
	return $size;
}


sub save
{
	my $self=shift;
	my $filename=shift;
	
	open (SVG,">".$filename);
	print SVG $self->prepare();
	close (SVG);
	return 1;
}


1;
