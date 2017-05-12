package Nokia::File::NFB;

## Create, Parse and Write Nokia NFB files.
## Robert Price - http://www.robertprice.co.uk/

use 5.00503;
use strict;
use utf8;
use vars qw($VERSION);

use Carp;
use Compress::Zlib qw(crc32);
use Encode qw(decode encode);
use Fcntl qw(:seek);
use FileHandle;

use Nokia::File::NFB::Element;

$VERSION = '0.01';


## new()
## the object constructor.
## OUTPUT: a blessed hash corresponding to the object.
sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}


## DESTROY()
## destructor for the object. We just make sure we have any
## open file handles closed before we die.
sub DESTROY {
	my $self = shift;

	## close any filehandles we have in the object that are still open.
	$self->{'_fh'}->close()	if ((exists $self->{'_fh'}) && ($self->{'_fh'}) && (ref($self->{'_fh'}) eq 'FileHandle'));
}


## version()
## get or set the NFB file version.
## INPUT: a string with the NFB file version in (optional).
## OUTPUT: a string with the NFB file version in.
sub version {
	my $self = shift;
	$self->{'_version'}	= $_[0]	if ($_[0]);
	return $self->{'_version'};
}


## firmware()
## get or set the phone firmware relating to the file.
## INPUT: a string with the phone firmware in (optional).
## OUTPUT: a string with the phone firmware in.
sub firmware {
	my $self = shift;
	$self->{'_firmware'}	= $_[0]	if ($_[0]);
	return $self->{'_firmware'};
}


## phone()
## get or set the phone model relating to the file.
## INPUT: a string with the phone model in (optional).
## OUTPUT: a string with the phone model in.
sub phone {
	my $self = shift;
	$self->{'_phone'}	= $_[0]	if ($_[0]);
	return $self->{'_phone'};
}


## elements()
## return a reference to an array with the elements in.
## INPUT: a reference to an array with elements in (optional).
## OUTPUT: a reference to an array with the elements in.
sub elements {
	my $self = shift;
	if ($_[0]) {
		my $elements = $_[0];
		croak("elements need to be a reference to an ARRAY")	
			unless (ref($elements) eq 'ARRAY');
		$self->{'_elements'} = $elements;
	}
	return $self->{'_elements'};
}


## read()
## reads in the NFB file from a specified filename, parse it
## and setup the object with the corresponding data.
## INPUT: filename to read.
sub read {
	my $self = shift;
	my $filename = shift;
	
	## keep a copy of the filename in the object for backup.
	$self->{'_filename'} = $filename;
	
	## open the file as readonly, else warn the user.
	my $fh = new FileHandle($filename, 'r');
	croak "Unable to open $filename for reading"	unless (defined($fh));
	$self->{'_fh'} = $fh;
	
	## ensure we are in binary mode as some system (win32 for example)
	## will assume we are handling text otherwise.
	binmode $fh, ':raw';

	## work out the length of the file and save it in the object.	
	$fh->seek(-4, SEEK_END);
	$self->{'_length'} = $fh->tell();

	## work out the checksum for the data and save it in the object.
	$fh->seek(0, SEEK_SET);
	$self->{'_crc'} = crc32($self->_read($self->{'_length'}));
	
	## work out the file version, this is a little endian long
	$fh->seek(0, SEEK_SET);
	$self->{'_version'} = unpack('V',$self->_read(4));

	## get the id and phone and store in the object.
	$self->{'_firmware'} = $self->_readstring();
	$self->{'_phone'} = $self->_readstring();
	
	## parse the main data.

	## work out how many elements of data we have stored in the file.
	$self->{'_number_of_elements'} = unpack('V', $self->_read(4));

	## where we are going to store our elements
	$self->{'_elements'} = undef;
	
	## iterate over all the elements in the file.
	for (my $i=0; $i<$self->{'_number_of_elements'}; $i++) {
	
		## work out filetype of the element, 1 = file, 2 = directory.
		my $filetype = unpack('V', $self->_read(4));
		
		## if we have a file...
		if ($filetype == 1) {

			## get the filename.
			my $path = $self->_readstring();
			
			## get the length of data.
			my $length = unpack('V', $self->_read(4));

			## get the data itself.
			my $fdata = $self->_read($length);

			## get the file's timestamp.
			my $timestamp = unpack('V', $self->_read(4));

			## store it all in an Element, and save.
			my $data = Nokia::File::NFB::Element->new({
				'type'	=> $filetype,
				'name'	=> $path,
				'size'	=> $length,
				'time'	=> $timestamp,
				'data'	=> $fdata,
			});
			push @{$self->{'_elements'}}, $data;
			
		## if we have a directory
		} elsif ($filetype == 2) {

			## get the directory's name.
			my $path = $self->_readstring();

			## store it all in an Element and save.
			my $data = Nokia::File::NFB::Element->new({
				'type'	=> $filetype,
				'name'	=> $path,
			});
			push @{$self->{'_elements'}}, $data;
			
		## else it's an unknown file type
		} else {
			croak("Unknown element type found in data");
		}
	}
	
	## get the checksum from the file.
	$self->{'_checksum'} = unpack('V', $self->_read(4));
	
	## close the file and remove references to the filehandle from the object.
	$fh->close();
	delete $self->{'_fh'};
}



