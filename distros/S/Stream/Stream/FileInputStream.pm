#!/usr/local/bin/perl -w

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Stream::FileInputStream;

@FileInputStream::ISA = qw(Stream::FileInputStream);

#
#	FileInputStream
#
#		Inherits from InputStream, redefining all of it's member
#		functions:
#			read
#			skip
#			readAll
#
#
#	Perhaps we should consider making this inherit from FileHandle?
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
	usage("FileHandle | filename") unless @_ == 2;

	my $type = shift; my $self = {}; bless $self, $type;
	my $arg = shift || usage("FileHandle | filename");

	if (ref($arg))
	{
		if (ref($arg) eq 'FileHandle')
		{
			$self->{'fh'} = $arg;
		}
		else
		{
			usage("FileHandle | filename");
		}
	}
	else
	{
		$self->{'fh'} = new FileHandle $arg, 'r';
		defined($self->{'fh'}) || return "Could not open $arg";
	}

	$self;
}

sub close
{
	shift->{'fh'}->close();
}

sub read
{
	usage("count") unless @_ == 2;

	my $self = shift;
	my $count = shift;
	my $fh = $self->{'fh'};

	my $retval = "";
	read($fh, $retval, $count) || return;
	$retval;
}

sub seek
{
	usage("type count") unless @_ == 3;

	my $self = shift;
	my $type = shift;
	my $count = shift;
	$self->{'fh'}->seek($type, $count);
}

sub skip
{
croak("Not yet implemented");
	usage("count") unless @_ == 2;

	my $self = shift;
	my $count = shift;
	my $fh = $self->{'fh'};

	my $data = $fh->read($count);
}

sub readAll
{
	usage unless @_ == 1;

	my $self = shift;
	my $fh = $self->{'fh'};

	my $save_sep = $/;
	undef $/;
	my $retval = <$fh>;
	$/ = $save_sep;

	$retval;
}

sub eoi
{
	usage unless @_ == 1;
	
	eof(shift->{'fh'});
}

1;
