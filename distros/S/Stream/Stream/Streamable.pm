#!/usr/local/bin/perl -w

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Stream::Streamable;

@Streamable::ISA = qw(Stream::Streamable);

use strict;
use Carp;

use Stream::DataInputStream;
use Stream::DataOutputStream;
use Stream::StringInputStream;
use Stream::StringOutputStream;
use Stream::FileInputStream;
use Stream::FileOutputStream;


sub usage
{
    my ($package, $filename, $line, $subr) = caller(1);
	$Carp::CarpLevel = 2;
	croak "Usage: $subr(@_)"; 
}

sub save
{
	usage unless @_ == 1;

	my $sos = new StringOutputStream;
	shift->saveToDataStream(new DataOutputStream $sos);
	$sos->data();
}

sub restore
{
	usage("data") unless @_ == 2;

    my $type = shift;
	my $sis_data = shift || usage("data");

	(defined $sis_data) || return "Cannot restore from undefined data!";

	my $sis = new StringInputStream $sis_data;
	my $dis = new DataInputStream $sis;

	my $self = restoreFromDataStream $type $dis;
	return $self unless (ref($self) eq $type);

	unless ($dis->eoi())
	{
		return "Incorrect length input (".length($dis->readAll())." bytes too many)";
	}

	$self;
}

#
#	Restore an object from a file
#
sub restoreFromFile
{
	usage("filename") unless @_ == 2;

	my $type = shift;
	my $filename = shift;

	my $fis = new FileInputStream $filename;
	return unless defined $fis;
	my $dis = new DataInputStream $fis;

	restoreFromDataStream $type $dis;
}

#
#	Save an object to a file
#
sub saveToFile
{
	usage("filename") unless @_ == 2;

	my $self = shift;
	my $filename = shift;

	my $fos = new FileOutputStream $filename;
	my $dos = new DataOutputStream $fos;

	$self->saveToDataStream($dos);
}

1;
