package SNMP::Util;
##
##
## Summary: This library contains basic methods for SNMP communications
## 
## Description:  This library contains a set of functions for handling snmp
##               communications
##
## Author:  Wayne Marquette - 6/2/98 - New library

## Compiler directives.
use strict;

## Module import.
use SNMP;
use FileHandle qw(autoflush);
use SNMP::Util_env;
use vars qw($VERSION);
$VERSION = "1.8";


autoflush STDOUT;

## Initalize Globals
use vars qw($Delimiter $Max_log_level $Return_type); 

@Util::EXPORT_OK = qw (
                       index_get_array
                       index_set_array
                       log
                       print_array
                       );

@Util::ISA = qw(Exporter);


################################ Public Methods ###############################


sub new {
    my($class, %args) = @_;
    my(
       $Comm_string,
       $IP,
       $device,
       $errmode,
       $mib_match,
       $mib_filename,
       $mib,
       $poll,
       $poll_timeout,
       $retry,
       $self,
       $timeout,
       $udp_port,
       $verbose,
       );

    ## Parse named args.
    $verbose = 0;
    foreach (keys %args) {
	if (/^-community/i) {
	    $Comm_string = $args{$_};
	}
	elsif (/^-device/i || /^-dev/) {
	    $IP = $args{$_};
	}
	elsif (/^-port/i || /^-udp_port/) {
	    $udp_port = $args{$_};
	}
	elsif (/^-timeout/i) {
	    $timeout = $args{$_};
	}
	elsif (/^-retry/i) {
	    $retry = $args{$_};
	}
	elsif (/^-poll$/i) {
	    $poll = $args{$_};
	}
	elsif (/^-poll_timeout/i) {
	    $poll_timeout = $args{$_};
	}
	elsif (/^-errmode/i) {
	    $errmode = $args{$_};
	}
	elsif (/^-mib/i) { #Not used but leave here for compatability
	    $mib = $args{$_};
	}
	elsif (/^-verbose/i) {
	    $verbose = $args{$_};;
            if ($verbose eq 'on'){
	       $verbose = 1;
	    }
            elsif ($verbose eq 'off'){
               $verbose = 0;
            }
            else{
		$verbose = 0;
            }
	}
	elsif (/^-delimiter/ || /^octet-delimit/){ # Change delimiter for octet string output
	    $Delimiter = $args{$_};
	}
	else {
	    die "Invalid argument - \"$_\"";
	}
    }

    
    ## Create a new object.
    $self = bless {}, $class;
    $self->{IP} = $IP;
    $self->{community} = $Comm_string;
    $self->{timeout} = $timeout;
    $self->{poll} = $poll;
    $self->{poll_timeout} = $poll_timeout;
    $self->{retry} = $retry;


    # Set all defaults
    if (!defined $self->{community} or $self->{community} eq '') {
        $self->{community} = 'public';
    }
    if (!defined $self->{timeout} or $self->{timeout} eq '') {
        $self->{timeout} = 5;
    }
    if (!defined $self->{retry} or $self->{retry} eq '') {
        $self->{retry} = 3;
    }

    if (!defined $self->{poll} or $self->{poll} eq '') {
        $self->{poll} = 1;
    }
    elsif ($self->{poll} eq 'on') {
        $self->{poll} = 1;
    }
    elsif ($self->{poll} eq 'off') {
        $self->{poll} = 0;
    }
    else {
        $self->{poll} = 1;
    }

    if (!defined $self->{poll_timeout} or $self->{poll_timeout} eq '') {
	$self->{poll_timeout} = 5;
    }

    ## Convert sec to microseconds
    $self->{timeout} = $self->{timeout} * 1000000;

    ## Turn verbose messages on.
    if ($verbose){
	$SNMP::verbose = 1;
    }
    else{
	$SNMP::verbose = 0;
    }
    
    $Return_type = 'array';
    
    # Initialize mib
    &SNMP::initMib();

    ## Create new SNMP Session.
    $self->{snmp} = new SNMP::Session(DestHost  => $self->{IP},
				    Community => $self->{community},
				    Timeout => $self->{timeout},
				    Retries => $self->{retry},
				    RemotePort => $self->{udp_port},
				    UseEnums => 1,
				    );

    return undef unless (defined $self->{snmp});
    ## Set the error mode.
    if (defined $errmode) {
	$self->errmode($errmode);
    }
    else {
	## Default to return.
	$self->errmode('return');
    }

    ## Return the new object.
    $self;
} # end sub new


sub ping_check_exit {
    my($self) = @_;
    my(
       $IP,
       $pingres,
       $result,
       $snmp,
       $save_log_level,
       $save_snmp,
       $save_poll,
       @pingres,
       );
    
    ## Variable init.
    $IP = $self->{IP};

    $save_log_level = $SNMP::Util::Max_log_level;
    $save_poll = $self->{poll};
    $save_snmp = $self->{snmp};

    # Turn logging off
    $SNMP::Util::Max_log_level = 'none';

    $self->{poll} = 0;


    $self->{snmp} = new SNMP::Session(DestHost  => $IP,
				    Community => $self->{community},
				    Timeout => 2000000,
				    Retries => 0,
				    RemotePort => $self->{udp_port},
				    UseEnums => 1,
				    );

    $pingres = $self->get('v','sysUpTime.0');

    $self->{poll} = $save_poll;
    $self->{snmp} = $save_snmp;

    # Change logging back to default
    $SNMP::Util::Max_log_level = $save_log_level;

    if (!$self->error && $pingres =~ /^\d+/){
	return 1;
    }
    else {
	&log('fail',"Cannot reach device $IP - Test Failed\n");
	return;
    }
} # end sub ping_check_exit


sub ping_check {
    my($self) = @_;
    my(
       $IP,
       $pingres,
       $result,
       $save_log_level,
       $save_poll,
       $save_snmp,
       $snmp,
       @pingres,
       );

    $IP = $self->{IP};

    $save_log_level = $SNMP::Util::Max_log_level;
    $save_poll = $self->{poll};
    $save_snmp = $self->{snmp};

    $self->{poll} = 0;

    # Turn logging off
    $SNMP::Util::Max_log_level = 'none';

    $self->{snmp} = new SNMP::Session(DestHost  => $IP,
				    Community => $self->{community},
				    Timeout => 2000000,
				    Retries => 0,
				    RemotePort => $self->{udp_port},
				    UseEnums => 1,
				    );

    $pingres = $self->get('v','sysUpTime.0');

    # Change logging back to default
    $SNMP::Util::Max_log_level = $save_log_level;

    $self->{poll} = $save_poll;
    $self->{snmp} = $save_snmp;

    if (!$self->error && $pingres =~ /^\d+/){
	return 1;
    }
    else {
	return;
    }
} # endsub ping_check


sub poll_device {
    my($self) = @_;
    my(
       $IP,
       $elapsed_time,
       $end_time,
       $get_result,
       $poll_timeout,
       $result,
       $uptime,
       @uptime,
       );

    ## Variable init.
    my $time_min = 0;
    my $time_sec = 0;
    my $start_time = time;
    my $stop = 0;

    $IP = $self->{IP};

    $poll_timeout = $self->{poll_timeout};

    if (!defined $poll_timeout || $poll_timeout eq '') {
	$poll_timeout = 5;
    }

    $elapsed_time = '0:0';
    &log('fail',"\n");
    while ($time_min < $poll_timeout){
	&log('fail',"Waiting for device $IP to respond at $elapsed_time (min:sec)         \r");
	$result = $self->ping_check;
        $end_time = time;
	$time_sec = $end_time - $start_time;
	$time_min = $time_sec / 60;
	$time_sec = $time_sec % 60;
	$elapsed_time = sprintf("%2d:%2d",$time_min,$time_sec);
	if ($result){
	    &log('status',"\nDevice $IP is now responding at $elapsed_time (min:sec)\n\n");
	    return 1;
	}
	#sleep 5;
    }
    &log('fail',"\nDevice $IP did not respond after $poll_timeout minutes \n\n");
    # Return fail exit status
    return 0;
} # end sub poll_device
    

sub poll_devices {
    my($self, @IP_array) = @_;
    my($IP);
    
    foreach $IP (@IP_array) {
	$self->poll_device($IP);
    }
} # end sub poll_devices

