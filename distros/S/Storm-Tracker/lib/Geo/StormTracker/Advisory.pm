package Geo::StormTracker::Advisory;
use Carp;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

#----------------------------------------------------------------------
sub new {
	my $HR={};
	bless $HR,'Geo::StormTracker::Advisory';
	return $HR;
}#new
#---------------------------------------------------------------------
sub stringify {
	my $self=shift;

	my $head=$self->_muck_with_hash('header_string');
	my $body=$self->_muck_with_hash('body_string');

	if (defined($head) and defined($body)){
		return $head."\n".$body;
	}
	else {
		return undef;
	}
}#stringify
#---------------------------------------------------------------------
sub stringify_header {
	my $self=shift;
	my $header_string=shift;

	return $self->_muck_with_hash('header_string',$header_string);
}#stringify_header
#---------------------------------------------------------------------
sub stringify_body {
	my $self=shift;
	my $body_string=shift;

	return $self->_muck_with_hash('body_string',$body_string);
}#stringify_body
#---------------------------------------------------------------------
sub name {
	my $self=shift;
	my $name=shift;

	return $self->_muck_with_hash('name',$name);
}#name
#---------------------------------------------------------------------
sub epoch_date {
	my $self=shift;
	my $epoch_date=shift;

	return $self->_muck_with_hash('epoch_date',$epoch_date);
}#epoch_date
#---------------------------------------------------------------------
sub event_type {
	my $self=shift;
	my $event_type=shift;

	return $self->_muck_with_hash('event_type',$event_type);
}#event_type
#---------------------------------------------------------------------
sub advisory_number {
	my $self=shift;
	my $advisory_number=shift;

	return $self->_muck_with_hash('advisory_number',$advisory_number);
}#advisory_number
#---------------------------------------------------------------------
sub is_final {
	my $self=shift;
	my $is_final=shift;

	return $self->_muck_with_hash('is_final',$is_final);
}#is_final
#---------------------------------------------------------------------
sub release_time {
	my $self=shift;
	my $release_time=shift;

	return $self->_muck_with_hash('release_time',$release_time);
}#release_time
#---------------------------------------------------------------------
sub weather_service {
	my $self=shift;
	my $weather_service=shift;

	return $self->_muck_with_hash('weather_service',$weather_service);
}#weather_service
#---------------------------------------------------------------------
sub position {
	my $self=shift;
	my $position_AR=shift;

	if ((defined $position_AR) and ( ref($position_AR) ne 'ARRAY' )){
		croak "position method expects an array reference when used as an assignment operator!\n";
	}
	
	return $self->_muck_with_hash('position',$position_AR);
}#position
#---------------------------------------------------------------------
sub max_winds {
	my $self=shift;
	my $max_winds=shift;

	return $self->_muck_with_hash('max_winds',$max_winds);
}#max_winds
#---------------------------------------------------------------------
sub min_central_pressure {
	my $self=shift;
	my $min_central_pressure=shift;

	return $self->_muck_with_hash('min_central_pressure',$min_central_pressure);
}#min_central_pressure
#---------------------------------------------------------------------
#sub movement_toward {
#	my $self=shift;
#	my $movement_toward_AR=shift;
#
#	if ((defined $movement_toward_AR) and (ref($movement_toward_AR) ne 'ARRAY')){
#		croak "movement_toward method expects an array reference when used as an assignment operator!\n";
#	}
#
#	return $self->_muck_with_hash('movement_toward',$movement_toward_AR);
#}#movement_toward
#---------------------------------------------------------------------
sub wmo_header {
	my $self=shift;
	my $wmo_header=shift;

	return $self->_muck_with_hash('wmo_header',$wmo_header);
}#wmo_header
#---------------------------------------------------------------------
sub _muck_with_hash {
	my $self=shift;
	my $key=shift;
	my $value=shift;

	#If called as an assignment 
	if (defined($value)){
		$self->{$key}=$value;
		return $self->{$key};
	}
	#Must have been called as a data request
	else {
		if (defined($self->{$key})){
			return $self->{$key};
		}
		else {
			return undef;
		}#if/else
	}#if/else
}#_muck_with_hash
#---------------------------------------------------------------------
1;
__END__

=head1 NAME

Geo::StormTracker::Advisory - The weather advisory object of the perl Storm-Tracker bundle.

=head1 SYNOPSIS

	use Geo::StormTracker::Advisory;

	#Create a new advisory object for holding
	#all the various elements of an advisory.
        $adv_obj=StormTracker::Advisory->new();
      
	#Return the entire advisory as a string.
	#Internally calls stringify_header and
	#stringify_body and joins the result.  
	$adv_obj->stringify(); 
 
All of the following methods can be used as both access and as assignment methods.
The use and functionality of the methods should be obvious.

