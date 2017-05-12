# $Id: FullDuplexScalar.pm,v 1.2 2003/09/11 19:57:32 davidb Exp $
#
# Copyright (C) 2003 Verisign, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

package FullDuplexScalar;

# This class just combines two IO::Scalar handles into a full duplex
# file-handle-like thing.  It implements the bare minimum to be able
# to function as a fake socket in testing Net::BEEP::Lite.

use IO::Scalar;

use strict;
use warnings;


sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = {};
  bless $self, $class;

  $self->{in}  = new IO::Scalar(shift);
  $self->{out} = new IO::Scalar(shift);

  $self;
}

sub close {
  my $self = shift;

  $self->{in}->close();
  $self->{out}->close();
}

sub getline {
  my $self = shift;

  $self->{in}->getline(@_);
}

sub read {
  my $self = shift;

  $self->{in}->read(@_);
}

sub print {
  my $self = shift;

  $self->{out}->print(@_);
}

sub flush {
  my $self = shift;

  $self->{out}->flush(@_);
}

sub in {
  my $self = shift;

  $self->{in};
}

sub out {
  my $self = shift;

  $self->{out};
}

1;
