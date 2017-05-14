#!/usr/local/bin/perl -w

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Stream::StringOutputStream;

@StringOutputStream::ISA = qw(Stream::StringOutputStream);

#
#	StringOutputStream
#
#		Inherits from OutputStream, redefining all of it's member
#		functions:
#			write
#

use strict;
use Carp;


sub usage
{
    my ($package, $filename, $line, $subr) = caller(1);
	$Carp::CarpLevel = 2;
	croak "Usage: $subr(@_)"; 
}

sub new
{
	usage("") unless @_ == 1;

	my $type = shift; my $self = {}; bless $self, $type;

	$self->{'data'} = '';

	$self;
}

sub write
{
	usage("data") unless @_ == 2;

	my $self = shift;
	my $data = shift || usage("data");

	$self->{'data'} .= $data;
}


sub data
{
	usage("") unless @_ == 1;

	shift->{'data'};
}

1;