It is important to realize that changes to a given attribute do not affect other
attributes.  It is the role of the caller to keep the content self consistent. 

	#Obtain the header as a string.
        $header_string=$adv_obj->stringify_header();
       
	#Change the contents of the header string.
	#Returns new header contents. 
	$header_string=$adv_obj->stringify_header($header_string);

	#Obtain the body as a string. 
        $body_string=$adv_obj->stringify_body();

	#Change the contents of the body string.
	#Returns new body contents.
        $body_string=$adv_obj->stringify_body($body_string);

	#Obtain the name string.
        $name=$adv_obj->name();
	
	#Change the name string.
	#Returns new name string.
        $name=$adv_obj->name($name);
	
	#Obtain the wmo header string.
        $wmo_header=$adv_obj->wmo_header();
	
	#Change the wmo header string.
	#Returns new wmo header string.
        $wmo_header=$adv_obj->wmo_header($wmo_header);

	#Obtain the advisory number value.
        $advisory_number=$adv_obj->advisory_number();
	
	#Change the advisory number value.
	#Returns the new advisory number.
        $advisory_number=$adv_obj->advisory_number($advisory_number);
       
	#Obtain the release time string. 
	$release_time=$adv_obj->release_time();

	#Change the release time string.
	#Returns the new release time string.
	$release_time=$adv_obj->release_time($release_time);

	#Obtain the epoch date in seconds. 
	$epoch_date=$adv_obj->epoch_date();

	#Change the epoch date.
	#Returns the new epoch date in seconds.
	$epoch_date=$adv_obj->epoch_date($epoch_date);

	#Obtain the weather service string.
        $weather_service=$adv_obj->weather_service();

	#Change the weather service string.
	#Returns the new weather service string.
        $weather_service=$adv_obj->weather_service($weather_service);

	#Obtain the position array or array reference.
        @position=$adv_obj->position();
	or
	$positon_AR=$adv_obj->position();

	#Change the position array.
	#Returns the new position array or array reference. 
        @position=$adv_obj->position($position_AR);
	or
	$position_AR=$adv_obj->position($position_AR);

	#Obtain the maximum wind value.
        $max_winds=$adv_obj->max_winds($max_winds);
       
	#Change the maximum wind value.
	#Returns the new maximum wind value.
	$max_winds=$adv_obj->max_winds($max_winds);

	#Obtain the minimum central pressure value.
        $min_central_pressure=$adv_obj->min_central_pressure();

	#Change the minimum central pressure value.
	#Returns the new minimum central pressure value. 
        $min_central_pressure=$adv_obj->min_central_pressure($min_central_pressure)

	#Determine whether or not the advisory says it is the last one.
        $is_final=$adv_obj->is_final();

	#Change the is_final value.
	#Returns the new is_final value. 
        $is_final=$adv_obj->min_central_pressure($is_final)


=head1 DESCRIPTION

The Geo::StormTracker::Advisory module is a component of
the Storm-Tracker perl bundle.  The Storm-Tracker perl
bundle is designed to track weather events using the
national weather advisories.  The original intent is to track
tropical depressions, storms and hurricanes.  A
Geo::StormTracker::Advisory object is designed to contain
everything about a single advisory.  The Geo::StormTracker::Advisory
objects are typically created and populated by the read methods of a 
Geo::StormTracker::Parser object.


=head1 CONSTRUCTOR

=cut

=over 4

=item new

Creates a C<Geo::StormTracker::Advisory> object and
returns a blessed reference to it. 

=back

=cut

=head1 METHODS

=cut

=over 4


=item stringify

Returns the entire advisory.  Internally calls stringify_header and
stringify_body and joins the result.


=back


The remaining methods function as both assignment and access methods.
When called with an argument, they act as assignment methods and when called
without an argument they act as access methods.

When successfully called as assignment methods the return value is that of the newly assigned
value. If the assignment is unsuccessful the return value will be undefined.

The attribute set/retrieved is identical to the method name.

=cut

=over 4

=item stringify_header ([STRING])

Returns a string value.

=cut

=item stringify_body ([STRING])

Returns a string value.

=cut
 
=item name ([STRING])

Returns a string value.

=cut

=item wmo_header ([STRING])

Returns a string value.

=cut

=item advisory_number ([VALUE])

Returns a string value.

=cut
 
=item release_time ([STRING])

Returns a string value.

=cut

=item epoch_date ([STRING])

Returns a string value.

=cut

=item weather_service ([STRING])

Returns a string value.

=cut

=item position ([ARRAY_REF])

Returns an array value when called in array context
and an array reference when called in a scalar context.

=cut

=item max_winds ([VALUE])

Returns a string value.

=cut
 
=item min_central_pressure ([VALUE])

Returns a string value.

=cut

=item is_final ([BOOLEAN])

Returns a boolean value.

=cut

=back

=cut

=head1 AUTHOR

James Lee Carpenter, Jimmy.Carpenter@chron.com

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.
 
Thanks to Dr. Paul Ruscher for his assistance in helping me to understand
the weather advisory formats.


=head1 SEE ALSO

	Geo::StormTracker::Main
	Geo::StormTracker::Data
	Geo::StormTracker::Parser
	perl(1).

=cut
