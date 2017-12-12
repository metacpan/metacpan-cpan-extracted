package SVG::Timeline::Compact;

# ABSTRACT: A Moose based SVG Timeline drawing class.

use Moose;
use SVG::Timeline::Compact::Event;
use SVG;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;
use POSIX ;

use v5.10;
use namespace::clean;

 


has _events =>(is=>'ro',isa =>'ArrayRef[SVG::Timeline::Compact::Event]',traits=>['Array'],handles=>{ev_push=>'push',ev_all=>'elements'});
has _min=>(is=>'rw',isa =>'DateTime');
has _max=>(is=>'rw',isa =>'DateTime');
has _resolution=>(is=>'rw',isa=>'DateTime::Duration',default=>sub {  DateTime::Duration->new(days=>1); });
has min_width=>(is=>'ro',isa=>'Int',default=>1);
has min_height=>(is=>'ro',isa=>'Int',default=>20); # Each Bar is 20 pixels high
has units=>(is=>'ro',isa=>'Int',default=>800);
1;


sub add_event {
	my ($self,%hsh)=@_;
	if (not defined $self->_min or DateTime->compare($self->_min,$hsh{start})>0 ) {$self->_min($hsh{start});}
	if (not defined $self->_max or DateTime->compare($self->_max,$hsh{end})<0 ) {$self->_max($hsh{end});}
	$hsh{min_width}=$self->min_width;
	my $ev=SVG::Timeline::Compact::Event->new( %hsh);
	$self->ev_push($ev);
}

sub layout {
	my $self=shift;
	my @slot;
	$self->_set_resolution();
	foreach my $event (sort _byStart $self->ev_all){
		my $found=0;
		$event->resolution($self->_resolution);
		$event->origin($self->_min);
		for my $slot(0..$#slot){
			my $evslot=$slot[$slot];
			my $head=pop @{$evslot};if ($head){push @{$evslot}, $head;}
			if ($head->x0+$head->width <$event->x0){
				push @{$evslot},$event;
				$found=1;
				last;

			}
		}

		if ($found==0){
			my $newslot=[$event];
			unshift @slot,$newslot;
		}
	}
	return @slot;
}

sub to_ds {
	my $self=shift;
	my @slot=$self->layout;
	my @ds;
	my ($y0,$y1,$x0,$maxX)=(0,1.5,0,0);
	my $fmt="yyyy-MM-dd hh:mm";
	foreach my $slot (@slot){
		foreach my $ev (@{$slot}){
			push @ds,{idchangeset=>$ev->id,count=>$ev->name,name=>$ev->tooltip,created=>$ev->start->format_cldr($fmt),
				x=>$ev->x0,y=>$y0,width=>$ev->width,height=>$y1, status=>$ev->color};
			$maxX=$ev->x0+$ev->width	if ($maxX<$ev->x0+$ev->width);
		}
		$y0+=1.5*$y1;
	}
	return {resolution=>$self->_resolution,start=>$self->_min->format_cldr($fmt),end=>$self->_max->format_cldr($fmt),maxX=>$maxX,maxY=>$y0,ds=>\@ds}
}


