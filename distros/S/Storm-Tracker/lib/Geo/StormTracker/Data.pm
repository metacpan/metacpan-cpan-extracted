package Geo::StormTracker::Data;

use Carp;
use Geo::StormTracker::Parser;
use IO::File;
use IO::Dir;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

#------------------------------------------------------------------------------
sub new {
	my $self=shift;
	my $path=shift;

	my ($msg,$success, $io)=undef;
	my $anon_HR={};

	#Check to see if the path was given
	unless (defined($path)){
		$msg = "The mandatory path argument was not provided to the new method!";
		carp $msg,"\n";
		return (undef,$msg);
	}

	#Make sure the path ends with a single slash.
	$path =~ s!/*$!/!;

	#Now check the path to see if it exists.
	#If not return undefined.
	unless (-e $path){
		$msg="The new method only creates an object if the path already exists!";
		$msg.="Consider using the shiny_new method instead!";
		carp $msg,"\n";
		return (undef,$msg);
	}#if
	
	#anytime a new data object is created it should contain a
	#the path, year, region, and event number for the weather event in question.

	$io=IO::File->new();
	unless ($io->open("<${path}region")){
		$msg="Couldn't open the ${path}region file!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$anon_HR->{'region'}=$io->getline();
	chomp $anon_HR->{'region'};
	$io->close();
	
	unless ($io->open("<${path}year")){
		$msg="Couldn't open the ${path}year file!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$anon_HR->{'year'}=$io->getline();
	chomp $anon_HR->{'year'};
	$io->close();
	
	unless ($io->open("<${path}event_number")){
		$msg="Couldn't open the ${path}event_number file!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$anon_HR->{'event_number'}=$io->getline();
	chomp $anon_HR->{'event_number'};
	$io->close();

	$anon_HR->{'path'} = $path;
	bless $anon_HR, 'Geo::StormTracker::Data';

	return ($anon_HR, undef);

}#new
#------------------------------------------------------------------------------
sub shiny_new {
        my $self=shift;
        my $path=shift;
	my $region=shift;
	my $year=shift;
	my $event_num=shift;
 
        my ($msg,$success, $io)=undef;
        my $anon_HR={};
 
        #Check to see if the path was given
        unless (defined($path)){
                $msg = "The mandatory path argument was not provided to the shiny_new method!";
                carp $msg,"\n";
                return (undef,$msg);
        }#unless

	#Check the region argument.
	unless (
		(defined $region) and
		($region =~ m!^\w{2}$!)
		){
		$msg = "The shiny_new method's mandatory region argument was not provided or failed the syntax check!";
		carp $msg,"\n";
                return (undef,$msg);
	}#unless
	
	#Check the year argument.
	unless (
		(defined $year) and
		($year =~ m!^\d{4}$!)
		){
		$msg = "The shiny_new method's mandatory year argument was not provided or was not a 4 digit number!";
		carp $msg,"\n";
                return (undef,$msg);
	}#unless
	
	#Check the event_num argument.
	unless (
		(defined $event_num) and
		($event_num =~ m!^\d+$!)
		){
		$msg = "The shiny_new method's mandatory event number argument was not provided or was not a number!";
		carp $msg,"\n";
                return (undef,$msg);
	}#unless
	
        #Make sure the path ends with a single slash.
        $path =~ s!/*$!/!;
 
        #Now check the path to see if it exist.
	#If the path already exists, return undefined.
	if (-e $path){
		$msg="The path already exists.  The shiny_new method always fails in this event!";
		return (undef,$msg);
	}#if

        $success=mkdir($path,0776);
        unless ($success) {
		$msg = "Could not create a directory $path!";
		$msg .= "Consider using the new method!";
                carp $msg,"\n";
                return (undef,$msg);
	}#unless

	#Write out the region file.
	$io=IO::File->new();
	unless ($io->open(">${path}region")){
		$msg="Could not create a ${path}region file!";
		$msg.= "  The database is likely in a corrupt state due to this failure!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$io->print($region);
	$io->close();

	#Write out the year file. 
	unless ($io->open(">${path}year")){
		$msg="Could not create a ${path}year file!";
		$msg.= "  The database is likely in a corrupt state due to this failure!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$io->print($year);
	$io->close();
	
	#Write out the event_number file. 
	unless ($io->open(">${path}event_number")){
		$msg="Could not create a ${path}event_number file!";
		$msg.= "  The database is likely in a corrupt state due to this failure!";
		carp $msg, "\n";
		return (undef, $msg);
	}#unless
	$io->print($event_num);
	$io->close();
 
        #anytime a new data object is created it should contain a
        #the path, region, year, and event_number for the weather event in question.
 
        $anon_HR->{'path'} = $path;
	$anon_HR->{'region'}=$region;
	$anon_HR->{'year'}=$year;
	$anon_HR->{'event_number'}=$event_num;
        bless $anon_HR, 'Geo::StormTracker::Data';
 
        return ($anon_HR, undef);
 
}#shiny_new
#------------------------------------------------------------------------------
sub get_path {
	my $self=shift;
	return $self->{'path'};
}#get_path
#------------------------------------------------------------------------------
sub get_region {
	my $self=shift;
	return $self->{'region'};
}#get_region
#------------------------------------------------------------------------------
sub get_year {
	my $self=shift;
	return $self->{'year'};
}#get_year
#------------------------------------------------------------------------------
sub get_event_number {
	my $self=shift;
	return $self->{'event_number'};
}#get_event_number
#------------------------------------------------------------------------------
sub is_active {
	my $self=shift;
	my $arg=shift;
	my $ignore_lock=shift;
	
	my ($activefile,$io,$success,$error,$msg)=undef;

	$ignore_lock=0 if (!defined $ignore_lock);

	$activefile=$self->{'path'}.'activefile';

	if (defined($arg)){
		($success,$error)=$self->_patiently_grab_lock() unless ($ignore_lock);
		unless (($success) or ($ignore_lock)){
			$msg="Couldn't grab write lock for this weather event!";
			$msg.="  error was: $error";
			carp $msg,"\n";
			return (undef,$msg);
		}#unless

		if ($arg){
			$io=IO::File->new();
			unless($io->open(">$activefile")){
				$msg="Couldn't open $activefile in is_active method!";
				carp $msg,"\n";
				return (undef,$msg);
			}
			$io->print($$);
			$io->close();
		}
		else {
			unless(unlink($activefile)){
				$msg="Couldn't unlink $activefile in is_active method!";
				carp $msg,"\n";
				return (undef,$msg);
			}
		}#if/else

		($success,$error)=$self->_patiently_release_lock() unless ($ignore_lock);
		unless (($success) or ($ignore_lock)){
			$msg="Couldn't release write lock for this weather event!";
			$msg.="  error was: $error";
			carp $msg,"\n";
			return (undef,$msg);
		}
		return ($arg,undef);
	}
	else {
		if (-e $activefile){
			return (1,undef);
		}
		else {
			return (0,undef);
		}
	}#if/else
}
#------------------------------------------------------------------------------
#Need to figure out something sensensible to do with the success and error return
#values.
sub insert_advisory {
	my $self=shift;
	my $adv_obj=shift;
	my $force_option=shift;
	my $active_state=shift;

	my ($i,$got_lock,$lost_lock,$success,$error,$msg,$set_to)=undef;

	#attempt to grab a write lock
	($got_lock,$msg)=$self->_patiently_grab_lock();
	unless ($got_lock){
		return (undef,$msg);
	}#unless
	
	($success,$msg)=$self->_write_advisory($adv_obj,$force_option);
	unless ($success){
	        ($lost_lock,$error)=$self->_patiently_release_lock();
		$msg .= $error unless ($lost_lock);	
		return (undef,$msg);
	}#unless

	($success,$msg)=$self->_update_trackfile($adv_obj,$force_option);
        unless ($success){
                ($lost_lock,$error)=$self->_patiently_release_lock();
                $msg .= $error unless ($lost_lock);              
                return (undef,$msg);
        }#unless

	if (defined $active_state){
		($set_to,$msg)=$self->is_active($active_state,1);
		unless (defined $set_to){
			($lost_lock,$error)=$self->_patiently_release_lock();
	                $msg .= $error unless ($lost_lock);              
			return (undef,$msg);
		}
	}#if

	#attempt to release the write lock
	($success,$error)=$self->_patiently_release_lock();

	if ($success){
		return (1,undef);
	}
	else {
		return (undef,$error);
	}#if/else

}#insert_advisory
#------------------------------------------------------------------------------
sub all_advisories {
	my $self=shift;

	my ($parser,$file,$adv_obj)=undef;
	my @advisory_files=();
	my @adv_obj_array=();

	@advisory_files=$self->_sorted_advisory_files();

	$parser=Geo::StormTracker::Parser->new();
	
	foreach $file (@advisory_files){
		$adv_obj=$parser->read_file($self->{'path'}.$file);
		push (@adv_obj_array,$adv_obj) if (defined $adv_obj);
	}

	return wantarray ? @adv_obj_array : \@adv_obj_array;
}#all_advisories
#-----------------------------------------------------------------------------
sub current_advisory {
	my $self=shift;

	my ($parser,$current_advisory_file,$adv_obj);
	my @advisory_files=();

	@advisory_files=$self->_sorted_advisory_files();
	$current_advisory_file=$advisory_files[$#advisory_files];
	
	$parser=Geo::StormTracker::Parser->new();

	$adv_obj=$parser->read_file($self->{'path'}.$current_advisory_file);

	return $adv_obj;
}#current_advisory
#-----------------------------------------------------------------------------
sub advisory_by_number {
	my $self=shift;
	my $advisory_number=shift;

	my ($d,$path,$msg,$file,$target_file,$parser,$number,$adv_obj)=undef;
	my @file_list=();

	$path=$self->{'path'};

	#Check the advisory_number argument	
	unless (defined $advisory_number){
		$msg="An advisory number argument must be given to the advisory_by_number method!";
		carp $msg,"\n";
		return undef;
	}

	#Grab list of files in the $path directory.
	$d=IO::Dir->new();
        $d->open($path);
        unless (defined($d)){
                $msg = "Had trouble reading $path directory!";
                carp $msg,"\n";
                return undef;
        }
	@file_list=$d->read();
	$d->close();

	#Figure out which file is has the advisory number we want.
	$target_file=undef;	
	foreach $file (@file_list){
		next if $file =~ m!^(\.|\.\.)$!;
		$file =~ m!(\d+[A-Z]*)\.adv!;
		$number=$1;
		#if ((defined $number) and ($advisory_number == $number)){
		if ((defined $number) and ($self->_compare_advisory_numbers($advisory_number,$number) == 0) ){
			$target_file=$file;
			last;
		}#if;
	}#foreach

	#If the desired file wasn't found then return undef.
	return undef unless (defined $target_file);

	#parse the file and obtain its advisory object. 
	$parser=Geo::StormTracker::Parser->new();

	$adv_obj=$parser->read_file($self->{'path'}.$target_file);

	#return the advisory object
	return $adv_obj;
}#advisory_by_number
#------------------------------------------------------------------------------
sub _sorted_advisory_files {
	my $self=shift;

	my ($d,$path,$msg,$file)=undef;
	my @unsorted_advisory_files=();
	my @advisory_files=();
	my @file_list=();

	$path=$self->{'path'};

        $d=IO::Dir->new();
        $d->open($path);
        unless (defined($d)){
                $msg = "Had trouble reading $path directory!";
		carp $msg,"\n";
		return undef;
        }
 
        @file_list=$d->read;
        $d->close();

	foreach $file (@file_list){
		if ($file =~ m!\d+[A-Z]*\.adv$!){
			push(@unsorted_advisory_files,$file);
		}#if
	}#foreach

	@advisory_files=sort {
				$a =~ m!(\d+[A-Z]*)\.adv$!;
				my $num_a=$1;	
				$b =~ m!(\d+[A-Z]*)\.adv$!;
				my $num_b=$1;
				#$num_a <=> $num_b;
				$self->_compare_advisory_numbers($num_a,$num_b);
				}
				@unsorted_advisory_files;

	return @advisory_files;

}#_sorted_advisory_files
#------------------------------------------------------------------------------
sub current_position {
	my $self=shift;

	my @position_array=();

	@position_array=$self->position_track();

	return $position_array[$#position_array];

}#current_postion
#------------------------------------------------------------------------------
sub position_track {
	my $self=shift;

	my ($trackfile,$in_line,$lat_digit,$lat_dir,$long_digit,$long_dir,$msg)=undef;
	my @position_array=();

	$trackfile=$self->{'path'}.'trackfile';

	my $io_in=IO::File->new();
	unless ($io_in->open("<$trackfile")){
		$msg="position_track method couldn't read from $trackfile!";	
		carp $msg,"\n";
		return undef;
	}
	while (defined($in_line=$io_in->getline)){
		chomp($in_line);
		($lat_digit,$lat_dir,$long_digit,$long_dir)=split(',',(split("\t",$in_line))[5]);
		push (@position_array,[$lat_digit,$lat_dir,$long_digit,$long_dir]);
	}#while	

	return wantarray ? @position_array : \@position_array;
}#positon_track
#------------------------------------------------------------------------------
sub _construct_data_line {
	my $self=shift;
	my $adv_obj=shift;

	my ($data_line,$advisory_number,$event_type,$release_time)=undef;	
	my ($max_winds,$min_central_pressure,$position_AR)=undef;
	my @data_line=();

	$advisory_number=$adv_obj->advisory_number();
	$event_type=$adv_obj->event_type();
	$release_time=$adv_obj->release_time();
	$max_winds=$adv_obj->max_winds();
	$min_central_pressure=$adv_obj->min_central_pressure();
	$position_AR=$adv_obj->position();

	if (defined $advisory_number){
		push(@data_line,$advisory_number);
	}	
	else {
		push(@data_line,'');
	}#if/else

	if (defined($event_type)){	
		push(@data_line,$event_type);
	}
	else {
		push(@data_line,'');
	}#if/else

	if (defined $release_time){
		push(@data_line,$release_time);
	}
	else {
		push(@data_line,'');
	}#if/else

	if (defined $max_winds){
		push(@data_line,$max_winds);
	}
	else {
		push(@data_line,'');
	}#if/else

	if (defined $min_central_pressure){
		push(@data_line,$min_central_pressure);
	}
	else {
		push(@data_line,'');
	}#if/else

	if (defined $position_AR){
		push(@data_line,join(',',@{$position_AR}));
	}
	else {
		push(@data_line,'');
	}#if/else

	$data_line=join("\t",@data_line);

	return $data_line;

}#_construct_data_line
#------------------------------------------------------------------------------
sub _update_trackfile {
	my $self=shift;
	my $adv_obj=shift;
	my $force_option=shift;
	
	my ($msg,$success,$io_in,$io_out,$in_line,$advisory_index,$data_line)=undef;
	my ($adv_comp,$trackfile,$advisory_number,$added_data)=undef;

	$data_line=$self->_construct_data_line($adv_obj);

	$trackfile=$self->{'path'}."trackfile";
	$advisory_number=$adv_obj->advisory_number();
	
	if (-e $trackfile) {
		$success=rename($trackfile,"$trackfile\.old");
		unless ($success) {
			$msg="Couldn't move $trackfile to $trackfile\.old!";
			croak $msg,"\n";
			#return (0,$msg);
		}#unless

		$io_in=IO::File->new();
		unless ($io_in->open("<$trackfile\.old")){
			$msg="Couldn't open $trackfile\.old for reading!";
			croak $msg,"\n";
			#return (0,$msg);
		}#unless

		$io_out=IO::File->new();
		unless ($io_out->open(">$trackfile")){
			$msg="Couldn't open $trackfile for writting!";
			croak $msg,"\n";
			#return (0,$msg);
		}#unless

		$added_data=0;
		while (defined($in_line=$io_in->getline)){
			chomp($in_line);

			$advisory_index=(split("\t",$in_line))[0];
			
			$adv_comp=$self->_compare_advisory_numbers($advisory_index,$advisory_number);
		
			#if ($advisory_index < $advisory_number){
			if ($adv_comp < 0){
				$io_out->print($in_line,"\n");
			}
			#elsif ($advisory_index == $advisory_number){
			elsif ($adv_comp == 0){
				if ($force_option){
					$io_out->print($data_line,"\n");
				}
				else {
					$io_out->print($in_line,"\n");
					$msg="Advisory number $advisory_number already exists and force option is not on!";
					$msg.="  The original track information was not changed!";
					carp $msg,"\n";
				}#if/else

				$added_data=1;
			}
			else {
				unless ($added_data){
					$io_out->print($data_line,"\n");
					$added_data=1;
				}#unless

				$io_out->print($in_line,"\n");
			}#if/elsif/else
		}#while
		$io_out->close();
		$io_in->close();
		
		unless(unlink("$trackfile\.old")){
			$msg="Couldn't unlink $trackfile\.old!";
			carp $msg,"\n"; 
		}
	}
	else {
		$io_out=IO::File->new();
		unless ($io_out->open(">$trackfile")){
			$msg="Couldn't open $trackfile for writting!";
			croak $msg,"\n";
			#return (0,$msg);
		}#unless
		$io_out->print($data_line,"\n");
		$io_out->close();
	}#if/else
		
	return (1,$msg);
}#_update_trackfile
#------------------------------------------------------------------------------
sub _compare_advisory_numbers {
	my $self=shift;
	my $adv_num1=shift;
	my $adv_num2=shift;

	my ($num1_digits,$num1_alpha,$num2_digits,$num2_alpha)=undef;

	$adv_num1 =~ m!(\d+)([A-Z]*)$!;
	$num1_digits=$1;
	$num1_alpha=$2;
	$num1_alpha=uc $num1_alpha if (defined $num1_alpha);
	$num1_alpha =~ tr/ABCDEFGHI/123456789/;
	$adv_num1="$num1_digits\.$num1_alpha";

	$adv_num2 =~ m!(\d+)([A-Z]*)$!;
	$num2_digits=$1;
	$num2_alpha=$2;
	$num2_alpha=uc $num2_alpha if (defined $num2_alpha);
	$num2_alpha =~ tr/ABCDEFGHI/123456789/;
	$adv_num2="$num2_digits\.$num2_alpha";

	return $adv_num1 <=> $adv_num2;
}#_compare_advisory_numbers
#------------------------------------------------------------------------------
sub _write_advisory {
	my $self=shift;
	my $adv_obj=shift;
	my $force_option=shift;

	my ($io,$filename,$msg,$path)=undef;

	#Come up with a filename unique to each advisory number
	#and which has some indicator of storm type
	$path=$self->{'path'};
	$filename =$adv_obj->event_type();
	$filename =~ s!\s!!gs;
	$filename .= $adv_obj->advisory_number();
	$filename .= '.adv';
	$filename = "${path}${filename}";


	if ((-e $filename) and (!$force_option)) {
		$msg="Filename $filename exists and force option is not on!";
		carp $msg,"\n";
		return (0,$msg);
	}
	else {
		$io=IO::File->new();
		unless ($io->open(">$filename")){
			$msg="Couldn't write to file $filename!";
			carp $msg,"\n";
			return (0,$msg);
		}
		$io->print($adv_obj->stringify());
		$io->close();
		return (1,undef);
	}
}#_write_advisory
#------------------------------------------------------------------------------
sub _patiently_grab_lock{
	my $self=shift;

	my ($success,$msg,$i)=undef;

	for ($i = 0; $i <= 4; $i++){
		$success=$self->_grab_advisory_lock();
		last if ($success);
		if ($i == 4) {
			$msg="Could not grab a write lock!";
			carp $msg,"\n";
			return (0,$msg);
		} 
		else {
			sleep 2;
		}#if/else
	}#for

	return (1,undef);

}#_patiently_grab_lock
#------------------------------------------------------------------------------
sub _patiently_release_lock{
	my $self=shift;

	my ($success,$msg,$i)=undef;

	for ($i = 0; $i <= 4; $i++){
		$success=$self->_release_advisory_lock();
		last if ($success);
		if ($i == 4) {
			$msg="Could not release the write lock!";
			carp $msg,"\n";
			return (0,$msg);
		} 
		else {
			sleep 2;
		}#if/else
	}#for

	return (1,undef);

}#_patiently_release_lock
#------------------------------------------------------------------------------
#$success=$self->_grab_advisory_lock();
sub _grab_advisory_lock {
	my $self=shift;

	my ($lock_file,$io)=undef;

	$lock_file=$self->{'path'}."lockfile";
	if (-e $lock_file) {
		return 0;
	}
	else {
		$io=IO::File->new();
		$io->open(">$lock_file") or croak "Couldn't write to $lock_file\n";
		$io->print("$$");
		$io->close();
		return 1; 
	}#if/else
}#_grab_advisory_lock
#------------------------------------------------------------------------------
#$success=$self->_release_advisory_lock();
sub _release_advisory_lock {
	my $self=shift;

	my $lock_file=undef;

	$lock_file=$self->{'path'}."lockfile";

	if (unlink($lock_file)){
		return 1;
	}
	else {
		return 0;
	}
}#_release_advisory_lock
#------------------------------------------------------------------------------

1;
__END__

=head1 NAME

Geo::StormTracker::Data - The weather event object of the perl Storm-Tracker bundle. 

=head1 SYNOPSIS

	use Geo::StormTracker::Data;

        #The only argument is the path for the data files of
	#this new data object.
        #If the directory does not exist it will fail.

	($data_object,$error)=Geo::StormTracker::Data->new('/data/1999/15');

	#The shiny_new method expects to create the last directory level of the path.
	#If the full path already exists it will fail.
	#The 2nd, 3rd, and 4th arguments are the region code, year, and event number respectively.
	($data_object,$error)=Geo::StormTracker::Data->shiny_new('/data/1999/15', 'NT', 1999, 15);

	
	#The insert_advisory method inserts an advisory object
	#into the data object.
	#Unless the second argument is true, inserting an
	#advisory with the same advisory number as a previously
	#inserted advisory will fail. 
       	#Second argument can be thought of as a force flag.
       
	 ($success,$error)=$data_object->insert_advisory($adv_obj,[0|1])


	#Determine the last known position for this weather event.
	$position_AR=$data_object->current_position()

	($long,$long_dir,$lat,$lat_dir)=@{$position_AR};


	#The postion_track method will return an
	#array of position array references.
	#sorted in advisory number order.
	#The position from the advisory with the smallest
        #advisory number will be in element 0 of @track.
       
	@track=$data_object->position_track();

	#Alternatively.

	$track_AR=$data_object->position_track();
	@track=@{$track_AR};


	#Retrieve the most current advisory available
	#for this data object.
        
	$adv_obj=$data_object->current_advisory;


	#Is this weather event still occurring?
	#$set_to will contain true(1) or false(0)
	#if called without any arguments.
	#Can be used as an assignment operator
	#if given an argument.
	#When used as an assignment operator it
	#returns the value to which it was set
	#if successful and undef otherwise.

	($set_to,$error)=$data_object->is_active([[0|1]);


	#The all_advisory_objects method returns an array of
	#every weather event advisory available in the referenced
	#data object.
	#The order is identical
	#to that returned by the position_track method.

	@all_advisory_objects=$data_object->all_advisories();
	
	#Alternatively

	$all_advisory_objects_AR=$data_object->all_advisories();


	#The advisory_by_number method returns an advisory
	#object for the advisory number given as an argument.
	#If the advisory doesn't exist the method returns undef.

	$adv_obj_15=$data_object->advisory_by_number(15);


	#Returns the path to the data file directory of
	#this object.

	$path=$data_object->get_path();


	#Returns the region code corresponding to the data object.

	$region=$data_object->get_region();
	

	#Returns the year corresponding to the data object.

	$year=$data_object->get_year();


	#Returns the event number corresponding to the data object.

	$event_number=$data_object->get_event_number();


=head1 DESCRIPTION

The C<Geo::StormTracker::Data> module is a component
of the Storm-Tracker perl bundle.  The Storm-Tracker perl bundle
is designed to track weather events using the national weather advisories.
The original intent is to track tropical depressions, storms and hurricanes.
There should be a C<Geo::StormTracker::Data> object for each
weather event being stored and/or tracked.  The C<Geo::StormTracker::Data>
objects are managed by C<Geo::StormTracker::Main>.

=head1 CONSTRUCTOR

=over 4

=item new (PATHNAME)

Creates a Geo::StormTracker::Data object.
This constructor method returns an array of
the form (OBJECT,ERROR).  OBJECT being the
newly created object if successful, and
ERROR being any errors encountered during the
attempt.

The data set for this object is assumed to be contained
within the directory specified by the mandatory
PATHNAME argument.  In the event that a directory
with the given PATHNAME does not exist, the method
will fail.  Check to see if the OBJECT returned is defined.

The motivation for having two constructor methods instead of
one, is to help the caller maintain data integrity.

=cut

=item shiny_new (PATHNAME, REGION, YEAR, EVENT_NUMBER)

Creates a Geo::StormTracker::Data object.
This constructor method returns an array of
the form (OBJECT,ERROR).  OBJECT being the
newly created object if successful, and
ERROR being any errors encountered during the
attempt.
 
The data set for this object will be placed
within the directory specified by the mandatory
PATHNAME argument.  The method will only succeed if
the directory with the given PATHNAME does not already
exist.

The shiny_new method only knows how to create the
last level directory.  The constructor does not
attempt to recursively create a new directory and therefore
will never succeed unless every directory in the path
except the last one already exists.  Even then the
creation of a new directory can fail due to permission
problems.  It is wise to always check to insure that
the OBJECT returned is defined.

The motivation for having two constructor methods instead of
one, is to help the caller maintain data integrity.

The mandatory REGION, YEAR, and EVENT_NUMBER will be
persistently stored within the Geo::StormTracker::Data
object.  Their values can be accessed via the
get_region, get_year, and get_event_number methods
of Geo::StormTracker::Data objects.  The REGION, YEAR,
and EVENT_NUMBER are not implicitly related to the
PATH in any way.

=cut

=back

=head1 METHODS

=over 4


=item insert_advisory (ADVISORY_OBJECT)

Attempts to insert a C<Geo::StormTracker::Advisory>
object into the C<Geo::StormTracker::Data>
object being referenced.

The method returns an array of the form (SUCCESS,ERROR).
SUCCESS being a boolean value indicating whether or not
the operation was successful and ERROR being a scalar
string reporting what error was encountered if any.


=item current_position

When called in scalar context current_position
returns a reference to a position array.

When called in array context current_position
returns a position array.
 
The position array specifies the longitude
and latitude of the most recent weather advisory
available for this C<Geo::StormTracker::Data> object.
The position array is of the form
(LONGITUDE,N or S,LATITUDE, W or E).

If the C<Geo::StormTracker::Data> object being
referenced contains no advisories at all the
return value will be undefined.


=item position_track

When called in scalar context position_track
returns a reference to an array of position
array references.

When called in array context position_track
returns an array of position array
references.

There is a position returned for each
advisory within the
C<Geo::StormTracker::Data> object
being referenced.  The position arrays
returned are sorted by advisory number
with the smallest advisory number first.

The position arrays are identical in format
to that returned by the current_position
method.


=item current_advisory

Returns a reference to the
C<Geo::StormTracker::Advisory>
object within the
C<Geo::StormTracker::Data> object
that has the greatest advisory
number.

If the C<Geo::StormTracker::Data>
object being referenced contains no
advisories at all the return value
will be undefined.


=item all_advisories

When called in scalar context all_advisories
returns a reference to an array of advisory
objects.

When called in array context all_advisories
returns an array of advisory objects.

The array of advisories is sorted by
advisory number in the same order as
that used by the position_track
method.  The advisory with the
smallest advisory number will be
given first.

If the C<Geo::StormTracker::Data>
object being referenced contains no
advisories at all the return value
will be undefined.


=item advisory_by_number (NUM)

Returns a reference to the advisory
object with the same advisory
number as given by the mandatory
NUM argument.

If the C<Geo::StormTracker::Data>
object being referenced does not
contain an advisory with the
requested advisory number the
return value will be undefined.


=item get_path

Returns the path passed to the
new method upon creation of
the referenced
C<Geo::StormTracker::Data>
object.

=item get_region

Returns the region passed to the
shiny_new method during the first
creation of the referenced
C<Geo::StormTracker::Data>
object.


=item get_year

Returns the 4 digit year passed to the
shiny_new method during the first
creation of the referenced
C<Geo::StormTracker::Data>
object.


=item get_event_number

Returns the event number passed to the
shiny_new method during the first
creation of the referenced
C<Geo::StormTracker::Data>
object.


=item is_active ([BOOLEAN])

When called with a boolean argument
is_active attempts to define the
referenced
C<Geo::StormTracker::Data>
object as active or inactive.
is_active returns the array
(SET_TO,ERROR).
If successful the SET_TO string
indicates the value the state
to which the data_object was set.
If unsuccessful SET_TO will be
undefined and ERROR will contain
the reason for the failure.  

When is_active is called without
an argument it will return the
current state of the
C<Geo::StormTracker::Data>
object being referenced.


=back


=head1 AUTHOR

Jimmy Carpenter, Jimmy.Carpenter@chron.com

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.
 
Thanks to Dr. Paul Ruscher for his assistance in helping me to understand
the weather advisory formats.

 
=head1 SEE ALSO

Geo::StormTracker::Main
Geo::StormTracker::Parser
Geo::StormTracker::Advisory

perl(1).

=cut