## write()
## write out the NFB file as a binary file to a specified filename.
## IN: filename to use
sub write {
	my $self = shift;
	my $filename = shift;

	## open the file for writing and save the handle to the object
	my $fh = new FileHandle($filename, 'w');
	croak "Unable to open $filename for writing"	unless (defined($fh));
	$self->{'_fh'} = $fh;
	
	## ensure we are in binary mode as some system (win32 for example)
	## will assume we are handling text otherwise.
	binmode $fh, ':raw';

	## write the binary data out
	print $fh $self->binary();	

	## close the file and remove references to the filehandle from the object.
	$fh->close();
	delete $self->{'_fh'};	
}



## binary()
## return the NFB file as a binary scalar.
## OUTPUT: The NFB file as a binary scalar variable.
sub binary {
	my $self = shift;
	my $binfile;
	
	## write out the nfb/c version.
	$binfile .= pack('V',$self->{'_version'});	## pack as little endian long.
	
	## write out the firmware.
	$binfile .= pack('V', length($self->{'_firmware'}));	## size of the string.
	$binfile .= encode('UCS-2LE', $self->{'_firmware'});	## and the string itself, in UCS2 (little endian) format.

	## write out the phone model.
	$binfile .= pack('V', length($self->{'_phone'}));
	$binfile .= encode('UCS-2LE', $self->{'_phone'});
	
	## the number of elements.
	$binfile .= pack('V',scalar(@{$self->{'_elements'}}));
	
	## add each element.
	foreach my $element (@{$self->{'_elements'}}) {
		$binfile .= $element->binary();
	}
	
	## work out the checksum and add it at the end.
	my $checksum = crc32($binfile);
	$binfile .= pack('V',$checksum);

	return $binfile;
}


## _readstring
## utility function to read a UCS2 string and return it in utf8.
## OUTPUT: string - the string in utf8 format.
sub _readstring {
	my $self = shift;
	
	## get the length of the string, as UCS2 is two bytes long, have to double it.
	my $length = unpack("V", $self->_read(4)) * 2;	
	
	## read, decode and return the string.
	my $ucs2string = $self->_read($length);
	return decode('UCS-2LE', $ucs2string);
}



## _read
## utility function to read data from a FileHandle and return it.
## INPUT: size - the ammount of data to read.
## OUTPUT: data - the data.
sub _read {
	my $self = shift;
	my $size = shift;
	my $data;
	my $fh = $self->{'_fh'};
	$fh->read($data, $size);
	return $data;
}

1;
__END__

=head1 NAME

Nokia::File::NFB - Create, Read and Write Nokia nfb/nfc phone backup files.

=head1 SYNOPSIS

  use Nokia::File::NFB;

  my $nfb = new Nokia::File::NFB;

  ## read in the file 'phone_backup.nfb'.
  $nfb->read('phone_backup.nfb');

  ## print out the phone model the backup file is of.
  print "Phone model is ", $nfb->phone(), "\n";

  ## change the phone model to 'PerlPhone'.
  $nfb->phone("PerlPhone");

  ## write out the file as 'new_phone_backup.nfb'.
  $nfb->write('new_phone_backup.nfb');
  
=head1 DESCRIPTION

This is used to parse existing or create new files in Nokia
NFB or NFC format. NFB is the format used by the Nokia PC Suite 
Backup and Restore software. 

The most interesting part is probably the elements() method. 
This is used to return each internal file backed up in the 
NFB file as a Nokia::File::NFB::Element object. These
are useful things such as photos, contacts and calendar files.

I don't actually know what the letters NFB or NFC actually stand
for, but they are the suffixes used on the backup and copy file
created by the Backup and Restore program.

This is based on some Python code found at 
http://www.dryfish.org/projects/nfb.html

=head1 METHODS

=head2 new()

Create a new Nokia::File::NFB. It takes no parameters.

	my $nfb = new Nokia::File::NFB;

=head2 read()
	
Reads in an NFB or NFC format file. Pass a scalar containing the
filename to read.

	$nfb->read("backup.nfb");

=head2 write()
	
Writes out an NFB or NFC file. Pass a scalar containing the
filename to write out.

	$nfb->write();

=head2 phone()
	
Gets or sets the phone model type in the NFB file.

	my $phone = $nfb->phone();
	$nfb->phone("PerlPhone");

=head2 version()
	
Gets or sets the NFB file version. 

	my $version = $nfb->version();
	$nfb->version(3);

NOTE: On my tests this is always version 3.

=head2 firmware()
	
Gets or sets the firmware of the phone that is backed
up in the NFB file.

	my $firmware = $nfb->firmware();
	$nfb->firmware('Perl');

=head2 elements()

Gets or sets a reference to a list of 
Nokia::File::NFB::Element objects. 
These are the actual files in backed up in the NFB file.

	my $elements = $nfb->elements();
	$nfb->elements($new_elements);
	
	
=head2 binary()
	
Returns the NFB file in binary format. This method is used by 
the write() method when it outputs a file. It takes no parameters.

	my $rawdata = $nfb->binary();

=head1 INTERNALS NOTES

Internally, the NFB data is stored in little endian format.
All strings are the little endian version of UCS2 and are 
encoded or decoded using the Encode module. The file checksum 
is just a CRC32, so we use this function from the Compress::Zlib
module.

I have tested this module using data backed up using PC Suite 6
from a Nokia 7250 and a Nokia 7610. They both parse correctly.

=head1 SEE ALSO

Nokia::File::NFB::File

Nokia PC Suite - http://www.nokia.com/

Python based parser - http://www.dryfish.org/projects/nfb.html

=head1 AUTHOR

Robert Price, E<lt>rprice@cpan.orgE<gt>

http://www.robertprice.co.uk/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
