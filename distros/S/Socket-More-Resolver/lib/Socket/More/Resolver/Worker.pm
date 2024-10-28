package Socket::More::Resolver::Worker;
use strict;
use warnings;
use feature "say";
unless(caller){
  $0="S::M::R::T";
  my $gai_data_pack="l> l> l> l> l>/a* l>/a*";
  my $gai_pack="($gai_data_pack)*";

  package main;
  use feature "say";
  #use POSIX ":sys_wait_h"; 
  #use constant::more DEBUG=>0;
  #use constant::more qw<CMD_GAI=0 CMD_GNI CMD_SPAWN CMD_KILL CMD_REAP>;
  BEGIN {
    *DEBUG=sub {0};
    *CMD_GAI=sub {0};
    *CMD_GNI=sub {1};
    *CMD_SPAWN=sub {2};
    *CMD_KILL=sub {3};
    *CMD_REAP=sub {4};
    *WNOHANG=sub {1};
  }

  # process any command line arguments for input and output FDs
  my $run=1;
  my @in_fds;
  my @out_fds;
  my $use_core=0;#=1;
  while(@ARGV){
    local $_=shift;  
    if(/--in/){
        @in_fds=split ",", shift;
        next;
    }
    if(/--out/){
        @out_fds=split ",", shift;
        next;
    }
  }
  
  DEBUG and say STDERR "TEMPLATE: ins: @in_fds";
  DEBUG and say STDERR "TEMPLATE: outs: @out_fds";

  # Pipes back to the API
  #
  open my $in,  "<&=$in_fds[0]" or die $!;
  open my $out, ">&=$out_fds[0]" or die $!;
  #$out->autoflush;

  #Simply loop over inputs and outputs
  DEBUG and say STDERR "Worker waiting for line ...";
  my $counter=0;
  while(<$in>){

    DEBUG and say STDERR "Worker got line...";
    $0="S::M::R::W-".$counter++;
    #parse
    # Host, port, hints
    chomp;  

    my $bin=pack "H*", $_;
    my ($cmd, $req_id)=unpack "l> l>", $bin;
    $bin=substr $bin, 8;

    DEBUG and say STDERR "WORKER $$ REQUEST,  ID: $req_id";

    my $return_out=pack "l> l>", $cmd, $req_id;
    if($cmd == CMD_SPAWN){
      #Fork from me. Presumably the template
      my $pid=fork;
      if($pid){
        #Parent
        # return message back to API with PID of offspring 
        DEBUG and say STDERR "FORKED WORKER... in parent child is $pid";
        $return_out.=pack "l>", $pid;
      }
      else {
        #child.

        $0="S::M::R::W";
        DEBUG and say STDERR "FORKED WORKER... child with fds";
        my ($in_fd, $out_fd)=unpack "l> l>", $bin;
        close $in;
        close $out;
        
        DEBUG and say STDERR "infd $in_fd, out_fd $out_fd";
        open $in,  "<&=$in_fd" or die $!;
        open $out, ">&=$out_fd" or die $!;

        next; #Do not respond.
      }

    }
    elsif($cmd== CMD_GAI){
      #Assume a request
      my @e =unpack $gai_pack, $bin;
      my @results;
      my $port=pop @e;
      my $host=pop @e;
      DEBUG and say STDERR "WORKER $$ PROCESSIG GAI REQUEST, id: $req_id";
      my $rc;


      if($use_core){
        require Socket;
        my %hints=@e;
        ($rc, @results)=Socket::getaddrinfo($host, $port, \%hints);
        if($rc){
          my $a=[$rc+0, -1, -1, -1, "", ""];
          $return_out.=pack($gai_data_pack, @$a);
        }
        else {
          for(@results){
            my $a=[$rc, $_->{family}, $_->{socktype}, $_->{protocol}, $_->{addr}, $_->{cannonname}//""];
            $return_out.=pack($gai_data_pack, @$a);
          }
        }
      }
      else {
        use Data::Dumper;
        require Socket::More::Lookup;
        DEBUG and say STDERR "host $host, port $port";
        $rc=Socket::More::Lookup::getaddrinfo($host, $port, \@e, \@results);
        unless (defined $rc){
          $results[0]=[$!, -1, -1, -1, "", ""];
        }

        for(@results){
          $return_out.=pack($gai_data_pack, @$_);
        }
      }
      use Data::Dumper;
      DEBUG and say STDERR Dumper @results;
    }

    elsif($cmd==CMD_GNI){
      DEBUG and say STDERR "WORKER $$ PROCESSIG GNI REQUEST, id: $req_id";
      my @e=unpack "l>/a* l>", $bin;
      if($use_core){
        require Socket;
        my($rc, $host, $service)=Socket::getnameinfo(@e);
        $return_out.=pack "l> l>/a* l>/a*",$rc, $host, $service;
      }
      else {
        require Socket::More::Lookup;
        my $rc=Socket::More::Lookup::getnameinfo($e[0],my $host="", my $service="", $e[1]);

        DEBUG and say STDERR "worker side rc $rc";
        DEBUG and say STDERR "worker side host $host";
        DEBUG and say STDERR "worker side service Service $service";

        unless (defined $rc){
          $return_out.=pack "l> l>/a* l>/a*",$!, $host, $service;

        }
        else {

          $return_out.=pack "l> l>/a* l>/a*",0, $host, $service;
        }
      }
    }

    elsif($cmd==CMD_KILL){
      # worker needs to exit
      # 
      $run=undef;
    }
    elsif($cmd==CMD_REAP){
      #
      my @pids=unpack "l>/l>*", $bin;
      DEBUG and say STDERR "WORKER $$ REAP HANDLER @pids";
      my @reaped;
      for(@pids){
        my $ret;
        if($_){
          # Only do the syscall if the pid is non zero
          $ret=waitpid $_, WNOHANG;
        }
        else {
          $ret=0;
        }
        push @reaped, $ret;
      }
      DEBUG and say STDERR "WORKER Reaped @reaped";
      $return_out.=pack "l>/l>*", @reaped;
    }

    else {
      die "Unkown command";
    }

    DEBUG and say STDERR "** BEFORE WORKER WRITE $$";
    syswrite $out, unpack("H*", $return_out)."\n" or say $!;
    DEBUG and say STDERR "** AFTER WORKER WRITE $$";

    last unless $run;
  }

  DEBUG and say STDERR "** EXITING WORKER $$";
}

1;
