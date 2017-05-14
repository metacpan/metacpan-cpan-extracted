#!/usr/local/bin/perl -w

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Stream::DataInputStream;

@DataInputStream::ISA = qw(Stream::DataInputStream);

#
#	DataInputStream
#
#		Inherits from InputStream (read, skip & readAll)
#
#		Implements DataInput (the read*, skip and readAll functions)
#
#		Uses an InputStream for its input
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
	usage unless @_ == 2;
	usage("InputStream undefined") unless defined $_[1];

	my $type = shift; my $self = {}; bless $self, $type;

	$self->{'is'} = shift || croak("InputStream undefined");

	$self;
}

sub read
{
	usage("count") unless @_ == 2;

	my $self = shift;
	my $count = shift;
	my $is = $self->{'is'};

	$is->read($count);
}

sub skip
{
	usage("count") unless @_ == 2;

	my $self = shift;
	my $count = shift;
	my $is = $self->{'is'};

	$is->skip($count);
}

sub readAll
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	$is->readAll();
}

sub eoi
{
	usage unless @_ == 1;

	my $self = shift;
	$self->{'is'}->eoi();
}


sub readByte
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $c = $is->read(1);
	return unless (defined($c));
	unpack("C", $c);
}

sub readInt16
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $data = $is->read(2);
	return unless (defined($data));
	unpack("n", $data);
}

sub readInt32
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $data = $is->read(4);
	return unless (defined($data));
	unpack("N", $data);
}

sub readFloat
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $data = $is->read(4);
	return unless (defined($data));
	unpack("f", pack("l", unpack("N", $data)));
}

sub readDouble
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $data1 = $is->read(4);
	my $data2 = $is->read(4);
	return unless (defined($data1));
	return unless (defined($data2));
	# The following is machine dependent!
	unpack("d", pack("l", unpack("N", $data2)) . pack("l", unpack("N", $data1)));
}

sub readTime
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $data = $is->read(4);
	return unless (defined($data));
	unpack("N", $data);
}

sub readLength
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $s = 0;
	for(;;)
	{
		my $c = $is->read(1);
		return unless (defined($c));
		my $n = ord($c);
		$s = ($s << 7) + (0x7F & $n);
		last if ($n < 128);		# Last octet
	}
	$s;
}

sub readString
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	my $len = $self->readLength();
	return unless defined $len;
	$is->read($len);
}

sub readLine
{
	usage unless @_ == 1;

	my $self = shift;
	my $is = $self->{'is'};

	return if $is->eoi();

	my $r = '';
	for (;;)
	{
		$_ = $is->read(1);
		last unless (defined($_));
		if (/\n/)
		{
			chop($r) if ((length($r) > 0) && (substr($r, -1, 1) eq '\r'));
			last;
		}
		$r .= $_;
	}
	$r;
}

1;