## Usage: $snmp->get($self,$format,@oid_list);
##
## Description: This subroutine will simply do an snmpget and verify that
##              no error occured and returns the result (referenced).
sub get {
    my($self, @args) = @_;
    my(
       $error,
       $error_index,
       $format,
       $hash,
       $oid_list,
       $poll,
       $poll_result,
       $return_type,
       $snmp,
       $value,
       $vars,
       $IP,
       %args,
       @oid_list,
       @values,
       );
    
    ## Determine if caller is using positional format or dashed args.
    ## If first arg start with a dash, all args must be of that format.
    if ($args[0] !~ /^-/) {
	## Arguments were supplied as positional.
	($format, @oid_list) = @args;
    }
    else {
	## Parse named args.
	%args = @args;
	foreach (keys %args) {
	    if (/^-format$/) {
 		$format = $args{$_};
	    }
	    elsif (/^-oids$/) {
		$oid_list = $args{$_};
		(ref $oid_list eq 'ARRAY') 
		    or die "Value of \"-oids\" must be an array ref";
	    }
	    else {
		die "Invalid argument to SNMP::Util::get: \"$_\"";
	    }
	}
    }
    $oid_list = \@oid_list unless defined $oid_list;


    ## Variable init.
    $poll = $self->{poll};
    $IP = $self->{IP};

    $snmp = $self->{snmp};

    ## Clear any previous errors.
    $self->error_reset;

    $vars = &build_get_var_list($oid_list);

    &log('debug',"\nsnmpget $IP @$oid_list\n");

    $snmp->get($vars);

    $error = $snmp->{ErrorStr};
    $error_index = $snmp->{ErrorInd};

    $return_type = $Return_type;
    

    if ($error ne ''){
	&log_error($self,'get',$error,$oid_list,$error_index);
	if ($poll && $error =~ /timeout/i ){
	    ## Poll for device if timeout retry times
	    $poll_result = $self->poll_device
		or return $self->error("oper: ", "SNMP::Util::poll_device failed\n"); 
	    $snmp->get($vars);
	    
	    $error = $snmp->{ErrorStr};
	    if ($error ne ''){
		&log_error($self,'get',$error,$oid_list,$error_index);
		return $self->error("oper: ","SNMP::Util::get failed $error\n");
	    }
	    else{
		if ($return_type eq 'array'){
		    @values = &format_array($format,$vars);
		    if (@values == 1){
			$value = $values[0];
			return($value);
		    }
		    return (@values);
		}
		elsif ($return_type eq 'hash'){
		    $hash = &format_hash($format,$vars);
		    return ($hash);
		}
	    }
	}
	else{
	    return $self->error("oper: ","SNMP::Util::get failed $error\n");
	}
    }
    else{
	if ($return_type eq 'array'){
	    @values = &format_array($format,$vars);
	    if (@values == 1){
		$value = $values[0];
		return($value);
	    }
	    return (@values);
	}
	elsif ($return_type eq 'hash'){
	    $hash = &format_hash($format,$vars);
	    return ($hash);
	}
    }

} # end sub get

sub get_hash {
    my($self, @args) = @_;

    my($hash);

    $SNMP::Util::Return_type = 'hash';
    $hash = $self->get(@args);
    $SNMP::Util::Return_type = 'array';

    $hash;
    
} # end sub get_hash


sub set {
    my($self, @args) = @_;
    my(
       $error,
       $error_index,
       $format,
       $i,
       $oid_list,
       $poll,
       $poll_result,
       $snmp,
       $vars,
       $IP,
       %args,
       @oid_list,
       @values,
       );

    ## Determine if caller is using positional format or dashed args.
    ## If first arg start with a dash, all args must be of that format.
    if ($args[0] !~ /^-/) {
        ## Arguments were supplied as positional.
        @oid_list = @args;
    }
    else {
        ## Parse named args.
        %args = @args;
        foreach (keys %args) {
            if (/^-oids$/) {
                $oid_list = $args{$_};
                (ref $oid_list eq 'ARRAY')
                    or die "Value of \"-oids\" must be an array ref";
            }
            else {
                die "Invalid argument to Snmp::set:: \"$_\"";
            }
        }
    }

    
    $oid_list = \@args unless defined $oid_list;

    ## Variable init.
    $poll = $self->{poll};
    $IP = $self->{IP};

    $snmp = $self->{snmp};

    ## Clear any previous errors.
    $self->error_reset;

    $vars = &build_set_var_list($oid_list);
    if (!defined $vars){
	&log_error($self,'set','oid list incomplete',$oid_list,$error_index);
	return $self->error("oper: ", "build_set_var_list failed\n");
    }
    &log('debug',"\nsnmpset $IP @$oid_list\n");
    $snmp->set($vars);

    $error = $snmp->{ErrorStr};
    $error_index = $snmp->{ErrorInd};

    if ($error ne ''){
	&log_error($self,'set',$error,$oid_list,$error_index);
	if ($poll && $error =~ /timeout/i){
	    ## Poll for device if timeout retry times
	    $poll_result = $self->poll_device
		or return $self->error("oper: ", "SNMP::Util::poll_device failed\n"); 
	    $snmp->set($vars);
	    
	    $error = $snmp->{ErrorStr};
	    if ($error ne ''){
		&log_error($self,'set',$error,$oid_list,$error_index);
		return $self->error("oper: ", "SNMP::Util::snmp set failed $error\n");
	    }
	}
	else{
	    return $self->error("oper: ", "SNMP::Util::snmp set failed $error\n");
	}
    }
    else{
	return 1;
    }
    


} # end sub set

sub set_get {
    my($self, @args) = @_;
    my(
       $error,
       $error_index,
       $fail,
       $format,
       $get_value,
       $i,
       $index,
       $oid_hash,
       $oid_list,
       $poll,
       $poll_result,
       $set_oid,
       $set_value,
       $snmp,
       $vars,
       $IP,
       %args,
       @get_oids,
       @get_result,
       @oid_list,
       @oids,
       @set_array,
       @values,
       );
    
    ## Determine if caller is using positional format or dashed args.
    ## If first arg start with a dash, all args must be of that format.
    if ($args[0] !~ /^-/) {
	## Arguments were supplied as positional.
	($format, @oid_list) = @args;
    }
    else {
	## Parse named args.
	%args = @args;
	foreach (keys %args) {
	    if (/^-oids$/) {
		$oid_list = $args{$_};
		(ref $oid_list eq 'ARRAY') 
		    or die "Value of \"-oids\" must be an array ref";
	    }
	    else {
		die "Invalid argument to SNMP::Util::set_get: \"$_\"";
	    }
	}
    }

    $oid_list = \@args unless defined $oid_list;

    ## Variable init.
    $poll = $self->{poll};
    $IP = $self->{IP};

    $snmp = $self->{snmp};

    ## Clear any previous errors.
    $self->error_reset;

    $oid_hash = &set_list_to_names_and_oids($oid_list);
    @set_array = @{$oid_hash->{names}};

    # Check if the second value is a enum or integer
    if ($set_array[1] =~ /^[a-zA-Z]+/){
	$format = 'ne';
    }
    else{
	$format = 'nv';
    }


    @get_oids = ();
    for ($i = 0; $i<= $#set_array; $i+=2){
	push @get_oids,$set_array[$i];
    }

    $vars = &build_set_var_list($oid_list);

    &log('debug',"\nsnmpset $IP @$oid_list\n");
    $snmp->set($vars);

    $error = $snmp->{ErrorStr};
    $error_index = $snmp->{ErrorInd};
    
    $fail = 0;
    if ($error ne ''){
	&log_error($self,'set',$error,$oid_list,$error_index);
	if ($poll && $error =~ /timeout/i){
	    ## Poll for device if timeout retry times
	    $poll_result = $self->poll_device
		or return $self->error("oper: ", "SNMP::Util::poll_device failed\n"); 
	    $snmp->set($vars);
	    
	    $error = $snmp->{ErrorStr};
	    if ($error ne ''){
		&log_error($self,'set',$error,$oid_list,$error_index);
		return $self->error("oper: ", "SNMP::Util::snmp set failed $error\n");
	    }
	    else{
		@values = &format_array($format,$vars);
		return (@values);
	    }
	}
	else{
	    return $self->error("oper: ", "SNMP::Util::snmp set failed $error\n",);
	}
    }
    else{
	@get_result = $self->get($format,@get_oids);
	
	for ($i = 0; $i <= $#set_array; $i+=2){
	    $set_oid = $set_array[$i];
	    $set_value = $set_array[$i+1];
	    if ($set_oid ne $get_result[$i]){
		&log('fail',"set - @set_array\n");
		&log('fail',"get - @get_result\n");
		$fail = 1;
	    }
	    if ($set_value ne $get_result[$i+1]){
		&log('fail',"set - @set_array\n");
		&log('fail',"get - @get_result\n");
		$fail = 1;
	    }
	}
	if (!$fail){
	    return 1;
	}
	else{
	    return ;
	}
    }
} # end sub set

      
sub next {
    my($self, @args) = @_;
    my(
       $error,
       $error_index,
       $format,
       $oid_list,
       $poll,
       $poll_result,
       $snmp,
       $vars,
       $IP,
       %args,
       @oid_list,
       @values,
       );
    
    ## Determine if caller is using positional format or dashed args.
    ## If first arg start with a dash, all args must be of that format.
    if ($args[0] !~ /^-/) {
	## Arguments were supplied as positional.
	($format, @oid_list) = @args;
    }
    else {
	## Parse named args.
	%args = @args;
	foreach (keys %args) {
	    if (/^-format$/) {
 		$format = $args{$_};
	    }
	    elsif (/^-oids$/) {
		$oid_list = $args{$_};
		(ref $oid_list eq 'ARRAY') 
		    or die "Value of \"-oids\" must be an array ref";
	    }
	    else {
		die "Invalid argument to SNMP::Util::next: \"$_\"";
	    }
	}
    }
    $oid_list = \@oid_list unless defined $oid_list;

    ## Variable init.
    $poll = $self->{poll};
    $IP = $self->{IP};

    $snmp = $self->{snmp};

    ## Clear any previous errors.
    $self->error_reset;

    $vars = &build_get_var_list($oid_list);
    
    &log('debug',"\nsnmpnext $IP @$oid_list\n");
    $snmp->getnext($vars);

    $error = $snmp->{ErrorStr};
    $error_index = $snmp->{ErrorInd};

    if ($error ne ''){
	&log_error($self,'next',$error,$oid_list,$error_index);
	if ($poll && $error =~ /timeout/i){
	    ## Poll for device if timeout retry times
	    $poll_result = $self->poll_device
		or return $self->error("oper: ", "SNMP::Util::poll_device failed\n"); 
	    
	    
	    $snmp->getnext($vars);
	    
	    $error = $snmp->{ErrorStr};
	    if ($error ne ''){
		&log_error($self,'next',$error,$oid_list,$error_index);
		return $self->error("oper: ", "SNMP::Util::next failed $error\n");

	    }
	    else{
		@values = &format_array($format,$vars);
		return (@values);
	    }
	}
	else{
	    return $self->error("oper: ", "SNMP::Util::next failed $error\n");
	}
    }
    else{
	@values = &format_array($format,$vars);
	return (@values);
    }
    


} # end sub get


