package Nokia::File::NFB::Element;

## Create and Write a Nokia NFB file element.
## Robert Price - http://www.robertprice.co.uk/

use 5.00503;
use strict;
use utf8;
use vars qw($VERSION);

use Carp;
use Encode qw(encode);

$VERSION = '0.01';


## new()
## the object creation method
## INPUT: type - the type of the entry (1 = file, 2 = directory)
##	name - the name of the entry
##	time - the timestamp of the entry
## 	data - the binary data
## OUTPUT: blessed hash representing the object
sub new {
	my $class = shift;
	my $params = shift;
	my $self = {
		'type'		=> $params->{'type'} || '',
		'name'		=> $params->{'name'} || '',
		'timestamp'	=> $params->{'time'} || CORE::time,	## default to now if no time is given.
		'data'		=> $params->{'data'} || '',
	};
	$self->{'size'} = length($self->{'data'}) || 0;
	bless $self, $class;
	return $self;
}


#use overload '""' => \&pretty_print;
## pretty_print()
## display the contents of the object nicely
## OUTPUT: string containing a version of the object suitable
##	for printing.
sub pretty_print {
	my $self = shift;
	my $string = "------------------------------------------------\n";
	$string .= ' NAME: ' . $self->{'name'} . "\n";
	$string .= ' TYPE: ' . $self->{'type'} . "\n";
	if ($self->{'type'} == 1) {
		$string .= 'SIZE: ' . $self->{'size'} . "\n";
		if ($self->{'time'}) {
			$string .= 'TIME: ' . $self->{'time'} . ' - ' . localtime($self->{'time'}) . "\n";		
		}
	}
	$string .= "------------------------------------------------\n";
	return $string;
}


## type()
## get or set the entry type for the element.
## INPUT: type - the type (1 = file, 2 = directory) (optional)
## OUTPUT: the type
sub type {
	my $self = shift;
	if ($_[0]) {
		my $type = shift;
		croak("Unknown type $type\nCan only be 1 or 2\n")	unless ($type == 1 || $type ==2);
		$self->{'type'} = $type;
	}
	return $self->{'type'};
}


## timestamp()
## get or set the timestamp for the element.
## INPUT: timestamp - creation time in seconds since epoch (optional)
## OUTPUT: timestamp - the timestmap of the element.
sub timestamp {
	my $self = shift;
	if ($_[0]) {
		my $time = shift;
		croak("Unknown time format, must be seconds since epoch\n")	unless ($time =~ /^\d+$/);
		$self->{'time'} = $time;
	}
	return $self->{'time'};
}


## name()
## get or set the filename of the element.
## INPUT: name - the name of the file / directory (optional).
## OUTPUT: name - the name of the file / directory.
sub name {
	my $self = shift;
	$self->{'name'}	= $_[0]	if ($_[0]);
	return $self->{'name'};
}


## data()
## get or set the data in the element.
## INPUT: data - the data of the file.
## OUTPUT: data - the data of the file.
sub data {
	my $self = shift;
	if ($_[0]) {
		$self->{'data'}	= $_[0];
		$self->{'size'} = length($self->{'data'});
	}
	return $self->{'data'};
}


## size()
## get the size of the data.
## OUTPUT: size - the size of the data.
sub size {
	my $self = shift;
	return $self->{'size'};
}


## binary
## return the object in a binary format suitable for insertion
## in a NFB file.
## OUTPUT: binary - the binary representation of the data.
sub binary {
	my $self = shift;
	my $binfile;

	croak("Need at least a name and type to generate binary element\n")
		unless(($self->{'type'}) && ($self->{'name'}));

	$binfile .= pack('V',$self->{'type'});
	$binfile .= pack('V', length($self->{'name'}));
	$binfile .= encode('UCS-2LE', $self->{'name'});
	
	if ($self->{'type'} == 1) {
		$binfile .= pack('V', length($self->{'data'}));
		$binfile .= $self->{'data'};
		$binfile .= pack('V', ($self->{'time'} ? $self->{'time'} : CORE::time()));
	}
	return $binfile;
}

1;
__END__

=head1 NAME

Nokia::File::NFB::Element - storage for a NFB file element.

=head1 SYNOPSIS

  use Nokia::File::NFB::Element;
  
  ## create an object.
  my $element = Nokia::File::NFB::Element({
  	'name'	=> $filename,
  	'type'	=> $filetype,
  	'time'	=> $timestamp,
  	'data'	=> $rawdata,
  });
  
  ## pretty print it.
  print $element->pretty_print(), "\n";
  
  ## check if the filename is /CALENDAR
  if ($element->name() eq '/CALENDAR') {
  
  	## chang the filename.
  	$element->name('/CALENDAR2');
  }
  
  ## put the binary representation of the data into a filehandle.
  print FH $element->binary();

=head1 DESCRIPTION

This module is used to store file elements from a Nokia NFB file.

It is mainly used internally from Nokia::File::NFB,
but can be used to create or modify data to be included in an
NFB file.

=head1 METHODS

=head2 new()

Creates a new Nokia::File::NFB::Element object.

	my nfb = Nokia::File::NFB::Element->new({
		'type'		=> $filetype,
		'name'		=> $filename,
		'timestamp'	=> $timestamp,
		'data'		=> $data,
	});
	
All the elements are optional at creation stage and can be added 
at later.

type - This is the type of file. It can be either '1' to represent a
FILE, or '2' to represent a directory.

name - The name of the file or directory this element represents.

timestamp - The timestamp of the file. If none is given it takes the current
time from the system clock.

data - The raw data contained in the element.

=head2 type()

Get or set the filetype of the element.

	## make the element a FILE.
	$nfb->type(1);	

	## show the element's file type.
	print "The file type is: " . $nfb->type();

The value passed in can only be '1' to represent a file, or '2' to 
represent a directory.

=head2 name()

Get or set the filename of the element.

	## set the filename to be \Calendar.
	$nfb->type('\\Calendar');	

	## show the element's file name.
	print "The file name is: " . $nfb->name();

=head2 timestamp()

Get or set the timestamp of the element.

	## set the timestamp to be the current time.
	$nfb->timestamp(time());	

	## show the element's timestamp.
	print "The timestamp is: " . $nfb->timestamp();

=head2 data()

Get or set the data of the element.

	## set the data.
	$nfb->data($testdata);	

	## get the element's data.
	my $testdata = $nfb->data();

=head2 size()

Get the size of the data part of the element.

	## get the size of the data.
	my $datasize = $nfb->size();

=head2 binary()

Return the element in binary format. This is suitable for the 
Nokia::File::NFB::Element to use directly.

	## return the element in binary format.
	my $element = $nfb->binary();

=head2 pretty_print()

Return a string with the elements (except the raw data) in a format
suitable for debugging.

	## print the element.
	print $nfb->pretty_print();

=head1 SEE ALSO

Nokia::File::NFB

Nokia PC Suite - http://www.nokia.com/

=head1 AUTHOR

Robert Price, E<lt>rprice@cpan.orgE<gt>

http://www.robertprice.co.uk/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
