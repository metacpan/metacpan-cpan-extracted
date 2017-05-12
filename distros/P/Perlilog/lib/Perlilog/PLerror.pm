#
# This file is part of the Perlilog project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

package Perlilog::PLerror;
use strict 'vars';
require Exporter;

@Perlilog::PLerror::ISA = ('Exporter');
@Perlilog::PLerror::EXPORT = qw(blow puke wiz wizreport fishy wrong say hint wink);
%Perlilog::PLerror::evalhash = ();
%Perlilog::PLerror::packhash = ();

sub blow {
  { local $@; require Perlilog::PLerrsys; }  # XXX fix require to not clear $@?
  my $err = &Perlilog::linebreak("@_");
  die $err if $err =~ /\n$/; 
  chomp $err;
  die "$err ".oneplace()."\n";
}

sub puke {
  { local $@; require Perlilog::PLerrsys; }  # XXX fix require to not clear $@?
  my ($chain, $err)=&stackdump(@_);
  die(&Perlilog::linebreak($chain."\nError: $err"));
}

sub wiz {
  print &Perlilog::linebreak("@_");
}

sub wizreport {
  { local $@; require Perlilog::PLerrsys; }  # XXX fix require to not clear $@?
  my ($chain, $err)=&stackdump(@_);
  die(&Perlilog::linebreak($chain."\nWiz report: $err"));
}

sub fishy {
  my $warn = &Perlilog::linebreak("@_");
  chomp $warn;
  warn "$warn\n";
}

sub wrong { 
  die(&Perlilog::linebreak("@_")."\n");
  $Perlilog::wrongflag=1;
}

sub say {
  print "@_";
}

sub hint {
#  print "@_";
}

sub wink {
  print "@_";
}

sub register {
  my $fname = shift;
  my ($pack,$file,$line) = caller;
  $Perlilog::PLerror::evalhash{$file}=[$pack,$fname,$line];
  $Perlilog::PLerror::packhash{$pack}=$fname;
}

1;