sub get_set_restore {
    my($self, $range, @oid_list) = @_;
    my(
       $IP,
       $value,
       $oid,
       $value,
       $value_hi,
       $value_lo,
       @range,
       @restore_oid_list,
       @set_oid_list,
       @value_array,
       );

    ## Variable init.
    $IP = $self->{IP};

    @restore_oid_list = $self->get('nv',@oid_list)
        or return;

    eval "\@range = ($range)";


    # Set the variable to all valid values
    foreach $value (@range){
	@set_oid_list = ();
	foreach $oid (@oid_list) {
	    push @set_oid_list, $oid, $value;
	}
	$self->set_get(@set_oid_list)
	    or return;
	&log('status',"Setting @set_oid_list\r");
    }


    $self->set(@restore_oid_list)
        or return;
    &log('status',"\nRestoring @restore_oid_list \n");

    return 1;
} # end sub get_set_range_restore


sub walk {
    my($self, @args) = @_;
    my(
       $error,
       $error_index,
       $format,
       $hash,
       $i,
       $instance,
       $loop,
       $loop_retry,
       $loop_stuck,
       $name,
       $name_indexed,
       $oid,
       $oid_hash,
       $oid_list,
       $oid_indexed,
       $poll,
       $poll_result,
       $print,
       $return_type,
       $snmp,
       $temp_hash,
       $temp_value,
       $test,
       $type,
       $vars,
       $value,
       $IP,
       %args,
       @patterns,
       @oid_list,
       @oids,
       @tmp_oid_list,
       @tmp_patterns,
       @values,
       @walk_values,
       );
    
    ## Determine if caller is using positional format or dashed args.
    ## If first arg start with a dash, all args must be of that format.
    if ($args[0] !~ /^-/) {
	## Arguments were supplied as positional.
	($format, @oid_list) = @args;
    }
    else {
	## Parse named args.
	%args = @args;
	$print = 0;
	foreach (keys %args) {
	    if (/^-format$/) {
 		$format = $args{$_};
	    }
	    elsif (/^-oids$/) {
		$oid_list = $args{$_};
		(ref $oid_list eq 'ARRAY') 
		    or die "Value of \"-oids\" must be an array ref";
	    }
	    elsif (/^-print$/) {
		$print = $args{$_};
		if ($print eq 'on'){
		    $print = 1;
		}
		elsif ($print eq 'off'){
		    $print = 0;
		}
		else{
		    $print = 0;
		}
	    }
	    else {
		die "Invalid argument to SNMP::Util::walk: \"$_\"";
	    }
	}
    }

    $oid_list = \@oid_list unless defined $oid_list;

    ## Variable init.
    $poll = $self->{poll};
    $IP = $self->{IP};

    $snmp = $self->{snmp};

    $return_type = $Return_type;

    ## Clear any previous errors.
    $self->error_reset;

    @walk_values = ();
    &log('debug',"\nsnmpwalk $IP @$oid_list\n");

    #Convert oid list to hash and then array
    $oid_hash = &get_list_to_names_and_oids($oid_list);
    @oid_list = @{$oid_hash->{names}};
    @oids = @{$oid_hash->{oids}};
    @patterns = @oids;

    $loop = 1;
    $loop_retry = 1;
    $loop_stuck = 1;
    while (@oid_list){
	$oid_list = \@oid_list;
	$vars = &build_get_var_list($oid_list);
	$snmp->getnext($vars);
	
	$error = $snmp->{ErrorStr};
    	$error_index = $snmp->{ErrorInd};
	
	if ($error ne ''){
	    &log_error($self,'walk',$error,$oid_list,$error_index);
	    
	    if ($poll && $error =~ /timeout/i){
		## Poll for device if timeout retry times
		$poll_result = $self->poll_device
		    or return $self->error("oper: ", "SNMP::Util::poll_device failed\n"); 
		
		
		$snmp->getnext($vars);
	    
		$error = $snmp->{ErrorStr};
		if ($error ne ''){
		    &log_error($self,'walk',$error,$oid_list,$error_index);
		    return $self->error("oper: ", "SNMP::Util::walk failed $error\n");
		}
	    }
	    else{
		if ($loop > 1 && $error =~ /nosuch/i){ #End of mib??
		    &log("fail","\nnosuchName error End of Mib??\n\n");
		}
		else{
		    return $self->error("oper: ", "SNMP::Util::walk failed $error\n");
		}
	    }
	}

   	# Check for timeout and retry if it's not the first next
	if ($error =~  /timeout/i){
	    if ($loop == 1){
		&log_error($self,'walk',$error,$oid_list,$error_index);
		return $self->error("oper: ", "SNMP::Util::walk timeout\n");
	    }
	    elsif ($loop > 1){ #Retry on timeout if not first time through loop
		if ($loop_retry <  4){ #
		    $loop_retry++;
		    next unless ($loop_retry == 3);
		    &log_error($self,'walk',$error,$oid_list,$error_index);
		    return $self->error("oper: ", "SNMP::Util::walk timeout\n");
		}
	    }
	}
	elsif (@tmp_oid_list && ($oid_list[0] eq $tmp_oid_list[0]) && $loop_stuck < 11){ # Abort infinite loop
	    $loop_stuck++;
	    next unless ($loop_stuck == 10);
	    &log_error($self,'walk','Exiting infinite loop',$oid_list,$error_index);
	    return $self->error("fatal: ","Exiting infinite loop\n");
	}

        $loop_stuck = 1;
	$loop_retry = 1;
	$test = 1;

	@tmp_oid_list = @oid_list;
	@tmp_patterns = @patterns;
	@patterns = ();
	@oid_list = ();
	for ($i = 0; $i<= $#tmp_oid_list; $i++){
	    $name = $vars->[$i]->[0];
	    $temp_value = $vars->[$i]->[2];
            $type = $vars->[$i]->[3];
	    $oid = &SNMP::translateObj($name);
	    $oid =~ s/\.//;
	    $instance = $vars->[$i]->[1];
	    if (!defined $instance || $instance eq ''){
		$name_indexed = $name;
		$oid_indexed = $oid;
	    }
	    else{
		$name_indexed = "$name.$instance";
		$oid_indexed = "$oid.$instance";
	    }


	    if (defined $tmp_patterns[$i] && $oid_indexed =~ /^$tmp_patterns[$i]\./){
		push @oid_list,$name_indexed;
		push @patterns,$tmp_patterns[$i];
		if ($return_type eq 'hash'){
		    $value = &convert_value($format,$name,$type,$temp_value);
		    $hash->{$name}{$instance} = $value;
		}
	    }
	    else{
		$test = 0;
	    }
	} 
	if ($test){
	    if ($loop > 1 && $error =~ /nosuch/i){ ##End of mib ??
		return @walk_values;
	    }
	    if ($return_type eq 'array'){
		@values = &format_array($format,$vars);
		print "@values\n" if ($print); 
		push @walk_values,@values;
	    }
	}
	$loop++;
    }
    if ($return_type eq 'array'){
	return(@walk_values);
    }
    elsif ($return_type eq 'hash'){
	return($hash);
    }
    else{
	return(@walk_values);
    }
       
	
	
    return @walk_values;
    
} # end sub walk

sub walk_hash {
    my($self, @args) = @_;

    my($hash);

    $SNMP::Util::Return_type = 'hash';
    $hash = $self->walk(@args);
    $SNMP::Util::Return_type = 'array';

    $hash;
    
} # end sub walk_hash

