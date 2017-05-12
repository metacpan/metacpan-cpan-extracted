# $Date: 2004/03/25 22:58:20 $
# $Revision: 1.14 $ 

package Net::Z3950::AsyncZ;
our $VERSION = '0.10';
use Net::Z3950::AsyncZ::Options::_params;
use Net::Z3950::AsyncZ::Errors;
use Net::Z3950::AsyncZ::ZLoop;
use Net::Z3950::AsyncZ::ErrMsg;
use Event;
use POSIX ":sys_wait_h";
use Symbol;
use Exporter;
use sigtrap qw (die untrapped normal-signals die error-signals);
@ISA=qw (Exporter);
@EXPORT_OK = qw(asyncZOptions isZ_MARC isZ_GRS isZ_RAW isZ_Error isZ_nonRetryable isZ_Info
                isZ_DEFAULT noZ_Response isZ_Header isZ_ServerName Z_serverName getZ_RecNum 
		getZ_RecSize delZ_header delZ_pid delZ_serverName prep_Raw get_ZRawRec
               );
%EXPORT_TAGS = (
	       record => [qw(isZ_MARC isZ_GRS isZ_RAW isZ_DEFAULT getZ_RecNum getZ_RecSize)],
               errors => [qw(isZ_Error isZ_nonRetryable)],
               header => [qw(isZ_ServerName Z_serverName noZ_Response isZ_Header
                              delZ_header delZ_pid delZ_serverName isZ_Info)]
	);


use IPC::ShareLite qw( LOCK_EX);

use strict;

my %forkedPID=();   # pids of forked process saved in hash:
			# keys = pids, values = our indexes to forked processes  
		    # these deleted when fork data is processed
		    # if there are no keys left in hash, then the timer loop exits
my %exitCode=();  # saves exit codes of forked processes
                         # keys = pids, values = exit codes
		  # processes without 0 values are killed in DESTROY to prevent zombies
my %resultTable = (); # saves pids, hosts and report results of child processes 
 # keys = pids, values = [ host, report_results, index, retry_index ]
 #
 # SLOT 0 	host server address
 # SLOT 1       report results: boolean = true if report, false if not  
 # SLOT 2	index of process in current cycle (original or retry)
 # SLOT 3       retry_index:
 #            		# -1, -2 or index of process retrying a failed query 
 #	        	# initialized to -1 in original cycle,-2 in retry cycle 
 #             		 	(a positive retry_index replaces original cycle's -1)
 #             		# the retry_index is always -2 in the retry process:
 #
 

my $__DBUG = 0;
my $_ERROR_VAL = Net::Z3950::AsyncZ::Errors::errorval();
$SIG{CHLD} = \&childhandler;

sub asyncZOptions  {   return Net::Z3950::AsyncZ::Options::_params->new(@_); }

sub isZ_Header { $_[0] =~ Net::Z3950::AsyncZ::Report::get_pats(); }
sub isZ_MARC { $_[0] =~ Net::Z3950::AsyncZ::Report::get_MARC_pat(); }
sub isZ_GRS  { $_[0] =~ Net::Z3950::AsyncZ::Report::get_GRS_pat(); }
sub isZ_RAW  { $_[0] =~ Net::Z3950::AsyncZ::Report::get_RAW_pat(); }
sub isZ_DEFAULT { $_[0] =~ Net::Z3950::AsyncZ::Report::get_DEFAULT_pat(); }
sub getZ_RecNum { $_[0] =~ /\s(\d+)\]/; $1; }

sub _setupUTF8 {
     return if is_utf8_init();
	local $^W = 0;     
	  eval { require MARC::Charset; }; 
	local $^W = 1;     
	  if ($@) {
	    warn "UTF8 requires MARC::Charset\n";
	    return 0;
	  }
    set_uft8_init();
    return 1;
}

# params:  string or ref to string
#   	   boolean: true, then substitution uses 'g' modifier		
#	   substitution string
#              if subst string is not defined, empty string is substituted
# return:  either string or reference to string, depending on whether a reference or a string
#          was intially passed in paramter $_[0]		

