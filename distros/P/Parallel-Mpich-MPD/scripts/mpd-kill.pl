#!/usr/bin/env  perl

# read pidlist avery N seconds and (kill -9|STOP) a random pid
# usage mpd-kill.pl --time=5 --hostname=node-0.phenyxtest --username=evaleto --loop

use Data::Dumper;
use Parallel::Mpich::MPD;
use Proc::ProcessTable;


# mpd-killer --time 20 --hostname=node-0.phenyxtest
use Getopt::Long;
my($time, $hostname, $username, $verbose, $loop);
$time=1;
$usename="evaleto";
if (!GetOptions(
		"time=s"=>\$time,
		"hostname=s" =>\$hostname,
		"username=s" =>\$username,
		"verbose" =>\$verbose,
		"loop" =>\$loop,
)|!defined($hostname)|!defined($username)){
  printf STDERR "Usage:\n";
  printf STDERR "mpd-killer --time=5 --hostname=node-0.phenyxtest --username=evaleto \n\n";
  exit 1;
}



#$Parallel::Mpich::MPD::Common::DEBUG=1;
#$Parallel::Mpich::MPD::Common::WARN=1;

Parallel::Mpich::MPD::Common::env_Check();

print "#\n";
print "#\n";
my %cached_psids;
my @mpd_pids;
my $pid;
my @sleepingpids;
my $maxsleep=10;
my $index;
my $delay=0;

sub checkProc{
  my @tmp=@_;
  %cached_psids={};
  my %psids={};
  my $id=0;
  foreach $p (@tmp){
    print "$p, ";
    $psids{$p}=1;
  }
  
  Parallel::Mpich::MPD::Common::__exec(cmd => "id -u $username", stdout =>\$id);
  my $FORMAT = "%-6s %-8s %-24s %-3s %-30s\n";
  printf($FORMAT, "PID", "STAT", "START", "MPD", "COMMAND");
  $t = new Proc::ProcessTable(cache_ttys=>1);

  foreach $p ( @{$t->table} ){
    if ($id == $p->uid){
      $cached_psids{$p->pid}=1;
      printf($FORMAT,
          $p->pid,
          $p->state,
          scalar(localtime($p->start)),
          ($psids{$p->pid}==1)?"Yes":"No",
          $p->cmndline);
    }
  }
  print "\n\n";
}

my $lastcmd;
my %tmppids;
my $ret;
do{
  system "clear";
      
  %tmppids=Parallel::Mpich::MPD::findJob( username=>$username, return=>'host2pidlist', reloadlist=>(($delay % $time) ==1)?1:0);
  @mpd_pids= keys %{$tmppids{$hostname}};
  $pidcount=scalar @mpd_pids; 
  
  my %jobids=Parallel::Mpich::MPD::findJob(username=>$username);
  #mpd infos:
  print "\n\nmpd says : jobids [".join(', ',keys %jobids)."] are running on [". join(',',keys %tmppids)."]\n";
  print "           local pids [".join(', ',@mpd_pids)."]\n\n";      
  
  $index =int(rand($pidcount));
  if ($pidcount>0 && (($delay % $time) ==1)){
    $lastcmd="";
    if ($cached_psids{$mpd_pids[$index]}!=1){
        $lastcmd="WARNING(1)  pid ".$mpd_pids[$index]." is already dead !!! MPD doesn't update his psids\n";
    }elsif (int(rand(2)+0.5)==1){
    #
    # kill
    #
      $lastcmd= "kill -9 the pid ".$mpd_pids[$index]."\n";
      ($ret=Parallel::Mpich::MPD::Common::__exec(cmd =>  "/bin/kill -9 ". $mpd_pids[$index]))==0 or printf STDERR "ERROR: kill SIGKILL ".$mpd_pids[$index]. " return $ret\n";
    }else{
      if (int(rand($pidcount*2))==$index && defined($mpd_pids[$index])){      
        #
        #wakeup
        #
        $lastcmd= "wakeup the pid ".$mpd_pids[$index]."\n";
        ($ret=Parallel::Mpich::MPD::Common::__exec(cmd =>  "/bin/kill -18  ".$mpd_pids[$index]))==0 or printf STDERR "ERROR: continue SIGCONT ".$mpd_pids[$index]. " return $ret\n";
        $sleepingpids[$index]=undef;
      }
      $lastcmd.= "sleep the pid ".$mpd_pids[$index]."\n";
      #
      #sleep
      #
      $sleepingpids[$index]=$mpd_pids[$index];
      ($ret=Parallel::Mpich::MPD::Common::__exec(cmd =>  "/bin/kill -19 ".$mpd_pids[$index]))==0 or printf STDERR "ERROR: stop SIGSTOP ".$mpd_pids[$index]. " return $ret\n";
    }
    $delay=1;
  }  
  printf $lastcmd;
  $lastcmd="";
  checkProc(@mpd_pids);
  $delay++;
  sleep 2;
}while (1 && defined($loop));

