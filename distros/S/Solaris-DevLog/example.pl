#!/usr/local/bin/perl -w
# $Id: example.pl,v 1.1 2002/02/11 21:51:44 bossert Exp $
# Project:  Solaris::DevLog
# File:     example.pl
# Author:   Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>
#
# Copyright (c) 2002 Greg Bossert
#
# This Perl module and its is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use strict;

use Solaris::DevLog qw(:flags);

# create a new devlog
my $devlog;
eval {
  $devlog = new Solaris::DevLog() 
};
die "$0: could not create new Solaris::DevLog ($@)" if $@;

# get the file descriptor
my ($fd) = $devlog->stream_fd;
print "$0: stream file descriptor is $fd\n";

# get 3 messages
for (1..3) {

  ### blocking select ###
  $devlog->select(undef);

  my ($status, $ctl, $data) = $devlog->getmsg();

  if ($status) {
    print 
      "$0: Error reading message:\n",
      "\tstatus: $status\n",
  }
  else {

    my $where;

    if ($ctl->{flags} & SL_ERROR) {
      $where = "error";
    }
    if ($ctl->{flags} & SL_CONSOLE) {
      $where = "console";
    }
    if ($ctl->{flags} & SL_TRACE) {
      $where = "trace";
    }

    print
      "$0: New Message to $where log:\n",
      "\tstatus: $status\n",
      
      "\tdata: $data\n",
      
      "\tcontrol hash:\n",
      "\t\tmid: $ctl->{mid}\n",
      "\t\tsid: $ctl->{sid}\n",
      "\t\tlevel: $ctl->{level}\n",
      "\t\tflags: $ctl->{flags}\n",
      "\t\tltime: $ctl->{ltime}\n",
      "\t\tttime: ", scalar localtime($ctl->{ttime}), "\n",
      "\t\tseq_no: $ctl->{seq_no}\n",
      "\t\tpri: $ctl->{pri}\n",
      "###\n";    
  }
}

exit;

########################################################################
# end file example.pl
########################################################################
