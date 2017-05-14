package Geo::StormTracker::Parser;
use strict;
use Carp;
use Time::Local;
use vars qw($VERSION @ISA);
use Geo::StormTracker::Advisory;

$VERSION = '0.02';

#-------------------------------------------------------------
sub new {
	my $HR={};
	bless $HR,'Geo::StormTracker::Parser';
	return $HR;
}#new
#-------------------------------------------------------------
sub read {
	my $self=shift;
	my $fh=shift;

	my @all_lines=<$fh>;
	my $advisory=join('',@all_lines);

	return $self->read_data($advisory);
}#read
#--------------------------------------------------------------
sub read_file {
	my $self=shift;
	my $filename=shift;

	my ($io,$file,$adv_obj,$msg)=undef;

	$io=IO::File->new();
	unless ($io->open("<$filename")){
		$msg="Couldn't open file $filename for reading!";
		carp $msg, "\n";
		return undef;
	}

	$adv_obj=$self->read_data(join('',($io->getlines)));

	return $adv_obj;
}#read_file
#--------------------------------------------------------------
sub read_data {
	my $self=shift;
	my $data=shift;

	my ($head,$body)=undef;
	
	my $adv_obj=Geo::StormTracker::Advisory->new();
	
	$head=$self->_extract_head($data);
	$adv_obj->stringify_header($head);
	
	$body=$self->_extract_body($data);
	$adv_obj->stringify_body($body);
	
	$adv_obj=$self->_grab_head_information($adv_obj,$head);
	
	$adv_obj=$self->_grab_body_information($adv_obj,$body);

	return $adv_obj;
}#read_data
#---------------------------------------------------------------
sub _extract_head {
	my $self=shift;
	my $advisory=shift;

	$advisory =~ s!^[\s*\n]*!!is;
        $advisory =~ m!^(([^\n]*\n){7})!is;

	return $1;
}#_extract_head
#---------------------------------------------------------------
sub _extract_body {
	my $self=shift;
	my $advisory=shift;

	$advisory =~ s!^[\s*\n]*!!is;
        $advisory =~ s!^(([^\n]*\n){7})!!is;
        $advisory =~ s!^[\s*\n]*!!is;
        $advisory =~ s!\n[\s*\n]*$!\n!is;
 
        return $advisory;
}#_extract_body
#---------------------------------------------------------------
sub _grab_head_information{
	my $self=shift;
	my $adv_obj=shift;
	my $head=shift;

	my ($name, $advisory_number, $epoch_date)=undef;

	my @head=split("\n",$head);
	chomp(@head);

	$adv_obj->wmo_header($head[1]);

	#$head[4] =~ m!(^.*\S)\s+ADVISORY!;
	$head[4] =~ m!(^.*?\S)(\s+INTERMEDIATE)?\s+ADVISORY!i;
	$name=$1;
	$adv_obj->name($name);

	if ($name =~ m!^TROPICAL DEPRESSION!is){
		$adv_obj->event_type('TROPICAL DEPRESSION');
	}
	elsif ($name =~ m!^TROPICAL STORM!is){
		$adv_obj->event_type('TROPICAL STORM');
	}
	elsif ($name =~ m!^HURRICANE!is){
		$adv_obj->event_type('HURRICANE');
	}
	else {
		$adv_obj->event_type('OTHER');
	}

	#The advisory number occasionally has a letter as its last character.
	$head[4] =~ m!^.*ADVISORY\s+NUMBER\s+(\d+)([A-Za-z]?)\s*$!i;

	$advisory_number=$1;
	if ($2){
		$advisory_number .= uc $2; #make sure letter is upper cased
	}#if

	$adv_obj->advisory_number($advisory_number);
	
	$adv_obj->weather_service($head[5]);

	$adv_obj->release_time($head[6]);

	$epoch_date=$self->_extract_epoch_date($head[6]);

	$adv_obj->epoch_date($epoch_date);

	return $adv_obj;

}#_grab_head_information
#---------------------------------------------------------------
sub _extract_epoch_date {
        my $self=shift;
        my $release_time=shift;
 
        my ($match, $month,$mon,$mday,$year, $time)=undef;
 
        return undef unless (defined $release_time);
        
	my %month_hash=(
                        'JAN'=>0,
                        'FEB'=>1,
                        'MAR'=>2,
                        'APR'=>3,
                        'MAY'=>4,
                        'JUN'=>5,
                        'JUL'=>6,
                        'AUG'=>7,
                        'SEP'=>8,
                        'OCT'=>9,
                        'NOV'=>10,
                        'DEC'=>11,
                        );
 
        $match=($release_time =~ m!\s(\w{3})\s+(\d+)\s+(\d{4})$!i);
 
        if ($match){
                $month=$1;
                $mday=$2;
                $year=$3;
 
                $mon=$month_hash{(uc $month)};
 
                #$time = timegm($sec,$min,$hours,$mday,$mon,$year);
                $time = timegm(0,0,0,$mday,$mon,$year);
 
                return $time;
        }
        else {
                return undef;
        }#if/else
}#_extract_epoch_date
#---------------------------------------------------------------
sub _grab_body_information{
        my $self=shift;
        my $adv_obj=shift;
        my $body=shift;

        my ($success,$repeating,$lat_digit,$lat_dir,$long_digit,$long_dir)=undef;
        my ($min_central_pressure,$matches,$max_winds,$movement_toward_dir,$movement_toward_speed)=undef;
 
        $success = ($body =~ m!\n(REPEATING[^\n]*\n(\S[^\n]+\n)+)!is);
 
        #If repeating block was found
        if ($success) {
                $repeating=$1;
 
                #going after position
                $matches=($repeating =~ m!POSITION\s{0,5}\.{0,5}\s{0,5}(\d+\.\d+)\s{0,3}([NS])\s{0,5}\.{0,5}\s{0,5}(\d+\.\d+)\s{0,3}([WE])[\s\.]!is);
                if ($matches){
                        $lat_digit=$1;
                        $lat_dir=$2;
                        $long_digit=$3;
                        $long_dir=$4;
			$adv_obj->position([$lat_digit,$lat_dir,$long_digit,$long_dir]);
                }
 
                #going after minimum central pressure
                $matches=($repeating =~ m!MINIMUM[\s\n]+CENTRAL[\s\n]+PRESSURE\s{0,5}\.{0,5}\s{0,5}(\d+)\s+MB!is);
                if ($matches){
                        $adv_obj->min_central_pressure($1);
                }
 
                #going after maximum sustained winds
                $matches=($repeating =~ m!MAXIMUM[\s\n]+SUSTAINED[\s\n]+WINDS\s{0,5}\.{0,5}\s{0,5}(\d+)\s+MPH!is);
                if ($matches){
                        $adv_obj->max_winds($1);
                }
 
#                #going after movement toward
#                $matches=($repeating =~ m!MOVEMENT[\s\n]+TOWARD\s{0,5}\.{0,5}\s{0,5}(\S+)[\n\s]+(\d+)\s+MPH!is);
#                if ($matches){
#                        $movement_toward_dir=$1;
#                        $movement_toward_speed=$2;
#			$adv_obj->movement_toward([$movement_toward_speed,$movement_toward_dir]);
#                }
        }
        #If repeating block was not found then
        #look for the information elsewhere in the body.
        else {
                #going after position
                $matches=($body =~ m!LATITUDE[^\d]{1,10}(\d+\.\d+)[\s\n]+(NORTH|N|SOUTH|S)!is);
                if ($matches){
                        $lat_digit=$1;
                        $lat_dir=substr($2,0,1);
                }#if
                $matches=($body =~ m!LONGITUDE[^\d]{1,10}(\d+\.\d+)[\s\n]+(WEST|W|EAST|E)!is);
                if ($matches){
                        $long_digit=$1;
                        $long_dir=substr($2,0,1);
                }#if
		$adv_obj->position([$lat_digit,$lat_dir,$long_digit,$long_dir]);

                #going after minimum central pressure
                $matches=($body =~ m!MINIMUM[\s\n]+CENTRAL[\s\n]+PRESSURE[^\d]{0,10}(\d+)\s+MB!is);
                if ($matches){
                        $adv_obj->min_central_pressure($1);
                }
 
                #going after maximum sustained winds   
                $matches=($body =~ m!MAXIMUM[\s\n]+SUSTAINED[\s\n]+WINDS[^\d]{0,20}(\d+)\s+MPH!is);
                if ($matches){
                        $adv_obj->max_winds($1);
                }
 
#                #going after movement toward
#                $matches=($body =~ m!MOVING[\s\n]+([\S\n]+)[^\d]{0,20}(\d+)\s+MPH!is);
#                if ($matches){
#                        $movement_toward_dir=$1;
#                        $movement_toward_speed=$2;
#                        $movement_toward_dir =~ s!\n!!igs;
#			$adv_obj->movement_toward([$movement_toward_speed,$movement_toward_dir]);
#                }
 
        }#if/else

	#going after a final advisory notice.
	$matches=($body =~ m!THIS\s*[\s\n]WILL\s*[\s\n]BE\s*[\s\n]THE\s*[\s\n]LAST\s*[\s\n]PUBLIC\s*[\s\n]ADVISORY!is);
	if ($matches){
		$adv_obj->is_final(1);
	}	
	else {
		$adv_obj->is_final(0);
	}

	return $adv_obj; #Wasn't that painfull

}#_grab_body_information
#---------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::StormTracker::Parser - Perl extension for Parsing Weather Advisories 