sub poll_value {
    my($self, %args) = @_;
    my(
       $IP,
       $delay,
       $elapsed_time,
       $format,
       $get_value,
       $instance,
       $mon_time,
       $oid,
       $name,
       $time,
       $time_out,
       $transition_time,
       $value,
       @value,
       $stop,
       );

    foreach (keys %args) {
	if (/^-oid/i) {
	    $oid = $args{$_};
	}
	elsif (/^-value/i || /^-state/i) {
	    $value = $args{$_};
	}
	elsif (/^-montime/i || /^-mon_time/) {
	    $mon_time = $args{$_};
	}
	elsif (/^-instance/){
	    $instance = $args{$_};
	}
	elsif (/^-timeout/i || /^-time_out/) {
	    $time_out = $args{$_};
	}
	elsif (/^-delay/i) {
	    $delay = $args{$_};
	}
    }

    if (ref($value) eq 'ARRAY'){
	@value = @$value;
    }

    ## Variable init.
    $IP = $self->{IP};
    $time_out  = 120 unless defined $time_out;
    $mon_time  = 0 unless defined $mon_time;
    $delay = 1 unless defined $delay;

    &log('fail',"\n");
    if ($value =~ /^[a-zA-Z]+/) {
	$format = 'e';
    }
    else {
	$format = 'v';
    }

    if (defined $instance){
	($name,$oid) = &get_name_and_oid($oid);
	$name = "$name.$instance";
	$get_value = $self->get($format, $name);
    }
    else{
	($name,$instance) = ($oid =~ /^(\w+)\.(.*)$/);
	($name,$oid) = &get_name_and_oid($name);
	$name = "$name.$instance";
	$get_value = $self->get($format, $name);
    }
    
    $get_value = '' unless defined $get_value;
    $time = time;
    $elapsed_time = 0;
    # Check if the get value equals the desired value
    $stop = 0;
    if (@value){
	if (grep(/$get_value/,@value)){
	    &log('status',"\n$name = $get_value at elapsed_time ($elapsed_time seconds) for device $IP\n");
	    $stop = 1;
	}
    }
    elsif ($get_value eq $value) {
	&log('status',"\n$name = $get_value at elapsed_time ($elapsed_time seconds) for device $IP\n");
	$stop = 1;
    }
    unless ($stop) {
	while (!$stop) {
	    $get_value = $self->get($format, $name);
	    $get_value = '' unless defined $get_value;
	    
	    $elapsed_time = time - $time;
	    if ($elapsed_time > $time_out) {
		if (@value){
		    &log('fail',"\n$name is not [@value] for device $IP at elapsed_time ($elapsed_time seconds)\n");
		}
		else{
		    &log('fail',"\n$name is not $value for device $IP at elapsed_time ($elapsed_time seconds)\n");
		}
		return $self->error("oper: ", "SNMP::Util::poll_value failed\n");
		$value = $get_value;
		return;
	    }
	    if (@value){
		if (grep(/$get_value/,@value)){
		    &log('status',"\n$name $get_value = [@value] at elapsed_time ($elapsed_time seconds) for device $IP\n");
		    $stop = 1;
		}
		else{
		    &log('status',"$name = $get_value at elapsed_time ($elapsed_time seconds) for device $IP       \r");
		}
	    }
	    elsif (defined $get_value && $get_value eq $value) {
		&log('status',"\n$name is now $get_value at elapsed_time ($elapsed_time seconds) for device $IP\n");
		$stop = 1;
	    }
	    elsif (defined $get_value  && $get_value ne '') {
		&log('status',"$name = $get_value at elapsed_time ($elapsed_time seconds) for device $IP       \r");
	    }
	    sleep $delay;
	}
    }
    $transition_time = $elapsed_time;
    if ($transition_time == 0) {
	$transition_time = 0.5;
    }
    
    $time = time;
    $elapsed_time = 0;
    while ($elapsed_time < $mon_time) {
        $get_value = $self->get($format, $name);
        $elapsed_time = time - $time;
	if (@value){
	    if (grep(/$get_value/,@value)){
		&log('status',"Monitoring $name = $get_value at time $elapsed_time seconds       \r");
	    }
	    else{
		&log('fail',"\n $name = $get_value should be [@value] at $elapsed_time seconds\n");
		return $self->error("oper: ", "SNMP::Util::poll_value  Monitoring failed\n");
	    }
	}
	elsif (defined $get_value && $get_value eq $value) {
	    &log('status',"Monitoring $name = $get_value at $elapsed_time seconds      \r");
	    $stop = 0;
	}
	elsif(defined $get_value && $get_value ne $value) {
	    &log('fail',"\n $name = $get_value should be $value at $elapsed_time seconds\n");
	    return $self->error("oper: ", "SNMP::Util::poll_value  Monitoring failed\n");
	}
        sleep $delay;
    }
    &log('status',"\n");

    return($transition_time);
} # end sub poll_value


################################ Private Methods ##############################




sub build_get_var_list{
    my($args) = @_;
    my(
       $i,
       $index,
       $instance,
       $name,
       $name_indexed,
       $start_index,
       $vars,
       @args,
       @oid_list,
       @var_list,
       );

    @args = @$args;

    @var_list = ();

    $start_index = 0;
    if ($args[0] =~ /^\d+/ && $args[0] !~ /^1.3.6.1/){
	$index = $args[0];
	$start_index ++;
    }
    elsif ($args[0] eq 'index'){
	$index = $args[1];
	$start_index+=2;
    }
    for ($i = $start_index; $i <= $#args; $i++){
	if (defined $index){ # Index is defined in hash
	    $name = $args[$i];
	    push @var_list, ["$name", "$index"];
	}
	elsif ($args[$i] =~ /^[a-zA-Z]+/ && $args[$i] =~ /^(\w+)\.\d+/){ # Index is contained in name (not applicable to oids)
	    ($name,$instance) = ($args[$i] =~ /^(\w+)\.(.*)$/);
	    push @var_list, ["$name", "$instance"];
	}
	else{ # Instance is either passed after name or there is none
	    $name = $args[$i];
	    if (defined $args[$i+1]){
		$instance = $args[$i+1];
		if ($instance =~ /^\d+/ && $instance !~ /^1.3.6.1/){ # Intance is an index
		    push @var_list, ["$name", "$instance"];
		    $i++;
		}  
		else{ ## Instance is name or an oid with no index (for walk only)
		    push @var_list, ["$name", ""], ["$instance", ""];
		    $i++;
		}
	    }
	    else{ #no instance
		push @var_list, ["$name", ""];
	    }
	}
    }
    $vars = new SNMP::VarList(@var_list);
    $vars;
}

sub build_set_var_list{
    my($args) = @_;
    
    my(
       $i,
       $index,
       $instance,
       $oid,
       $name,
       $name_indexed,
       $start_index,
       $type,
       $value,
       $vars,
       @args,
       @oid_list,
       @var_list,
       );
    
    
    @args = @$args;
    @var_list = ();

    $start_index = 0;
    if ($args[0] =~ /^\d+/ && $args[0] !~ /^1.3.6.1/){
	$index = $args[0];
	$start_index ++;
    }
    elsif ($args[0] eq 'index'){
	$index = $args[1];
	$start_index+=2;
    }

    for ($i = $start_index; $i <= $#args; $i++){
	if (defined $index){ # Index may be passed for oids or names
	    $name = $args[$i];
	    ($name,$oid) = &get_name_and_oid($name);
	    $value = $args[$i+1];
	    $type = &SNMP::getType($name);

	    # Convert octets before sent out
	    $value = &pack_octet($value) if (!defined $SNMP::MIB{$name}{textualConvention} && $type =~ /octet/i);
	    push @var_list, ["$name","$index","$value"];
	    $i++;
	}
	elsif ($args[$i] =~ /^[a-zA-Z]+/ && $args[$i] =~ /^(\w+)\.\d*/ ){ #Format only allowed for names
	    ($name,$instance) = ($args[$i] =~ /^(\w+)\.(.*)$/);
	    return if ($instance eq '');
	    ($name,$oid) = &get_name_and_oid($name);
	    $value = $args[$i+1];
	    return if (!defined $value);
	    $type = &SNMP::getType($name);

	    # Convert octets before sent out
	    $value = &pack_octet($value) if (!defined $SNMP::MIB{$name}{textualConvention} && $type =~ /octet/i);
	    push @var_list, ["$name","$instance","$value"];
	    $i ++;
	}
	else{  #Use this case for names and oids
	    $name = $args[$i];
	    $instance = $args[$i+1];
	    $value = $args[$i+2];
	    ($name,$oid) = &get_name_and_oid($name);
	    $type = &SNMP::getType($name);
	    
	    # Convert octets before sent out
	    $value = &pack_octet($value) if (!defined $SNMP::MIB{$name}{textualConvention} && $type =~ /octet/i);
	    push @var_list, ["$name","$instance","$value"];
	    $i+=2;
	}
	    
    }

    $vars = new SNMP::VarList(@var_list);
    $vars;
}

sub pack_octet{
    my($value) = @_;
    my(
       $byte,
       $packed_val,
       @octets,
       @values,
       );
 
    @values = split(' ', $value);
    foreach $byte (@values) {
	push @octets, hex($byte);
    }
    $packed_val = pack('C*', @octets);
}

