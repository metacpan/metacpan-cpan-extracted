package Parallel::Mpich::MPD::Job;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Parallel::Mpich::MPD::Common;

=head1 NAME

Parallel::Mpich::MPD::Job - Mpich MPD job wrapper

=head1 SYNOPSIS

=head1 EXPORT

=head1 FUNCTIONS

=head1 METHOD

=head2 infos

Get information of this job. Information contains these values:
  my %info=$job->infos();
  $info{jobid}; 
  $info{jobalias};
  $info{username};
  $info{hosts}[0..N]{host};
  $info{hosts}[0..N]{pid};
  $info{hosts}[0..N]{sid};
  $info{hosts}[0..N]{rank};
  $info{hosts}[0..N]{cmd};

=head2 kill

Kill this job. See examples:
  Parallel::Mpich::MPD::findJob(alias => 'olivier1')->kill();
  Parallel::Mpich::MPD::findJob(jobid => '1@linux02_32996')->kill();

=head2 signal

Send a sig to this job. 
It return false if not ok.
examples:
  # SIGQUIT, SIGKILL, SIGSTOP, SIGCONT, SIGXCPU, SIGUSR1, SIGUSR2  
  Parallel::Mpich::MPD::findJob(alias => 'olivier1')->signal("SIGSTOP");
  Parallel::Mpich::MPD::findJob(alias => 'olivier1')->signal("SIGCONT");
  Parallel::Mpich::MPD::findJob(jobid => '1@linux02_32996')->kill();

=over 4

  NOTE:
  You couLd check the state with the following ps command:
  ps -eo state,nice,user,comm
  ps state des:
  D    Uninterruptible sleep (usually IO)
  R    Running or runnable (on run queue)
  S    Interruptible sleep (waiting for an event to complete)
  T    Stopped, either by a job control signal or because it is being traced.
  W    paging (not valid since the 2.6.xx kernel)
  X    dead (should never be seen)
  Z    Defunct ("zombie") process, terminated but not reaped by its parent.

=back

=head2 sig_stop

Stop this job.
return false if not ok

=head2 sig_cont

Continue this job.
return false if not ok

=head2 kill

Send a kill signal

=head2 equals($job)

compare towo jobs and return true/false
FIXME.: should be implemented 

=head2 toSummaryString

return a string for the current job

=head1 AUTHOR

Olivier Evalet, Alexandre Masselot, C<< <alexandre.masselot at genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parallel-mpich-mpd at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parallel-Mpich-MPD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parallel::Mpich::MPD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parallel-Mpich-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parallel-Mpich-MPD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parallel-Mpich-MPD>

=item * Search CPAN

L<http://search.cpan.org/dist/Parallel-Mpich-MPD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Olivier Evalet, Alexandre Masselot, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use Object::InsideOut;
my @jobid :Field(Accessor => 'jobid');
#my @infos :Field(Accessor => 'infos');
my @jobalias :Field(Accessor => 'jobalias');
my @username :Field(Accessor => 'username');
my @hosts :Field(Accessor => '_hosts', Type=> 'List', Permission => 'private');


# Query or Manage a Job instance defined by his jobid. 
my %init_args :InitArgs = (
			   JOBALIAS=>qr/^jobalias$/i,
			   JOBID=>qr/^jobid$/i,
			  );
sub _init :Init{
  my ($self, $h) = @_;
  $self->jobalias($h->{JOBALIAS})if $h->{JOBALIAS};
  $self->jobid($h->{JOBID}) if $h->{JOBID};
  $self->_hosts([]);
}

sub _automethod :Automethod{
  my ($self, $val) = @_;
  my $set=exists $_[1];
  my $name=$_;
  if ($name=~/sig(kill|cont|stop)/){
    my $sig=uc $1;
    return sub{
              return $self->signal("SIG$sig");
	    }
  }
}

# n host index  return hash of host
# k key         return value of the key
# v value       set value of the key

sub hosts{
  my ($self, $n, $k, $val)=@_;

  #return the array
  unless(defined $n){
    return wantarray?@{$self->_hosts()}:$self->_hosts();
  }
  unless(defined $k){
    return $self->_hosts()->[$n];
  }

  my $reHostField="(host|pid|sid|rank|cmd)";
  croak "host parameter not in $reHostField" unless $k=~/^$reHostField$/o;
  if(defined $val){
    $self->_hosts()->[$n]{$k}=$val;
    return $val;
  }
  return $self->_hosts()->[$n]{$k};
}

sub hosts_push{
  my ($self, $h)=@_;
  push @{$self->_hosts()}, $h;
}


# \$out \$err
sub kill{
  my $this=shift;
  my ($out,$err)=@_;
  my $stdout="";
  my $stderr="";
  my $pid="";
  env_Init() unless defined(%env);
  my $params;
  $params=$this->jobid();

  my $ret=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdkilljob')." $params");
  return $ret==0;
}

# return true if the criteria match this job
#  $criteria{pid} [ && $criteria{rank}]
#  $criteria{jobid}
#  $criteria{jobalias}
#  $criteria{username}

sub equals{
  my $this=shift;
  my %criteria=@_;
  
  #print Dumper \%criteria;
  #print $this;
  
  if (defined($criteria{jobalias}) &&  $criteria{jobalias}{$this->jobalias}){
    return 1;
  }
  
  if (defined($criteria{username}) &&  $criteria{username}{$this->username}){
    return 1;
  }
  
  if (defined($criteria{jobid}) &&  $criteria{jobid}{$this->jobid}){
    return 1;
  }
  
  foreach my $host (@{$this->_hosts()}){
    if (defined($criteria{pid})) {
      if (defined($criteria{rank})) {
        return 1 if ($criteria{rank} eq $host->{rank} && $criteria{pid} eq $host->{rank});
      }else{
        return 1 if ($criteria{pid} eq $host->{pid});
      }
    }
  }
  
}

# Send a signal to all process for the current job.
# SIGQUIT, SIGKILL, SIGSTOP, SIGCONT, SIGXCPU, SIGUSR1, SIGUSR2
sub signal{
  my $stdout="";
  my $stderr="";
  my $pid="";
  my $this=shift;
  my ($sigtype)=@_;
  if (!defined($sigtype)){
    printf STDERR "ERROR:".__PACKAGE__."::__sig() sigtype is not defined. \n";
    return 0;
  } 
  env_Init() unless defined(%env);
  my $params;
  $params="-j ".$this->jobid();

  my $ret=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdsigjob')." $sigtype $params");

  return $ret==0;
}

#sub stop{  
#  my $this=shift;
#  return $this->signal("SIGSTOP");
#}

#sub continue{  
#  my $this=shift;
#  return $this->signal("SIGCONT");
#}

#sub destroy{  
#  my $this=shift;
#  return $this->signal("SIGKILL");
#}


use overload '""' => \&toSummaryString;

sub toSummaryString{
  my $self=shift;

  my $ret=$self->jobid."\t(alias='".$self->jobalias."', user='".$self->username."')\n";
  my @h=$self->hosts();
  foreach (sort {$a->{rank} <=> $b->{rank}} @h){
    $ret.="$_->{rank}\t".($_->{host}||'')."\t".($_->{pid}||'')."\t".($_->{sid}||'')."\t".($_->{pgm}||'')."\n";
  }
  return $ret."\n";
}


1; # End of Parallel::Mpich::MPD