sub to_svg{
	my $self=shift;
	my @slot=$self->layout;
	my $svg=SVG->new();
        my $d = DateTime::Format::Duration->new( pattern => '%Y years, %m months, %e days, '.  '%H hours, %M minutes, %S seconds');
	my $bbox=$svg->group(id=>"bbox");
	my $bars=$svg->group(id=>"bars");
        my $def=$svg->defs(id=>"arrow","stroke-linecap"=>"round","stroke-width"=>"1");
        $def->line(x1=>"-8",y1=>"-4",x2=>"1",y2=>"0");
        $def->line(x1=>"1",y1=>"0",x2=>"-8",y2=>"4");
	my ($y0,$y1,$x0,$maxX)=(0,$self->min_height,0,0);
	foreach my $slot (@slot){
		#p @slot;
		foreach my $ev (@{$slot}){
			#p $ev;
			$x0=$ev->x0;
			my $width=$ev->width;
			my $color=$ev->color;
			my $rect=$bars->rect(x=>$x0."px",y=>$y0."px",width=>$width."px",height=>$y1."px", fill=>$color,stroke=>"#000");
			$bars->text(x=>$x0+$width/2,y=>($y0-2+$self->min_height),"text-anchor"=>"middle")->cdata($ev->name);
				$rect->title->cdata($ev->tooltip.", Start: ". $ev->start.", End ". $ev->end);
			$maxX=$x0+$width	if ($maxX<$x0+$width);
		}
		$y0+=$y1*1.5;

	}
	#$y0+=$y1*1.5;
        $maxX=$self->units if($maxX<$self->units);
	my $border=$bbox->rect(x=>0,"fill-opacity"=>"0.1",y=>0,width=>$maxX."px",height=>$y0."px");
	my $x=0 ;
        my$dim=$bbox->group(id=>"dim");
	$dim->line(x1=>0,y1=>($y0+$self->min_height),x2=>800,y2=>($y0+$self->min_height));
	$dim->use("xlink:href"=>"#arrow",x=>0,y=>($y0+$self->min_height));
	$dim->use("xlink:href"=>"#arrow",x=>800,y=>($y0+$self->min_height));
	#$dim->text(x=>$maxX/2,y=>($y0+$self->min_height),"text-anchor"=>"middle")->cdata("<-------------- ". $self->_resolution. " --------------->");
        #<use stroke="#000000" xlink:href="#ah" transform="translate(354.4 119.4)rotate(90)"/>
	$bbox->text(x=>$maxX+10,y=>$self->min_height)->cdata("Min:\t".$self->_min->format_cldr("yyyy/MM/dd h:m"));
	$bbox->text(x=>$maxX+10,y=>2*$self->min_height)->cdata("Max:\t".$self->_max->format_cldr("yyyy/MM/dd h:m"));

	my $unit;
	$unit= $self->_resolution->in_units('months')." Months" if ($self->_resolution->in_units('months')>0);
	$unit= $self->_resolution->in_units('days')." Days" if ($self->_resolution->in_units('days')>0);
	$unit= $self->_resolution->in_units('minutes')." Minutes" if ($self->_resolution->in_units('minutes')>0);
	$bbox->text(x=>$maxX+10,y=>3*$self->min_height)->cdata("Scale:\t ".$unit);
	while($x<=$maxX){
		if($x%100 == 0){
		$bbox->line(x1=>$x,x2=>$x,y1=>$y0,y2=>0 ,style=>"stroke:#000;stroke-width:1px" );
		$dim->text(x=>$x,y=>($y0+$self->min_height),"text-anchor"=>"middle")->cdata("$x");
	}else{
		$bbox->line(x1=>$x,x2=>$x,y1=>$y0,y2=>0 ,style=>"stroke:#fff;stroke-width:1px" );
	}
		$x=$x+10;

	}
	return $svg->xmlify;
}
sub _set_resolution{
	#We desire that atleast 50% of the graph is utilized. and we do not overflow.
	#minutes up to 800 minutes
	my $self=shift;
	my $scale=get_scale($self->_min,$self->_max);
	$self->_resolution($scale);
}
sub get_scale{
	my ($min,$max)=@_;
	my $duration=$max-$min;
	my $days=$duration->in_units('months')*30 +$duration->in_units('days');
	my $hours=$days*24+$duration->in_units('hours');
	my $minutes=$hours*60+$duration->in_units('minutes');
	my $scale;
	#p $minutes;
	if ($duration->in_units('months')>300){
		$scale=DateTime::Duration->new(months=>POSIX::ceil($duration->in_units('months')/800));
	}elsif ($days>300){
		$scale=DateTime::Duration->new(days=>POSIX::ceil($days/800));
	}elsif ($hours>300){
		$scale=DateTime::Duration->new(hours=>POSIX::ceil($hours/800));
	}else{
		$scale=DateTime::Duration->new(minutes=>POSIX::ceil($minutes/800));
	}
	return $scale;
}
sub _byStart {
	return DateTime->compare($a->start,$b->start);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SVG::Timeline::Compact - A Moose based SVG Timeline drawing class.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use SVG::Timeline::Compact;
 use DateTime::Format::Natural;

 my $svg=SVG::Timeline::Compact->new();

 my $parser = DateTime::Format::Natural->new;
 my $start=$parser->parse_datetime("12pm");
 my $end=$parser->parse_datetime("1pm");

 $svg->add_event(
		start=>$start,
		end=>$end,
		name=>"Event 1",
		tooltip=>"First Event of the example",
		color=>"#ff00ff"
);

 $start=$parser->parse_datetime("12:45pm");
 $end=$parser->parse_datetime("1:20pm");

 $svg->add_event(
		start=>$start,
		end=>$end,
		name=>"Event 2",
		tooltip=>"Second Event of the example",
		color=>"#ff000f"
);

 $start=$parser->parse_datetime("3:00pm");
 $end=$parser->parse_datetime("5:20pm");

 $svg->add_event(
		start=>$start,
		end=>$end,
		name=>"Event 3",
		tooltip=>"Third Event of the example",
		color=>"#fff00f"
);

 open my $fh,">","test.svg" or die "unable to open test.svg for writing";
 print $fh $svg->to_svg;

=head1 DESCRIPTION

This module originated because L<SVG::Timeline> did not meet my requirements.

The major difference with L<SVG::Timeline> are as follows

=over 4

=item *

Start and End are actual L<DateTime> Objects.

=item *

Auto-calculation of timescale ( min, hours, days, months, years ) based on the events and grid size.

=item *

Auto Layout to fit multiple events on same row.

=item *

Tooltips.

=back

=head1 METHODS

=head2 new
 Creates a new SVG::Timeline::Compact Object.

Takes the following parameters:

=over 4

=item min_width:

 Default 1, If the event duration is less then min_width then the resultant bar in the graph is made equal to min_width e.g. if start==end then instead of drawing an event with width 0, an event 1 px width is drawn.

=item min_height:

 Default 20, The height of the bar, This assumes that our text is 12 px high.

=item units:

 Default 800, The width of the drawing area in px. 

=back

=head2 add_event

 Takes a hash corresponding to L<SVG::Timeline::Compact::Event> and adds it to the event list.

The hash fields are:

=over 4

=item id:

 Optional, Event ID.

=item start:

 Required, DateTime Object representing the Start Time.

=item end:

 Required, DateTime Object representing the End Time.

=item name:

 Required, Event Name.

=item tooltip:

 Optional, Event Tooltip.

=item color:

 Optional, The RGB value for filling the rectangle representing the event.

=back

=head2 to_svg
 Performs an autolayout of all the added events and returns the resultant SVG as a string.

=for html 		<img src="https://raw.githubusercontent.com/jahagirdar/SVG-Timeline-Compact/master/test.svg?sanitize=true" width ="1000">

=head1

=head1 AUTHOR

Vijayvithal <jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