sub unpack_octet{
    my($name,$value) = @_;

    my(
       $octet,
       $octet_string,
       @octets,
       $tc,
       $delimiter,
       );

    $octet_string = '';
    if (!defined $Delimiter){
	$delimiter = ' ';
    }
    else{
	$delimiter = $Delimiter;
    }

    ##Check textual convection for type of octet-string
    $tc = $SNMP::MIB{$name}{textualConvention};
    if (!defined $tc){ #Real type is octet-string
	@octets = unpack("C*", $value);
	if (@octets){
	    foreach $octet (@octets){
		$octet = sprintf("%2.2x",$octet);
		$octet_string = "$octet_string$delimiter$octet";
	    }
	}
	else{
	    $octet_string = '';
	}
	$value = $octet_string;
    }
    elsif ($tc =~ /addr/i) {
	@octets = unpack("C*", $value);
	if (@octets){
	    foreach $octet (@octets){
		$octet = sprintf("%2.2x",$octet);
		$octet_string = "$octet_string$delimiter$octet";
	    }
	}
	else{
	    $octet_string = '';
	}
	$value = $octet_string
    }
    $value =~ s/^$delimiter//;
    $value;
}

## Add the indexes to the array for the snmpget
## and enumrations to values.
##
## Input : array of (oid-names)
## Output: array of (oids)
sub index_get_array {
    my($index, @names) = @_;
    my(
       $indexed_name,
       $name,
       @indexed_names,
       );

    foreach $name (@names) {
	$indexed_name = "$name.$index";
	push @indexed_names,$indexed_name;
    }

    return (@indexed_names);
} # end index_get_array

sub log_error{
    my($self,$func,$error,$oid_list,$error_index)= @_;

    my(
       $IP,
       $Comm_string,
       @oids,
       @names,
       $oid_hash,
       );

    $IP = $self->{IP};
    $Comm_string = $self->{community};

    if ($func =~ /set/){
	$oid_hash = &set_list_to_names_and_oids($oid_list);
	@oids = @{$oid_hash->{oids}};
	@names = @{$oid_hash->{names}};
    }
    else{
	$oid_hash = &get_list_to_names_and_oids($oid_list);
	@oids = @{$oid_hash->{oids}};
	@names = @{$oid_hash->{names}};
    }

    if ($error ne ''){
	if ($error =~ /timeout/i){
	    &log('fail',"\n\n$func Timeout\n");
	    &log('fail',"snmp$func $IP $Comm_string @oids\n");
	    &log('fail',"snmp$func $IP $Comm_string @names\n");
	    $self->error_detail('',"$func Timeout\n","snmp$func $IP $Comm_string @oids\n","snmp$func $IP $Comm_string @names\n");
	}
	else{
	    &log('fail',"\n\n$func $error\n");
	    &log('fail',"snmp$func $IP $Comm_string @oids\n");
	    &log('fail',"snmp$func $IP $Comm_string @names\n");
	    &log('fail',"snmp error index = $error_index\n");
	    $self->error_detail($error_index,"$func $error\n",$error_index,"snmp$func $IP $Comm_string @oids\n","snmp$func $IP $Comm_string @names\n","snmp error index = $error_index\n");
	}
    }
}

## Add the indexes to the array for an snmpset
##
## Input: index and array 
## Output: array of indexed names with corresponding type and value 
sub index_set_array {
    my($index, @names) = @_;
    my(
       $i,
       $indexed_name,
       $name,
       @indexed_names,
       );

    for ($i = 0; $i <= $#names; $i+=3) {
	# if the oid is a name
	$indexed_name = "$names[$i].$index";
	push @indexed_names, $indexed_name, $names[$i+1], $names[$i+2];
    }

    return (@indexed_names);
} # end sub index_set_array

##Convert names to oids
sub get_list_to_names_and_oids{
    my($args) = @_;
    my(
       $index,
       $i,
       $instance,
       $name,
       $name2,
       $oid,
       $oid2,
       $oid_name,
       @oid_names,
       @oids,
       $name_indexed,
       $start_index,
       $hash,
       @args,
       );

  
    @args = @$args;

    @oids = ();
    @oid_names = ();
    $start_index = 0;
    if ($args[0] =~ /^\d+/ && $args[0] !~ /^1.3.6.1/){
	$index = $args[0];
	$start_index ++;
    }
    elsif ($args[0] eq 'index'){
	$index = $args[1];
	$start_index+=2;
    }
    for ($i = $start_index; $i <= $#args; $i++){
	if (defined $index){
	    $name = $args[$i];
	    $instance = $index;
	    ($name,$oid) = &get_name_and_oid($name);
	    $oid_name = "$name.$instance";
	    $oid = "$oid.$instance";
	    push @oid_names,$oid_name;
	    push @oids,$oid;
	}
	elsif ($args[$i] =~ /^(\w+)\.\d+/ && $args[$i] =~ /^[a-zA-Z]+/){ # only allowed for names not oids
	    ($name,$instance) = ($args[$i] =~ /^(\w+)\.(.*)$/);
	    ($name,$oid) = &get_name_and_oid($name);

	    $oid_name = "$name.$instance";
	    $oid = "$oid.$instance";
	    push @oid_names,$oid_name;
	    push @oids,$oid;
	}
	else{ # Instance is either passed after name or there is none
	    $name = $args[$i];
	   
	    $instance = $args[$i+1] if defined $args[$i+1];
	    if (!defined $instance){ #No instance 
		($name,$oid) = &get_name_and_oid($name);
		push @oid_names,$name;
		push @oids,$oid;
	    }
	    elsif ($instance =~ /^\d+/ && $instance !~ /^1.3.6.1/){
		$instance = $args[$i+1];
		($name,$oid) = &get_name_and_oid($name);
		$oid_name = "$name.$instance";
		$oid = "$oid.$instance";
		push @oid_names,$oid_name;
		push @oids,$oid;
		$i++;
	    }
	    else{ ## Instance is name or oid (no instance passed (for walk only))
		($name,$oid) = &get_name_and_oid($name);
		if (defined $args[$i+1]){
		    $name2 = $args[$i+1];
		    ($name2,$oid2) = &get_name_and_oid($name2);
		    push @oid_names,$name,$name2;
		    push @oids,$oid,$oid2;
		    $i++;
		}
		else{
		    push @oids,$oid;
		    push @oid_names,$name;
		}
	    }
	}
    }
    $hash->{names} = [@oid_names];
    $hash->{oids} = [@oids];

    $hash;
}##Convert names to oids

sub set_list_to_names_and_oids{
    my($args) = @_;
    my(
       $index,
       $i,
       $instance,
       $name,
       $oid,
       $type,
       $value,
       $temp_value,
       $oid_name,
       @oid_names,
       @oids,
       @oid_names,
       $name_indexed,
       $start_index,
       $hash,
       @args,
       );

    @args = @$args;

    $start_index = 0;
    if ($args[0] =~ /^\d+/ && $args[0] !~ /^1.3.6.1/){
	$index = $args[0];
	$start_index ++;
    }
    elsif ($args[0] eq 'index'){
	$index = $args[1];
	$start_index+=2;
    }

    @oids = ();
    @oid_names = ();
    # Check if type field is passed for snmpset
    for ($i = $start_index; $i <= $#args; $i++){
	if (defined $index){
	    $name = $args[$i];
	    $instance = $index;
	    $temp_value = $args[$i+1];
	    return if (!defined $temp_value);
	    ($name,$oid) = &get_name_and_oid($name);
	    $type = &SNMP::getType($name);
	    $i++;
	    if ($temp_value =~ /^\d+/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value ||  $value eq '');
	        push @oid_names,"$name.$instance",$value;
	        push @oids,"$oid.$instance",$temp_value;
	    }
	    elsif ($temp_value =~ /^[a-zA-Z]/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value || $value eq '');
	        push @oid_names,"$name.$instance",$temp_value;
	        push @oids,"$oid.$instance",$value;
	    }
            else{
	        push @oid_names,"$name.$instance",$temp_value;
	        push @oids,"$oid.$instance",$temp_value;
            }
	}
	elsif ($args[$i] =~ /^[a-zA-Z]+/ && $args[$i] =~ /^(\w+)\.\d*/ ){ # Use this case for names
	    ($name,$instance) = ($args[$i] =~ /^(\w+)\.(.*)$/);
	    return if (!defined $instance || $instance eq '');
	    $temp_value = $args[$i+1];
	    return if (!defined $temp_value);
	    ($name,$oid) = &get_name_and_oid($name);
	    $type = &SNMP::getType($name);
	    $i++;

	    if ($temp_value =~ /^\d+/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value || $value eq '');
	        push @oid_names,"$name.$instance",$value;
                push @oids,"$oid.$instance",$temp_value;
	    }
	    elsif ($temp_value =~ /^[a-zA-Z]/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value || $value eq '');
                push @oid_names,"$name.$instance",$temp_value;
	        push @oids,"$oid.$instance",$value;
	    }
            else{
                push @oid_names,"$name.$instance",$temp_value;
                push @oids,"$oid.$instance",$temp_value;
            }
	}
	else{
	    $name = $args[$i];
	    $instance = $args[$i+1];
	    $temp_value = $args[$i+2];
	    ($name,$oid) = &get_name_and_oid($name);
	    $type = &SNMP::getType($name);
	    $i+=2;
	    if ($temp_value =~ /^\d+/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value || $value eq '');
	        push @oid_names,"$name.$instance",$value;
                push @oids,"$oid.$instance",$temp_value;
	    }
	    elsif ($temp_value =~ /^[a-zA-Z]/ && $type =~ /integer/i){
		$value = &SNMP::mapEnum($name,$temp_value);
                $value = $temp_value if (!defined $value || $value eq '');
                push @oid_names,"$name.$instance",$temp_value;
	        push @oids,"$oid.$instance",$value;
	    }
            else{
                push @oid_names,"$name.$instance",$temp_value;
                push @oids,"$oid.$instance",$temp_value;
            }
	}
    }

    $hash->{names} = [@oid_names];
    $hash->{oids} = [@oids];

    $hash;
}


