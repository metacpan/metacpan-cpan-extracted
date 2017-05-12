#!/usr/bin/perl

use R3;

%logon = (
	client=>"100", 
	user=>"USER116",
	passwd=>"SECRET",
		host=>"shiva",
	sysnr=>0,
	pre4=>0,
);

print "\nR/3 users on $logon{host}\n";
eval {
	$conn=new R3::conn (%logon);
	$usr_tabl=new R3::itab ($conn, "UINFO");
	$list_usr=new R3::func ($conn, "THUSRINFO");
	call $list_usr ([], [USR_TABL=>$usr_tabl]);
	printf "\n%-7.7s %-14.14s %-24.24s %-8.8s\n\n",
		"Client", "User", "Terminal", "Time";
	for ($i=1; $i<=$usr_tabl->get_lines(); $i++)
	{
		%val=$usr_tabl->get_record($i);
		$t=$val{ZEIT};
		$t=substr($t,0,2) . ":" . substr($t,2,2) . ":" . substr($t,4,2);
		printf "%-7.7s %-14.14s %-24.24s %-8.8s\n",
			$val{MANDT}, $val{BNAME}, $val{TERM}, $t;
	}
};
print $@ if $@;