sub delZ_header {   
  my($str,$g, $subst) = @_;
  my $pat = Net::Z3950::AsyncZ::Report::get_pats();   
  return  _del_headers($str,$pat, $g, $subst);  
}

# 	see delZ_header
sub delZ_pid { 
  my($str,$g, $subst) = @_;
  return  _del_headers($str,'<#--\d+-->', $g, $subst);  
}

# 	see delZ_header
sub delZ_serverName {
  my($str,$g, $subst) = @_;
  return  _del_headers($str,'<!--.*?-->', $g, $subst);  
}

sub _del_headers {  
  my $str = ref $_[0] ? ${$_[0]} : $_[0];
  my $pat = $_[1];
  my $g = $_[2];
  my $subst = (defined $_[3]) ? $_[3] : "";

  if($g) {
	$str =~ s/$pat/$subst/g;  
  }
  else {
       $str =~ s/$pat/$subst/;  
  }
  return \$str if ref $_[0];
  return $str;

}


# make string from array, return ref to string
# param: array of raw records
sub prep_Raw { 
  my $raw = shift;
  my $str = join "",@$raw;
  $raw = delZ_header(\$str);   # will get back ref to string     
  $raw = delZ_pid($raw,1);       # passing ref will get back ref
  $raw = delZ_serverName($raw,1);
  $raw = delZ_header($raw,1,'<!##!>');
  return $raw;
}

# param:  ref to string of raw records
# return next record
sub get_ZRawRec {
  my $raw = shift;
  return undef if ! $raw;

  if ($$raw !~ /<!##!>/) {  # presumed last record
   my $rec =  $$raw;
   $$raw = "";
   return $rec; 
  }
  $$raw =~ s/(.*?)<!##!>//;    
  return $1;
}

# tests whether line is our substitue for absence of Report:
#	 {!-- library.anu.edu.au --}
#  It reports previous server's name in curlies, substituted for angle brackets
#  (like HTML comment) which hold server name in header of each report item
sub noZ_Response {  $_[0]=~/\{!--\s+.*\s+--\}/; }