sub format_array {
    my($format, $vars) = @_;
    my(
       $enum,
       $i,
       $instance,
       $name,
       $name_instance,
       $number_values,
       $octet,
       $octet_string,
       $oid,
       $option,
       $tc,
       $status,
       $type,
       $temp_value,
       $value,
       @format,
       @octets,
       @result,
       );
    
    ## Variable init.
    @format = split('', $format);

    $number_values = @{$vars};
    @result = ();
    for ($i = 0; $i< $number_values; $i++){
	$name = $vars->[$i]->[0];
	($name,$oid) = &get_name_and_oid($name);
     	$instance = $vars->[$i]->[1];
	$name_instance = "$name.$instance";
	$temp_value = $vars->[$i]->[2];
	$type = $vars->[$i]->[3];
	
	foreach $option (@format) {
	    if ($option eq 'o') {
		push @result, "$oid.$instance";
		next; 
	    }
	    if ($option eq 'O') {
		push @result, "$oid";
		next; 
	    }
	    if ($option eq 't') {
		push @result, $type; 
		next; 
	    }
	    if ($option eq 'v' || $option eq 'e'){
		$value = &convert_value($option,$name,$type,$temp_value);
		push @result, $value;
		next;
	    }
	    if ($option eq 'i') {
		push @result, $instance; 
		next; 
	    }
	    if ($option eq 'n') { 
		push @result, $name_instance; 
		next; 
	    }	
	    if ($option eq 'N') { 
		push @result, $name; 
		next; 
	    }
	}
    }

    return(@result);

} # end sub format_array

sub format_hash {
    my($format, $vars) = @_;
    my(
       $enum,
       $hash,
       $i,
       $instance,
       $name,
       $name_instance,
       $number_values,
       $octet,
       $octet_string,
       $oid,
       $option,
       $tc,
       $status,
       $type,
       $temp_value,
       $value,
       @format,
       @octets,
       @result,
       );
    
    ## Variable init.
    @format = split('', $format);

    $number_values = @{$vars};
    @result = ();
    for ($i = 0; $i< $number_values; $i++){
	$name = $vars->[$i]->[0];
	($name,$oid) = &get_name_and_oid($name);
     	$instance = $vars->[$i]->[1];
	$name_instance = "$name.$instance";
	$temp_value = $vars->[$i]->[2];
	$type = $vars->[$i]->[3];

	$value = &convert_value($format,$name,$type,$temp_value);

	$hash->{$name}{$instance} = $value;

    }

    $hash;

} # end sub format_array

sub convert_value{
    my($format,$name,$type,$temp_value) = @_;

    my($value);

    if ($format =~ /e/){
	#Convert the packed data to hex format (octet-string)
	if ($type =~ /octet/i){
	    $value = &unpack_octet($name,$temp_value);
	}
	elsif ($type =~ /integer/i){
	    $value = $temp_value;
	}
	elsif ($type =~ /ticks/i) {
	    $value = &decode_uptime($temp_value);
	}
	else{
	    $value = $temp_value;
	}
    }
    elsif ($format =~ /v/){
	if ($type =~ /integer/i && $temp_value =~ /^[a-zA-Z]/){
	    $value = &SNMP::mapEnum($name,$temp_value);
	    $value = $temp_value if (!defined $value || $value eq '');
	}
	elsif ($type =~ /octet/i){
	    $value = &unpack_octet($name,$temp_value);
	}
	else{
	    $value = $temp_value;
	}
    }
    $value;
}

sub get_name_and_oid{
    my($value) = @_;
    
    my(
       $oid,
       $name,
       @oid_name,
       );
    
    return if (!defined $value);
    if ($value =~ /^[a-zA-Z]+/){ #Value is a mib name not an oid
	$name = $value;
	$oid = &SNMP::translateObj($value);
	$oid =~ s/^\.//;
    }
    else{     # Value is an oid
	$oid = $value;
	$oid =~ s/^\.//;
	$name =  &SNMP::translateObj($oid);
    }

    @oid_name = ($name,$oid);
    @oid_name;
}
sub print_array {
    my($format, @list) = @_;
    my(
       $count,
       $number_items,
       $string,
       $value,
       @number_items,
       );

    ## Variable init.
    @number_items = split('',$format);
    $number_items = @number_items;
    $count = 1;
    $string = '';

    foreach $value (@list) {
	$string = "$string $value";
	if ($count >= $number_items) {
	    print "$string\n";
	    $string = '';
	    $count = 1;
	}
	else {
	    $count ++;
	}
    }
} # end sub print_array



##--------------------------------------------------------------------
## Usage: &decode_uptime($timetick)
## Description: decode an time tick data item
## Input: $timetick, encoded timetick
## Output: Time in days, hours:minute:seconds
##-------------------------------------------------------------------
sub decode_uptime {
    my($uptime) = @_;
    my(
       $days,
       $hours,
       $minutes,
       $result,
       $seconds,
       );

    $uptime /= 100;
    $days = $uptime / (60 * 60 * 24);
    $uptime %= (60 * 60 * 24);

    $hours = $uptime / (60 * 60);
    $uptime %= (60 * 60);

    $minutes = $uptime / 60;
    $seconds = $uptime % 60;

    if ($days == 0) {
	$result = sprintf("%d:%02d:%02d", $hours, $minutes, $seconds);
    } 
    elsif ($days == 1) {
	$result = sprintf("%d day, %d:%02d:%02d",
			  $days, $hours, $minutes, $seconds);
    } 
    else {
	$result = sprintf("%d days, %d:%02d:%02d",
			  $days, $hours, $minutes, $seconds);
    }

    return $result;
} # end sub decode_uptime


sub log {
    my($log_level, $message) = @_;

    my(
       $max_log_level,
       );

    if (defined $SNMP::Util::Max_log_level){
	$max_log_level = $SNMP::Util::Max_log_level;
    }
    else{
	$max_log_level = $ENV{'MAX_LOG_LEVEL'};
	if (!defined $max_log_level || $max_log_level eq '') {
	    $max_log_level = $ENV{'ATS_MAX_LOG_LEVEL'};
	}
    }

    $max_log_level = 2 unless defined $max_log_level;
    $log_level = 2 unless defined $log_level;

    $SNMP::Util::Max_log_level = $max_log_level unless defined $SNMP::Util::Max_log_level;

    ## Convert max_log_level text tags to numbers.
    if ($max_log_level =~ /none/i || $max_log_level =~ /off/i) {
	$max_log_level = 0;
    }
    elsif ($max_log_level =~ /fail/i) {
	$max_log_level = 1;
    }
    elsif ($max_log_level =~ /status/i) {
	$max_log_level = 2;
    }
    elsif ($max_log_level =~ /debug/i) {
	$max_log_level = 3;
    }

    ## Convert log_level text tags to numbers.
    if ($log_level =~ /none/i || $log_level =~ /off/i) {
	## No logging
	$log_level = 0;
    }
    elsif ($log_level =~ /fail/i) {
	## Failures only
	$log_level = 1;
    }
    elsif ($log_level =~ /status/i) {
	## Failures and general status
	$log_level = 2;
    }
    elsif ($log_level =~ /debug/i) {
	## Failures, status, and details
	$log_level = 3;
    }

    if ($log_level <= $max_log_level){
	print "$message";
    }
} # end sub log


############################# Error Handling Methods #########################


sub die {
    my(@msgs) = @_;
    my $prg;

    ## Get the program's name.
    $prg = $0;
    $prg =~ s#\s+.*$##;		# truncate everything but first word
    $prg =~ s#^.*/##;		# truncate leading path

    ## Print error message along w/ stack backtrace and then die.
    $Carp::CarpLevel = 1;
    &Carp::confess(join('', "$prg died: ", @msgs, "\n"));
} # end sub die


sub error {
    my($self, $errortype, @errormsgs) = @_;


    if (! defined $errortype) {  # no arg given
	if ($self->{"errormsg"}) {
	    return 1;
	}
	else {
	    return '';
	}
    }
    else {  # arg given
	## Save error message.
	$self->{"errortype"} = $errortype;
	$self->{"errormsg"} = join '', @errormsgs;

	## Die or return with error.
	if ($self->{errormode} ne "return") {
	    &die($self->{"errormsg"});
	}
	else {
	    return wantarray ? () : undef;
	}
    }
} # end sub error

