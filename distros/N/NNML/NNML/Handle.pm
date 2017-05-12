#                              -*- Mode: Perl -*- 
# Handle.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb 27 15:03:57 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Feb 28 12:09:50 1997
# Language        : CPerl
# Update Count    : 21
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Universität Dortmund, all rights reserved.
# 

package NNML::Handle;
use Net::Cmd;
use IO::Socket;
use vars qw(@ISA);
use strict;
use Carp;

@ISA = qw(Net::Cmd IO::Socket::INET);

# Snarfed from Net::Cmd; we don't expect an answer.
sub dataend
{
 my $cmd = shift;

 return 1
    unless(exists ${*$cmd}{'net_cmd_lastch'});

 if(${*$cmd}{'net_cmd_lastch'} eq "\015")
  {
   syswrite($cmd,"\012",1);
   print STDERR "\n"
    if($cmd->debug);
  }
 elsif(${*$cmd}{'net_cmd_lastch'} ne "\012")
  {
   syswrite($cmd,"\015\012",2);
   print STDERR "\n"
    if($cmd->debug);
  }

 print STDERR "$cmd>>> .\n"
    if($cmd->debug);

 syswrite($cmd,".\015\012",3);

 delete ${*$cmd}{'net_cmd_lastch'};

}

1;
