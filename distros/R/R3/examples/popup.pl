#!/usr/bin/perl

use R3;

%logon = (
	client=>"100", 
	user=>"USER116",
	passwd=>"SECRET",
        host=>"shiva",
	sysnr=>0,
);

print "Send popup message to a logged on R/3 user!\n\n";
print "CLIENT: "; $client=<>; chomp $client;
print "USER: "; $user=<>; chomp $user;
print "MESSAGE: "; $msg=<>; chomp $msg;
eval {
	$conn=new R3::conn (%logon);
	$popup=new R3::func ($conn, "TH_POPUP");
	call $popup ([CLIENT=>$client, USER=>$user, MESSAGE=>$msg,
		CUT_BLANKS=>'X'], []);
	print "Message sent!\n";
};
print $@ if $@;
