use strict;
package Phenyx::Utils::LSF::JobInfo;

=head1 NAME

Phenyx::Utils::LSF::JobInfo

=head1 SYNOPSIS


=head1 DESCRIPTION

Get info from LSF submited jobs

LSF master can be remote (setting $SHELLCOMMANDPREFIX)

=head1 FUNCTIONS

=head3 parseBJobs($job1 [,$job2 [...]]);

=head3 parseBJobs("-a"); #or whatever bjobs arguments that produce a same output

issue a bjobs command a returns a hash jobid => hash corresponding to bjobs output


=head3 jobInfo($jobid, $tag);

Returns a tag for a job (tags are bjobs command header, i.e. EXEC_HOST, QUEUE...)

=head3 isJobStarted($jobid);

Returns is a given job has been started (STAT is (PEND|PSUSP|RUN|USUSP|SSUSP))

=head3 isJobRunning($jobid);

Returns is a given job is currently running (STAT is 'RUN')

=head3 isJobFinished($jobid);

Returns is a given job has completed (error or not) (STAT is (DONE|EXIT|ZOMBI))

=head1 GLOBAL VARIABLES

=head1 SHELLCOMMANDPREFIX

A shell prefix (typically 'ssh user@lsf.host.name') to be preprend to any bjobs or whatever command.t

=head1 EXAMPLES

See t/ directories

=head1 SEE ALSO

bsub

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com


=cut

our $SHELLCOMMANDPREFIX;
our $CHEAT_BJOBS_COMMAND;

sub isJobStarted{
  my $jobid=shift or die __PACKAGE__.": must provide a jobid as first arg to jobStat()";
  my $stat=jobInfo($jobid, 'STAT');
  return $stat=~/^(PEND|PSUSP|RUN|USUSP|SSUSP)$/ || isJobFinished($jobid);
}

sub isJobRunning{
  my $jobid=shift or die __PACKAGE__.": must provide a jobid as first arg to jobStat()";
  my $stat=jobInfo($jobid, 'STAT');
  return $stat=~/^(RUN)$/ || isJobFinished($jobid);
}
sub isJobFinished{
  my $jobid=shift or die __PACKAGE__.": must provide a jobid as first arg to jobStat()";
  my $stat=jobInfo($jobid, 'STAT');
  return $stat=~/^(DONE|EXIT|ZOMBI)$/;
}

sub jobInfo{
  my $jobid=shift or die __PACKAGE__.": must provide a jobid as first arg to jobStat()";
  my $tag=shift or die __PACKAGE__.": must provide a tag as second arg to jobStat()";
  my %jobs;
  %jobs=parseBJobs($jobid);
  return $jobs{$jobid}{$tag};
}

sub parseBJobs{
  my $cmd;
  unless($CHEAT_BJOBS_COMMAND){
    $cmd="$SHELLCOMMANDPREFIX bjobs @_";
  }else{
    $cmd=$CHEAT_BJOBS_COMMAND;
  }

  my $fd;
  open ($fd, "$cmd|") or die "cannot execute command $cmd: $!";

  my $header=<$fd>;
  chomp $header;
  my @title2pos;
  while ($header=~/(\S+\s*)/g){
    my $tag=$1;
    my $start=$-[1];
    my $len=length $tag;
    $tag=~s/\s*$//;
    push @title2pos, {tag=>$tag,
		      start=>$start,
			length=>$len,
		      };
  }

  my %jobs;
  my $curJob;
  while (my $line=<$fd>){
    my %line;
    foreach my $h(@title2pos){
      my $val=substr $line, $h->{start}, $h->{length};
      $val=~s/\s*$//;
      $line{$h->{tag}}=$val;
    }
    if($line{JOBID}){
      $jobs{$line{JOBID}}={
			   JOBID=>$line{JOBID},
			   EXEC_HOST=>[]
			  };
      $curJob=$jobs{$line{JOBID}};
    }else{
      die "no JOBID was defined when reading [$line]" unless defined $curJob;
    }
    foreach my $tag (keys %line){
      if($tag eq 'EXEC_HOST'){
	foreach (split /,/, $line{$tag}){
	  if(/(\d+)\*(.*)/){
	      foreach (1..$1){
		push @{$curJob->{EXEC_HOST}}, $2;
		
	      }
	    }else{
	      push @{$curJob->{EXEC_HOST}}, $_;
	    }
	}
	}else{
	  if($line{$tag}=~/\S/){
	    if($curJob->{$tag}){
	      $curJob->{$tag}.=" $line{$tag}";
	    }else{
	      $curJob->{$tag}=$line{$tag};
	    }
	  }
	}
    }
  }
  return %jobs;
}
1;