=head1 SYNOPSIS

	use Geo::StormTracker::Parser;

	#Create a parser object
	$parser_obj=Geo::StormTracker::Parser->new();

	#Parse input and return a Geo::StormTracker::Advisory object.
	$adv_obj=$parser_obj->read(\*STDIN);
	
	#An alternative to the read method above,
	#which accepts the advisory as a string.
	$adv_obj=$parser_obj->read_data($advisory_data); 

	#Same as above two methods but reads from a file instead.
	$adv_obj=$parser_obj->read_file($advisory_data); 


=head1 DESCRIPTION

The Geo::StormTracker::Parser module is a component
of the Storm-Tracker perl bundle.  The Storm-Tracker perl
bundle is designed to track weather events using the
national weather advisories.  The original intent is to track
tropical depressions, storms and hurricanes.  The various
read methods of Geo::StormTracker::Parser take a plain
text advisory as input and return Geo::StormTracker::Advisory
objects.

=head1 CONSTRUCTOR

=over 4

=item new

Creates a new instance of a Geo::StormTracker::Parser object and
returns a blessed reference to it.

=back

=head1 METHODS

=over 4

=item read (TYPEGLOB_REF)

Reads from the type glob reference passed as an argument and returns
a Geo::StormTracker::Advisory object if successful.
If unsuccessful the method returns an undefined value.

=item read_data (STRING)

Attempts to parse the advisory text input as a string argument and returns
a Geo::StormTracker::Advisory object if successful.
If unsuccessful the method returns an undefined value.

=item read_file (STRING)

Reads an advisory saved in a file whose path is passed as a string argument
and returns a Geo::StormTracker::Advisory object if successful.
If unsuccessful the method returns an undefined value.

=back

=head1 AUTHOR


James Lee Carpenter, Jimmy.Carpenter@chron.com

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
 
Thanks to Dr. Paul Ruscher for his assistance in helping me to understand
the weather advisory formats.


=head1 SEE ALSO

	Geo::StormTracker::Advisory
	Geo::StormTracker::Main
	Geo::StormTracker::Data
	perl(1).

=cut