# tests if line contains server name
sub isZ_ServerName { $_[0] =~ /<!--(.*)-->/; }
sub isZ_PID { $_[0] =~ /<#--\d+-->/; }
sub isZ_Info { &isZ_PID || &noZ_Response; }
# returns server name
sub Z_serverName {   
         if( $_[0] =~ /<!--(.*?)-->/){
           return $1 if $1;
         }
	 return undef;
}

# returns 0 if not an error
# returns 2 if cycle 2 error
# returns 1 if non-recoverable cycle 1 error
 sub isZ_Error {
    my $err = shift;
    return 0 if !$err; 
    return 2 if $err->[0] && $err->[1];
    return 1 if $err->[0] && !$err->[0]->{retry};
    return 0;
}

# tests return value of isZ_Error()
# returns true if the error was a cycle 1 fatal error
sub isZ_nonRetryable {  $_[0] == 1;  }



{

my @results=();
my @errors=();
my @recSize = ();
my $busy = 0;
my $utf8_init = 0;

 sub is_utf8_init {      
   $utf8_init;
 }

 sub set_uft8_init {
   $utf8_init = 1;
 }

 sub _utf8 {
    my $index = shift;    

    _setupUTF8() if !$utf8_init;
    return if !$utf8_init;

    my $cs = MARC::Charset->new();
    for(my $i = 0; $i < scalar(@{$results[$index]}); $i++) {
                 $results[$index]->[$i] = $cs->to_utf8($results[$index]->[$i]);
    }
 }

 sub _saveResults {
    $busy = 1; 
    my ($arr, $index) = @_;
    $results[$index] = $arr;      
    $busy = 0;
 }

 sub _saveErrors {
    @errors = @_; 
 }

 sub _isBusy { return $busy; }

# returns reference to results array
 sub getResult {
    my ($self,$index) = @_; 
    _utf8($index) if $self->{options}[$index]-> _getFieldValue('utf8');
    return $results[$index];
 }

sub getZ_RecSize { $recSize[$_[0]];  }

 sub getErrors {
    my ($self,$index) = @_; 
    return [$errors[$index]->[0], $errors[$index]->[1]] if $errors[$index];
    return undef;
 }


sub getMaxErrors { return scalar @errors; }

sub _callback {  
  $busy = 1;
  my ($self, $index) = @_;
  _utf8($index) if $self->{options}[$index]-> _getFieldValue('utf8');
  my $cb = $self->{options}[$index]-> _getFieldValue('cb');
  $cb = $self->{cb} if !$cb;  

  my $last_el = scalar(@{$results[$index]})-1;
  my $size = $results[$index]->[$last_el]; 
  $size =~ /\*==(\d+)==\*/;
  $recSize[$index] = $1 ? $1 : 0;  
  $results[$index]->[$last_el] =~s/\*==(\d+)==\*//;  
  
  &$cb($index, $results[$index]) if $cb;
  $busy = 0;
}

}



#-------------------------------------------------------------------#
# private paramaters:
#       start:     start time for timers
#	zl:	   array of forked processes 
#	errors:    reference to Net::Z3950::AsyncZ::Errors object for main process
#	share:     reference to IPC::ShareLite
#       timer:	   reference to timer watcher 
#	unlooped:  notifies DESTROY when all pipes have been processed,		
#		   because DESTROY is called for each closed pipe--hence
#		   makes it safe to do cleanup that applies to main process
#      monitor_pid:  pid of the monitor, for killing it
#--------------------------------------------------------------------#
sub new {
my($class, %args) = @_;
my $index = 0;

my $self = { 
	          start => time(), zl => [], query=>$args{query}, errors=>undef,
        	  log=>$args{log} || undef, cb=>$args{cb}, timer => undef,
                  timeout=>$args{timeout}  || 25, timeout_min=>$args{timeout_min} || 5,
                  interval => $args{interval} || 1, servers=>$args{servers},
                  options=>$args{options}, unlooped=>0, maxpipes=>$args{maxpipes} || 4, 
                  share => undef, monitor => 0 || $args{monitor}, monitor_pid=>undef,
 		  swap_check => $args{swap_check} || 0, swap_attempts => $args{swap_attempts} || 5 
          };

	bless $self,$class;        
        $self->{ errors } = Net::Z3950::AsyncZ::Errors->new($self->{log});

%forkedPID=(); 
%exitCode=();  
%resultTable = ();
        
	my $incr = $self->{maxpipes};
        $self->{share} = new IPC::ShareLite( -key => $$ +  5000, 
                                -create  => 'yes', 
                                -destroy => 'yes');
      $self->{monitor_pid} = $self->_monitor() if $self->{monitor};
      
      $SIG{HUP} = sub {             
          $self->{abort} = 1;          
          $self->{unlooped} = 1;   # notify DESTROY that it's safe to kill outstanding processes              
          $! = 227;
          die "Aborting." 
       };
      

      $self->processHosts(-1,%args);

		#  retry servers that returned without error fatal codes
      my @retries = $self->_getReTries();  
      $args{'servers'} =  \@retries;
      $self->{'servers'} = $args{'servers'};
      $self->processHosts(-2, %args);      
      $self->_showStats(\%resultTable) if $__DBUG;
      $self->_processErrors();
      kill KILL => $self->{monitor_pid} if $self->{monitor};
      $self->{share} = undef;
      return $self;
     
}


sub processHosts {
my ($self, $retry_marker, %args) = @_;
my $index = 0;
my $count = 0;

      $self->{unlooped} = 0;
      $self->{start} = time();
      %forkedPID=();

	foreach my $server(@{$args{servers}}) {          
 
	          $self->{server} = $server;  
                  $self->{options}[$index] = Net::Z3950::AsyncZ::Options::_params->new(format=>$args{format},
                            num_to_fetch=>$args{num_to_fetch})
                            if ! defined $self->{options}[$index]; 

                  $self->{options}[$index]->option(_this_server=>$server->[0]);
                  $self->start($index, $retry_marker);
                    

		  if($count == $self->{maxpipes}) { 
		       my $mem_avail = $self->{swap_check} ? 0 : 1;
                       my $attempts = 0;
                       while(!$mem_avail) {
                          $mem_avail = is_mem_left();                         
                          if (!$mem_avail){
                            my $start_t = time();
                	    Event->timer(at => time+$self->{swap_check},cb => sub { $_[0]->w->cancel;} );		
    			    Event::loop;
                            # print STDERR "(swap-check) slept: ", time()-$start_t,"\n" if $__DBUG; 
                          }
                          $attempts++;
			   # print STDERR "(swap-check) attempts: $attempts\n" if $__DBUG;;
                          die "Memory resources appear to be too low to continue;\n",
                              "try settng the swap_check to a higher value and or",
                              "allowing for more than $self->{swap_attempts} swap_attempts\n"
                                   if $attempts > $self->{swap_attempts};
                       }

	              $self->{timer} = 
                        Event->timer(interval => $self->{interval}, hard=>1, cb=> sub { $self->timerCallBack(); } );                
    	                Event::loop();          
                       $count = -1;                      
		}
                          
                  $index++;
                  $count++;                    
	} 


# if there are any servers left to wait for, get another loop
	if(scalar (@{$args{servers}})%$self->{maxpipes} != 0) {
            $self->{timer} = 
	      Event->timer(interval => $self->{interval}, hard=>1, cb=> sub { $self->timerCallBack(); } );
	      Event::loop();      
	}
    
    $self->{unlooped} = 1;

}


sub _getReTries {
my $self =  shift;
my @retries=();
my $count=0;

  foreach my $pid (keys %resultTable) {                
   if($resultTable{$pid}->[1] == 0)    {    	                                    
 	my $err = Net::Z3950::AsyncZ::ErrMsg->new($exitCode{$pid});  ## created for testing only
        next if !$err->doRetry();                            ## not being saved
        my $index = $resultTable{$pid}->[2];
        push @retries, $self->{servers}[$index];
        $self->{options}[$count] = $self->{options}[$index];        
        $resultTable{$pid}->[3] = $count;         # save retry index
        $count++;
      }
  }

  return @retries;

}

sub start {
my $self=shift;
return if defined $self->{abort};
my $index = shift;
my $retry_marker = shift;
my $pid;

	if($pid = fork) {                    
              $forkedPID{$pid} = $index; 
	      $exitCode{$pid} = -1;    
   	      $resultTable{$pid}->[0] = @{$self->{servers}[$index]}[0];  # server name
              $resultTable{$pid}->[1] = 0;				 # report = false
              $resultTable{$pid}->[2] = $index; 			 # current index
              $resultTable{$pid}->[3] = $retry_marker;		         # retry index 

              print "process $index: \$pid = $pid   $resultTable{$pid}->[0] @{$self->{servers}[$index]}[1] @{$self->{servers}[$index]}[2]\n" if $__DBUG;
	}
        else  {    
                die "Server cannot handle your request at this time" unless defined $pid;
                $self->{share}->destroy(0);

                my $update = $self->{options}[$index]->_updateObjectHash($self);
		my $query  = $update->{query}  ? $update->{query}  : $self->{query};
                my $log    = $update->{log}    ? $update->{log}    : $self->{log}; 
		$self->{options}[$index]->_setFieldValue('_this_pid', $$);
                my $zerrs = Net::Z3950::AsyncZ::Errors->new($log, @{$self->{server}}[0], $query,
                            $self->{options}[$index]->get_preferredRecordSyntax(),
                            @{$self->{server}}[2]
                            );

		$self->{zl}[$index] = 
                    Net::Z3950::AsyncZ::ZLoop->new(@{$self->{server}},$query,$self->{options}[$index]);
		$self->{zl}[$index]->setTimer($self->{interval});   

		my $host = @{$self->{servers}[$index]}[0];
                if ($self->{zl}[$index]->{report} && $self->{share}) { 
                     push @{$self->{zl}[$index]->{report}}, 
                         "*==" . $self->{zl}[$index]->{rsize} . "==*\n";
                               
			$self->{share}->store(join '',@{$self->{zl}[$index]->{report}});
                }
                elsif ($self->{share}) {
                   $self->{share}->store("");
                }
		else { exit (Net::Z3950::AsyncZ::ErrMsg::_EINVAL()); }
                            

		exit 0;			
                  
          }


}


{
my $in_getResult = 0;
sub _gettingResult { $in_getResult; }

sub _getResult {
$in_getResult = 1;
my ($self, $pid) = @_;

                 exit (Net::Z3950::AsyncZ::ErrMsg::_EINVAL()) if !$self->{share};
                 $self->{share}->lock(LOCK_EX);

                 while(_isBusy()) { } 
                 my $data = $self->{share}->fetch(); 
                  return if !$data;	 # presumably should never occur
                                         # but it happened once and split doesn't
                                         # complain about splitting an undefined value
                  my @data = split "\n", $data;

                 $data[0] =~ /<!--(.*)-->/; 
                 my $host = $1;
                 $self->{share}->store("\{!\-\- $host \-\-\}") if $host;

                 $data[1] =~ /<#--(\d+)-->/ if $data[1]; 
                 my $_this_pid = $1 if $1;
                 $resultTable{$_this_pid}->[1] = 1
                            if $_this_pid && exists $resultTable{$_this_pid}; 
                 splice(@data,1,1);
                 $pid =  $_this_pid if $_this_pid;
                 my $index = _getIndex($pid);
                 
                 while(_isBusy()) { } 
                 _saveResults(\@data, $index);     
                 while(_isBusy()) { } 
                 $self->_callback($index); # if $self->{cb};                


                 $self->{share}->unlock;                 
                     
$in_getResult = 0;
}

}


sub _getIndex {
my $pid = shift;
   return  $resultTable{$pid}->[2] if $resultTable{$pid}->[3] == -1;  # cycle 1, no retry index
   my $current_index = $resultTable{$pid}->[2];    # this process's index, from either cycle

   foreach $pid (keys %resultTable) {                   # if this retry index == $current_index,
      return $resultTable{$pid}->[2]                    #  $current_index must be a cycle 2 index
          if $resultTable{$pid}->[3] == $current_index; # and this table entry is cycle 1 entry
   }

   return  $resultTable{$pid}->[2];  # default:  returns cycle 1 or 2 index
}

sub allDone {
  foreach my $pid (keys %exitCode) {
      return 0 if $exitCode{$pid} == -1;
  }
  return 1;
}

sub timerCallBack {
my $self=shift;
my $Seconds = time();

 foreach my $pid (keys %forkedPID) {      
      while (_gettingResult()) { }
      $self->_getResult($pid), delete $forkedPID{$pid} if $exitCode{$pid} == 0;            
 }
 
 my $endval = $Seconds - $self->{start};
 if ($endval > $self->{timeout} || allDone() ) {
   $self->{timer}->cancel();   
   Event::unloop();     
 }

}


sub _processErrors {
my $self = shift;
my %cycle_1 = ();
my %cycle_2 = ();
my @errors = ();
my $_count = 0;
$__DBUG =0;
print "\n\nProcessing Errors\n" if $__DBUG;

	 foreach my $pid (keys %resultTable) {                
	     $cycle_2{$pid} = $resultTable{$pid}, next
	            if $resultTable{$pid}->[1] == 0 && $resultTable{$pid}->[3] == -2;
	     $cycle_1{$pid} = $resultTable{$pid}
	            if $resultTable{$pid}->[1] == 0;
	 }

	print "\nCycle 1\n" if $__DBUG;
	$self->_showStats(\%cycle_1) if $__DBUG;

	 foreach my $pid_1 (keys %cycle_1) {   
       	     my $err = Net::Z3950::AsyncZ::ErrMsg->new($exitCode{$pid_1});
             my $index = _getIndex($pid_1);  
             $errors[$index]->[0] = $err;   
	     print $pid_1, "  " if $__DBUG; 
            $self->_printError($err) if $__DBUG;
	 }

	print "\nCycle 2\n" if $__DBUG;
	$self->_showStats(\%cycle_2) if $__DBUG;


	 foreach my $pid_2 (keys %cycle_2) {   
       	     my $err = Net::Z3950::AsyncZ::ErrMsg->new($exitCode{$pid_2});
             my $index = _getIndex($pid_2); 
             $errors[$index]->[1] = $err;    
             print $pid_2, "  " if $__DBUG; 
            $self->_printError($err) if $__DBUG;
	 }

	_saveErrors(@errors);
$__DBUG =0;
}


sub _printError {
my $self = shift;
my $err = shift;
my $errno = $err->{errno};
        my $num = sprintf( "[%3d]",$errno);       
        print "$num ";
	print     $err->{msg} if $err->{msg};   
        print "   NET" if $err->isNetwork();
        print "   SYSTEM" if $err->isSystem();
        print "   TRY AGAIN" if $err->isTryAgain();
        print "   SUCCESS" if $err->isSuccess();     
        print "   --Z3950 ERROR " if $err->isZ3950();
        print "   --RETRY " if $err->doRetry();
        print  "\n";  
}

sub childhandler {

 while((my $retv = waitpid(-1,WNOHANG))>0) {
                    $exitCode{$retv} = $? >> 8;		    	
                    $? = $exitCode{$retv}, die
                          if Net::Z3950::AsyncZ::ErrMsg::_abort($exitCode{$retv});
 }
  $SIG{CHLD} = \&childhandler;
}

use Carp;

sub DESTROY {
my $self =  shift;
	# Because each process uses this DESTROY method, we have to
	# wait for the main loop to end before closing its error log
	# and before killing any potential zombie processes



  return if !$self->{unlooped};

  print "DESTROY\n" if $__DBUG;
  foreach my $pid (keys %exitCode) {   
      if( kill 0 => $pid) {
	kill 9 => $pid if ($exitCode{$pid} < 0 || $exitCode{$pid} > 0);  
	print "killing $pid\n" if ($exitCode{$pid} < 0 || $exitCode{$pid} > 0) && $__DBUG;
      }
  }
    kill KILL => $self->{monitor_pid} if $self->{monitor};
    $self->{share} = undef if defined $self->{share};

    sleep(1);  # allow time for remaining killed processes to be reaped
}






sub _monitor {
my $self = shift;

$SIG{ALRM} = sub { 
  my $pid = getppid();
 # print "killing: $pid\n";  
  kill HUP => $pid;   
  kill KILL => $$;
  };

my $pid;
	if($pid = fork) {                              
          return $pid;
	}
        else  {  
            die "Unable to fork" unless defined $pid;
            alarm($self->{monitor});
            while (1) { sleep(10); } 
        }
 
}




sub is_mem_left {
 my $vmstat;
 if($^O =~ /linux/) {
     $vmstat = "vmstat 1 3 | ";
 }
 else {
     $vmstat = "vmstat -S 1 3| ";
 }

    open VMSTAT, $vmstat or die "can't open vmstat";

    my (@si,@so,$si_index,$so_index,@fields);
    my $count=0;
    while(<VMSTAT>) {
         sleep(1);    # helps to insure that vmstat produces 3 lines of output  
         s/^\s*// and s/\s*$//;
         s/\s+/;/g;
         if(/si/i && /so/i) {
            @fields =  split /;/;
            for(my $i=0; $i< scalar @fields; $i++) {
             $si_index = $i if  $fields[$i] =~ /^si$/i;
             $so_index  = $i if $fields[$i] =~ /^so$/i;
            }
         }
         elsif(/\d/) {
           @fields =  split /;/;
           $si[$count] =  $fields[$si_index];
           $so[$count] = $fields[$so_index];           
           $count++;
         }
    }

    close VMSTAT;
    sleep 3 and return 1 if $count < 2;  # fix for when vmstat returns after only one cycle
    return 0 if abs($si[2] - $si[1]) >= 20;
    return 0 if abs($so[2] - $so[1]) >= 20;
    return 1;


}

1;


__END__


sub _showStats {
my $self = shift;
my $table = shift;
print "\nStats\n";
      foreach my $pid (keys %$table) {
     		print "$pid:\t";      
                print "$table->{$pid}->[0]",
                "    result:  $table->{$pid}->[1]",
                "    index: $table->{$pid}->[2]",
                "    retry index:  $table->{$pid}->[3]";
                print "\texit code: $exitCode{$pid}\n" if exists $exitCode{$pid};
      }
}


