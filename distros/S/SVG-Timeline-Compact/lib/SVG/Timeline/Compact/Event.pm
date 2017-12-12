package SVG::Timeline::Compact::Event;

# ABSTRACT: Event Container for SVG::Timeline::Compact

use DateTime;
use DateTime::Duration;
use v5.10;
use Moose;


has resolution=>(is=>'rw',isa=>'DateTime::Duration');
has id =>(is=>'rw',isa=>'Int');
has origin=>(is=>'rw',isa=>'DateTime');
has start =>(is=>'ro',isa=>'DateTime');
has end=>(is=>'ro',isa=>'DateTime');
has name =>(is=>'ro');
has tooltip =>(is=>'ro');
has color =>(is=>'ro', isa=>"Str");
has min_width =>(is=>'ro',isa=>'Int');
has _start =>(is=>'rw',isa=>'DateTime');
has _width =>(is=>'rw',isa=>'Int');
sub x0{
	my $self=shift;
	return $self->distance($self->origin,$self->start,0);
}
sub width{
	my $self=shift;
	#p $self->start;
	#p $self->end;
	my $width= $self->distance($self->start,$self->end);
	#p $self->resolution;
	#p $width;
	return $width;

}
sub distance {
	my ($self,$start,$end,$minwidth)=@_;
	$minwidth=$self->min_width if !defined $minwidth;
	my $dist=$end -$start;#/$self->resolution ;
	#p $dist; #mon day min  sec
	my $retval=$self->_get_scaled($dist);
		 
	$retval=$minwidth if $retval<$minwidth;
	return $retval;
}
sub _get_scaled{
	my ($self,$distance)=@_;
	my $duration=$self->resolution;
	my $weeks=$distance->in_units('months')*5 +$duration->in_units('weeks');
	my $days=$distance->in_units('months')*30 +$duration->in_units('days');
	my $minutes=$days*24*60+$distance->in_units('minutes');
	#p $minutes;
	my $scale;
	if ($duration->in_units('months')>0){
		$scale=POSIX::ceil($duration->in_units('months'));
		return $distance->in_units('months')/$scale;
	}elsif ($duration->in_units('days')>0){
		$scale=POSIX::ceil($duration->in_units('days'));
		return $days/$scale;
	}elsif ($duration->in_units('minutes')>0){
		$scale=POSIX::ceil($duration->in_units('minutes'));
		return $minutes/$scale;
	}else{
	print STDERR "Error Parsing Duration";
	return $0;
	}
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SVG::Timeline::Compact::Event - Event Container for SVG::Timeline::Compact

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This module should not be called by the user. It is for internal use of SVG::Timeline::Compact.

=head1 METHODS

=head2 new

=over 4

=item id Optional, Event ID.

=item start Required, DateTime Object representing the Start Time.

=item end Required, DateTime Object representing the End Time.

=item name Required, Event Name.

=item tooltip Optional, Event Tooltip.

=item color, Optional, The RGB value for filling the rectangle representing the event.

=back

=head1 AUTHOR

Vijayvithal <jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