sub error_detail {
    my($self,$error_index, @errormsg_detail) = @_;

    ## Save error message.
    push @errormsg_detail,"snmp error index = $error_index\n" if ($error_index ne '');
    $self->{"errormsg_detail"} = join '', @errormsg_detail;
    
    ## Die or return with error.
    if ($self->{errormode} ne "return") {
	    &die($self->{"errormsg_detail"});
	}
    else {
	return wantarray ? () : undef;
    }
} # end sub error


sub error_index {
    my($self, $errortype, @errormsgs) = @_;

    if (! defined $errortype) {  # no arg given
        if ($self->{"errormsg"}) {
            return 1;
        }
        else {
            return '';
        }
    }
    else {  # arg given
        ## Save error message.
        $self->{"errortype"} = $errortype;
        $self->{"errormsg"} = join '', @errormsgs;

        ## Die or return with error.
        if ($self->{errormode} ne "return") {
            &die($self->{"errormsg"});
        }
        else {
            return wantarray ? () : undef;
        }
    }
} # end sub error


sub error_reset {
    my($self) = @_;
    
    ## Save error message.
    $self->{"errortype"} = "";
    $self->{"errormsg"} = "";
    $self->{"errormsg_detail"} = "";

    1;
} # end sub error_reset


sub errmode {
    my($self, $mode) = @_;
    
    if (defined $mode) {
	if ($mode =~ /^return$/i) {
	    $self->{errormode} = "return";
	}
	else {
	    $self->{errormode} = "die";
	}
    }

    return $self->{errormode};
} # end sub errmode


sub errmsg {
    my($self, $msg) = @_;

    if (defined $msg) {
	$self->{errormsg} = $msg;
    }

    return $self->{errormsg};
} # end sub errmsg

sub errmsg_detail {
    my($self, $msg) = @_;

    if (defined $msg) {
	$self->{errormsg_detail} = $msg;
    }
    
    return $self->{errormsg_detail};
} # end sub errmsg



sub errtype {
    my($self, $type) = @_;
    
    if (defined $type) {
	$self->{errortype} = $type;
	return '';
    }

    return $self->{errortype};
} # end sub errtype


1;

__END__;


######################## User Documentation ##########################


## To format the following user documentation into a more readable
## format, use one of these programs: pod2man; pod2html; pod2text.

=head1 NAME

SNMP::Util - Snmp modules to perform snmp set,get,walk,next,walk_hash etc.

=head1 SYNOPSIS

C<use SNMP::Util;>


## Documentation (POD)
=head1 NAME

 Perl SNMP utilities - SNMP::Util - Version 1.8


=head1 DESCRIPTION

This Perl library is a set of utilities for configuring and monitoring SNMP
based devices.  This library requires the UCD port of SNMP and the SNMP.pm
module writted by Joe Marzot.

