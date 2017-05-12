package Net::OICQ::ClientEvent;

# $Id: ClientEvent.pm,v 1.1 2007/01/02 21:08:52 tans Exp $

# Copyright (c) 2003 - 2006 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

use strict;
use warnings;
use Carp;
use Net::OICQ::Event;
eval "no encoding; use bytes;" if $] >= 5.008;

our @ISA = qw(Net::OICQ::Event);

sub new {
	my ($class, $header, $data, $oicq) = @_;
	croak "Error: OICQ object missing for new ClientEvent" unless defined($oicq);
	my $self = {
		Time => time(),
		OICQ => $oicq,
		Header => $header,
		Data => $data
	};
	bless $self, $class;
	$self->process;
	return $self;
}

sub uid {
	substr(shift->{Header}, 7, 4)
}

1
