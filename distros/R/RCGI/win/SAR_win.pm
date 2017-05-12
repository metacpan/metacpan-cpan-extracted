package SAR;

sub system_activity_report {
    my($wait_time) = shift;
    if (!defined($wait_time)) {
	$wait_time = 60;
    }

    my($sec, $min, $hour) = localtime(time());
    my($first_time) = time();
    my($first_usertime, $first_systime, $first_idletime, $first_uptime) = Pstat();
    sleep $wait_time;
    my($last_time) = time();
    my($last_usertime, $last_systime, $last_idletime, $last_uptime) = Pstat();

    my($diff_user) = $last_usertime - $first_usertime;
    my($diff_sys) = $last_systime - $first_systime;
    my($diff_idle) = $last_idletime - $first_idletime;
    my($diff_time) = $last_time - $first_time;

    my($prc_user) = int( ( $diff_user * 100) / $diff_time);
    my($prc_sys) = int( ( $diff_sys * 100) / $diff_time);
    my($prc_idle) = int( ( $diff_idle * 100) / $diff_time);
    my($prc_io) = 100 - ($prc_user + $prc_sys + $prc_idle);

    my($mday, $mon, $year);
    ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
    $mon++;
    $time = sprintf("%2.2d:%2.2d:%2.2d",$hour,$min,$sec);
    @result = ( "$mon/$mday/$year $time",
	       $prc_user,$prc_sys,$prc_io,$prc_idle );
    return @result;
}

sub Pstat {
    my($uptime_days, $uptime_hr, $uptime_min, $uptime_sec);
    my($usertime_hr, $usertime_min, $usertime_sec);
    my($kernel_hr, $kernel_min, $kernel_sec, $process);
    my($user_cpu, $sys_cpu);
    my($uptime, $idletime, $usertime, $systime);

    open(PSTAT,"c:\\ntreskit\\pstat |");
    while(<PSTAT>) {
	if (/^\s*User\s*Time/) {
	    last;
	} 
	if (/uptime\:/) {
	    ($uptime_days, $uptime_hr, $uptime_min, $uptime_sec) =
		/uptime\:\s*(\d+)\s+(\d+)\:(\d+)\:(\d+)\./;
	    $uptime = ($uptime_days * 24 * 3600) + $uptime_hr * 3600 +
		$uptime_min * 60 + $uptime_sec;
	}
    }
    while(<PSTAT>) {
	if (/^\s*$/ || /^\s*pid\:/) {
	    last;
	} 
	($usertime_hr, $usertime_min, $usertime_sec,
	 $kernel_hr, $kernel_min, $kernel_sec, $process) =
	 /^\s*(\d+)\:(\d+)\:(\d+)\.\d+\s+(\d+)\:(\d+)\:(\d+)\.\d+[\s\d]+(.*)$/;
	$user_cpu = $usertime_hr * 3600 + $usertime_min * 60 + $usertime_sec;
	$sys_cpu  = $kernel_hr * 3600 + $kernel_min * 60 + $kernel_sec;
	if ($process =~ /Idle Process/) {
	    $idletime = $user_cpu + $sys_cpu;
	} else {
	    $usertime += $user_cpu;
	    $systime += $sys_cpu;
	}
    }
    close(PSTAT);
    return ($usertime, $systime, $idletime, $uptime);
}


1;