=head1 Version
    
    1.0 Initial Release
    1.1 Fixed Manifest File
    1.2 Added get_hash / walk_hash now calls walk / Modified output in poll_value
    1.3 Added use strict to library and fixed some bugs with my vars
    1.4 Fixed code to elminate perl warning
    1.5 Changed all mapInt functions to mapEnum - (support for mapInt not in 
        Joe Marzot's version 1.8).
    1.6 Updated docs html and text
    1.7 Includes patches from Charles Anderson 
    1.8 Includes patches from  tyoshida

=head1 Software requirements

The following applications need to be built and installed before running the 
SNMP::Util application.

    ucd-snmp-3.5 - ftp:://ftp.ece.ucdavis.edu:/pub/snmp/ucd-snmp.tar.gz
    SNMP-1.8 - www.perl.com/CPAN


=head1 Summary of functions

 get - snmpget and return formatted array
 get_hash - snmpget and return hash
 get_set_restore - get value, set new range of values and restore value
 next - snmpnext and return formatted array
 ping_check - get uptime and return 1 if reachable
 ping_check_exit - get uptime and exit if not reachable
 poll_device - poll a device until it becomes reachable
 poll_devices - poll several devices until they becomes reachable
 poll_value - snmpget in a loop until variable reaches desired state
 set - snmpset and return
 set_get - snmpset followed by get and check 
 walk - snmpwalk and return formatted array
 walk_hash - snmpwalk and return hash ($hash->{mibname}{index} = value)



=head1 Creation on the SNMP::Util object

You must first do a use statement to pull in the library. Then the snmp object can
be created.

 #!/usr/local/lib/perl
 use lib "put lib path here" 
 use SNMP::Util;

 The SNMP::Util object is created as follows:

 $snmp = new SNMP::Util(-device => $IP,
                       -community => $community, 
                       -timeout => 5,             
                       -retry => 0,             
                       -poll => 'on',            
                       -poll_timeout => 5,        
                       -verbose => 'off',         
	 	       -errmode => 'return',    
                       -delimiter => ' ', 
		      )
 
 community = snmp community string
 timeout = snmp timeout in seconds (You may also use sub second values ie 0.5)
 retry = number of snmp retries on timeouts
 poll = poll the unreachable device after number of retries reached and then retry again
 poll timeout = poll timeout in minutes default = 5 minutes
 verbose = controls the output of the snmp low level library
 errmode = error mode ('return' on error or 'die' on error) default = return
 delimeter = specifies the character to use between octets when getting octet-strings
 
 
 Note: Delimiter can also be set by using the setting the Global variable as follows:
       $SNMP::Util::Delimiter = '-'


=head2 Creating and using multiple objects

First populate an array of IP addresses:

 @IP_array = ('1.1.1.1','1.1.1.2','1.1.1.3','1.1.1.4')
    
 foreach $IP (@IP_array){

    $snmp->{$IP} = new SNMP::Util(-device => $IP,
                      -community => $community, 
		      -timeout => 5,             
		      -retry => 0,               
		      -poll => 'on',          
		      -delimiter => ' ', 
		      )
 }

 #Now get the uptime for each switch
 foreach $IP (@IP_array){
     $uptime = $snmp->{$IP}->get('v','sysUpTime.0')
     print "Uptime for $IP = $uptime\n"
 }


=head1 How to use the object for a simple snmpget

   $uptime = $snmp->get('v','sysUpTime.0')
             where 'v', is the format of the output (v = value)
             and $uptime contains the system uptime in 10ths of seconds

=head1 MIB Loading

The SNMP::Util module loads the mib using the SNMP::Util_env.pm module by using the following statements.

 use SNMP::Util_env
 # Initialize mib
 &SNMP::initMib()
 
 You must update the SNMP::Util_env.pm file or simply set up these environment
 variables and the SNMP::Util_env.pm file will not override them.
 
 The environment variables are as follows:

 $ENV{'MIBDIRS'} = '/usr/local/lib/snmp/mibs' 
 $ENV{'MIBFILES'} = '/ats/data/mibs/rfc1850.mib:
 /ats/data/mibs/rfc1406.mib:/ats/data/mibs/rfc1407.mib:
 /ats/data/mibs/rfc1595.mib:/ats/data/mibs/rfc1724.mib'
   
 You can specify whatever MIBS you would like to load.

=head1 Error Handling method

All error handling is done through the error handling method (error).
The error message can be obtained by using the method (errmsg)
The detailed error message can be obtained by using the method (errmsg_detail)
 
 This error method returns a boolean result to indicate if an error ocurred

 example:

    if ($snmp->error){
	$error = $snmp->errmsg;
	$error_detail = $snmp->errmsg_detail;
	print "snmp error = $error\n";
	print "snmp error detail = $error_detail\n";
    }


=head1  Print Output Logging

The printing of output is controlled by the logging routine.  the amount of output is
configured by setting the MAX_LOG_LEVEL environment variable.  There are four levels of output logging: (none,status,fail,debug).  You may also set the logging using the global variable Max_log_level.

 none = print  no output (use errmsg only for errors)
 status = print general status information
 fail = print general status and failures
 debug = print general status, failures, and debug information
  
 You can set the environment variable in your environment or inside the 
 program using the following format:
 
    $env{'MAX_LOG_LEVEL'} = 'debug'

    or using the global 
    $SNMP::Util::Max_log_level = 'debug'

 Example Output from Logging:

    get (noSuchName) There is no such variable name in this MIB.
    snmpget 100.100.100.1 public 1.3.6.1.2.1.2.2.1.1.1 1.3.6.1.2.1.2.2.1.7.1
    snmpget 100.100.100.1 public ifIndex.1 ifAdminStatus.1
    snmp error index = 1
   
    Note: error index = the index of the var bind that failed




=head1 Formatting SNMP output (get, next, walk)

The SNMP utilities have a formatting function which will format the return values 
which are most cases an array.

 The format options are specified as strings as follows:
 
 print " format string = oOnNtvei\n"
 print " o = oid with index\n"
 print " O = oid without index\n"
 print " n = name with index\n"
 print " N = name without index\n"
 print " t = type\n"
 print " v = value\n" 
 print " e = enumeration\n"
 print " i = instance of the mib variable\n\n"
 
 Note: enumerations apply to integers and timeticks.  It will convert integer values
 to enumerations and it will convert timeticks to days,hours,minutes,seconds.
 
 example usage:
 
 @result = $snmp->get('nve','sysUptime.0')
 $result[0] = sysUptime.0
 $result[1] = 13392330
 $result[2] = 1 days, 13:12:03
 
 Note: Any format can be used for the (get,walk,next routines)
       Only 'e' or 'v' is needed in the walk_hash routine.


This formatting was designed to allow the user to format the output in
whatever format they need for there application.  You may want to use
the 'v' option when comparing timetick values, but you may want to use 
the 'e' option for the human readable display.

The snmpget routine may be equated to an array if the formatting has more than
one value or it may be equated to a scalar value if the formatting has only one
value.  It must be equated to an array if the snmpget is a multi var bind.


=head1 Input Formatting

The input supplied to the SNMP functions is designed to be very flexible and
allows the user to use shortcuts to apply instances to variables.

=head2 Input formatting options for the get,next,walk

B<Simple format name.instance or oid.instance>

 $snmp->get('e','ifIndex.1','ifAdminStatus.1','ifOperStatus.1')
 $snmp->get('e','1.3.6.1.2.1.2.2.1.1.1','1.3.6.1.2.1.2.2.1.7.1','1.3.6.1.2.1.2.2.1.8.1')


B<Shortcut format instance up front (no instance in mib name or oid>

 $snmp->get('e',1,'ifIndex','ifAdminStatus','ifOperStatus')
 $snmp->get('e',1,'1.3.6.1.2.1.2.2.1.1','1.3.6.1.2.1.2.2.1.7','1.3.6.1.2.1.2.2.1.8')

B<Long format name,instance,name,instance etc of oid,instance,oid,instance etc>

 $snmp->get('e','ifIndex',1,'ifAdminStatus',1,'ifOperStatus',1)
 $snmp->get('e','1.3.6.1.2.1.2.2.1.1',1,'1.3.6.1.2.1.2.2.1.7',1,'1.3.6.1.2.1.2.2.1.8',1)

You may also set up an array for any of the above formats and pass the array into the
get function as follows:

 @oids = ('ifIndex.1','ifAdminStatus.1','ifOperStatus.1')
 $snmp->get('e',@oids)

B<Hash like format> name => instance or oid => instance

 $interface = 1
 $snmp->get(
	   'e',
	   ifIndex => $interface,
	   ifAdminStatus => $interface,
	   ifOperStatus => $interface,
	   ifSpeed => $interface,
	   )
 or 

 $snmp->get(
	   index => $interface,
	   ifIndex,
	   ifAdminStatus,
	   ifOperStatus,
	   ifSpeed,
	   )


B<Calling get with dashed options>

 @result = $snmp->get(
                     -format => 'ne',
                     -oids => [
                               ifIndex => $interface,
                               ifAdminStatus => $interface,
                               ifOperStatus => $interface,
                               ifSpeed => $interface,
                               ],
                    )
 or 
 @oids = ('ifIndex.1','ifAdminStatus.1','ifOperStatus.1')
 @result = $snmp->get(
                     -format => 'ne',
                     -oids => \@oids,
		     )
 
Note: When using the dashed option format, you must pass the array by reference as shown 
above.
 
 
=head2 Input formats for the set routine

B<Simple format name.instance,value or oid.instance,value>

 $snmp->set('ifAdminStatus.1','up')
 $snmp->set('1.3.6.1.2.1.2.2.1.7.1','up')


B<Shortcut format instance up front (no instance in mib name or oid>

 $snmp->set(1,'ifAdminStatus','up')
 $snmp->set(1,'1.3.6.1.2.1.2.2.1.7','up')

B<Long format name,instance,value or oid,instance,value>

 $snmp->set('ifAdminStatus',1,'up')
 $snmp->set('1.3.6.1.2.1.2.2.1.7',1,'up')
 
You may also set up an array for any of the above formats and pass the array into the
get method as follows:
 
 @oids = ('ifAdminStatus.1','up')
 $snmp->set(@oids)

B<Hash like format>

 $snmp->set(
	   "ifAdminStatus.$interface" => 'up',
	   )
 or 

 $snmp->set(
	   index => $interface,
	   "ifAdminStatus" => 'up',
	   )


 
 
=head1 SNMP Method summary


=head2 get

The get will do a snmpget and return an array specified by the format
statement.

 Usage: @result = $snmp->get('ne','ifAdminStatus.1')
        $result[0] = ifAdminStatus.1
	$result[1] = 'up'

	$result = $snmp->get('e','ifAdminStatus.1')
        Note: As shown above, the result is a scalar if only one value is returned

=head2 get_hash

This method will do an snmpget and return a hash.   The format for the hash is
(value = $hash->{mibname}{index}).

 
 example: $hash = $snmp->get_hash('ne','ifIndex.1','ifIndex.2',
				  'ifOperStatus.1','ifOperStatus.2'); 

 $hash->{ifIndex}{1} = 1
 $hash->{ifIndex}{2} = 2
 $hash->{ifOperStatus}{1} = up
 $hash->{ifOperStatus}{2} = up

 Note: Valid format statements for get_hash are 'ne' or 'nv'
 
=head2 get_set_restore

The get_set_restore will get the variable, set it to a range and restore the value

 Usage:  @result = $snmp->get_set_restore('1..10','ifAdminStatus.1');
         where the value '1..10' is the range of values

 Note: The range is specified using .. for ranges and , for individual values. 

=head2 next

The next will do a snmpnext and return an array specified by the format
statement.

 Usage:  @result = $snmp->next('ne','ifAdminStatus.1')
	$result[0] = ifAdminStatus.2
	$result[1] = 'up'

	$result = $snmp->next('e','ifAdminStatus.1')
        Note: As shown above, the result is a scalar if only one value is returned
 
=head2 ping_check

The ping_check will do a snmpget of uptime and return 1 if device is alive

=head2 ping_check_exit

The ping_check will do a snmpget of uptime and exit if not alive 

=head2 poll_device

The poll_device will loop on the snmpget of uptime command until the device is reachable. 
The loop will exit once the poll_timeout time is reached (default = 5 minutes).

=head2 poll_devices

The poll_devices will do a snmpget of uptime on several devices until the device are reachable.
The loop will exit once the poll_timeout time is reached (default = 5 minutes).

 $snmp->poll_devices(@IP_array);
 where @IP_array = array of IP addresses
				     

=head2 poll_value

The poll value method will poll a mib variable until it reaches that state and returns the amount of time it took to reach that state

 Usage: $snmp->poll_value(-oid => "ifAdminStatus.$interface",
			 -state => 'up',
			 -timeout => 120,
			 -montime => 5,
			 -delay   => 1)

 or 
  
 $snmp->poll_value(-oid     => "1.3.6.1.2.1.2.2.1.8",
                  -instance => $interface,
                  -state => 'up',
                  -timeout => 120,
                  -montime => 5,
                  -delay   => 1)

or  

 use a array ref if you want the polling to stop when the result 
 matches more than one value

 $snmp->poll_value(-oid     => "1.3.6.1.2.1.2.2.1.8",
                  -instance => $interface,
                  -state => ['up','down']
                  -timeout => 120,
                  -montime => 5,
                  -delay   => 1)

 
 Note: You must use the instance when using oids.


=head2 set

The set will set a group of variables and return 1 if passed

 Usage:  @result = $snmp->set(
			     index => 1,
			     ifAdminStatus => 'up',
			     )

=head2 set_get

The set_get will set a group of variables,get,check and return 1 if passed

 Usage:  @result = $snmp->set(
			     index => 1,
			     ifAdminStatus => 'up',
			     )


=head2 walk

The walk will do a snmpwalk and return an array specified by the format
statement. It also has a special print option to print out each loop in the 
walk. This method is capable of doing multivarbind walks.

 Usage: @result = $snmp->walk(-format => 'ne',
			       -oids =>['ifAdminStatus'],
			       -print => 'on');
			   
		  where print = 'on' or 'off'

        or use the shortcut format (Note: print will be disabled by default
				     
        @result = $snmp->walk('ne','ifAdminStatus');			      

	$result[0] = ifAdminStatus.1
	$result[1] = 'up'
        $result[2] = ifAdminStatus.2
	$result[3] = 'up'
        ...

=head2 walk_hash

The walk_hash will do a snmpwalk and return a hash with the value specified by the format.
This method is capable of doing multivarbind walks.

 Usage: $result = $snmp->walk_hash('e','ifIndex','ifAdminStatus','ifOperStatus')
        $result->{ifIndex}{1} = 1
	$result->{ifAdminStatus}{1} = 'up'
        $result->{ifOperStatus}{1} = 'up'
	$result->{ifIndex}{2} = 2
	$result->{ifAdminStatus}{2} = 'up'
        $result->{ifOperStatus}{2} = 'up'

 or 
 Usage: $result = $snmp->walk_hash('v','ifIndex','ifAdminStatus','ifOperStatus')
        $result->{ifIndex}{1} = 1
	$result->{ifAdminStatus}{1} = 1
        $result->{ifOperStatus}{1} = 1
	$result->{ifIndex}{2} = 2
	$result->{ifAdminStatus}{2} = 1
        $result->{ifOperStatus}{2} = 1

 


























