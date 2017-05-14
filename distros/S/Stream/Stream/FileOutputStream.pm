#!/usr/local/bin/perl -w

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Stream::FileOutputStream;

@FileOutputStream::ISA = qw(Stream::FileOutputStream);

#
#	FileOutputStream
#
#		Inherits from OutputStream, redefining all of it's member
#		functions:
#			write
#
#
#   Perhaps we should consider making this inherit from FileHandle?
#


use strict;
use Carp;
use FileHandle;
use POSIX;

sub usage
{
    my ($package, $filename, $line, $subr) = caller(1);
	$Carp::CarpLevel = 2;
	croak "Usage: $subr(@_)"; 
}

sub new
{
	usage("FileHandle") unless @_ == 2;

	my $type = shift; my $self = {}; bless $self, $type;

	my $arg = shift;

	if (defined ref($arg) && ref($arg) eq 'FileHandle')
	{
		$self->{'fh'} = $arg;
	}
	else
	{
		$self->{'fh'} = new FileHandle $arg, 'w';
		(defined($self->{'fh'})) || return "Could not open $arg";
	}

	$self;
}

sub close
{
    shift->{'fh'}->close();
}

sub write
{
	usage("data") unless @_ == 2;

	my $self = shift;
	my $data = shift;

	$self->{'fh'}->print($data);
}

1;
