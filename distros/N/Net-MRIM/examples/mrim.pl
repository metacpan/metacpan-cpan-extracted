#!/usr/bin/perl -w
#
# Copyright (c) 2007 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)

use strict;
use Net::MRIM;
use threads;
use threads::shared;
use Term::ReadLine;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

#
#  Enter login information below !
#

my $LOGIN = "login\@mail.ru";
my $PASSWORD = "password";

#
# the real stuff starts here...
#

$|=1;

my $data : shared = "";
my @dataout : shared = ();
my @clistkeys : shared = ();
my @clistitems : shared = ();

my $thr = threads->new(\&mrim_conn);

my $term = new Term::ReadLine 'MRIM';
my $prompt : shared = "MRIM > ";

my $input="";

while ($input=$term->readline($prompt)) {
	if ($input eq "quit") { cleanup_exit(); }
	elsif ($input eq "sh") { flush_data(); } 
	elsif ($input eq "cl") {
		print BOLD "\n## Contact List ##\n";
		for (my $i=0; $i<scalar(@clistkeys); $i++) {
			my $clitem=$clistkeys[$i];
			print "".($i+1)." : ".$clistkeys[$i]." (".$clistitems[$i].")\n" if ($clitem ne 'x');
		}
		print "##\n";
		flush_data();
	}
	elsif ($input =~ m/^s[0-9]+.*/) {
		push @dataout,$input;
		flush_data();
	} elsif ($input =~ m/^i[0-9]+/) {
		push @dataout,$input;
		flush_data();
	} elsif ($input=~m/^add\s.*/) {
		push @dataout,$input;
		flush_data();
	} elsif ($input=~m/^del\s.*/) {
		push @dataout,$input;
		flush_data();
	}
	elsif ($input=~m/^auth\s.*/) {
		push @dataout,$input;
		flush_data();
	}
	elsif ($input eq "help") {
		print <<EOF

MRIM Quick Help

help         - this help
quit         - exits MRIM
sh           - show historized messages waiting
cl           - show contact list
s<num> <msg> - send <msg> to contact number <num> in the contact list
i<num>       - request information for contact number <num>
add <email>  - add an user to the contact list
del <email>  - remove an user from the contact list
auth <email> - authorize user

EOF
	}
	else {
		print BOLD RED "\nunkown command $input\n";
		print "\n";
	}

}

print "Exiting...\n"; push @dataout,"quit"; $thr->join; exit;

exit;

sub print_data {
	my ($mydata)=@_;
	print RESET "\n".$mydata;
	print UNDERLINE "\nMRIM > " if (length($mydata)>1);
}

sub flush_data {
	print_data($data);
	$data="";
}

sub cleanup_exit {
	flush_data();
	print BOLD "Exiting...";
	print "\n";
	push @dataout,"quit"; 
	$thr->join;
	exit;
}

sub my_local_time {
	my @ltime=localtime();
	return sprintf("%02d",$ltime[2]).':'.sprintf("%02d",$ltime[1]);
}

sub mrim_conn {

	my $mrim=Net::MRIM->new();
	$mrim->hello();
	if (!$mrim->login($LOGIN,$PASSWORD)) {
		print "LOGIN REJECTED\n";
		exit;
	}

	while (1) {
		my $command;
		my $ret=undef;
		foreach $command (@dataout) {
			if ($command eq "quit") { $mrim->disconnect; exit; }
			elsif ($command =~ m/^s([0-9]+)\s(.*)/) {
			 	my $contact=$clistkeys[$1-1];
				my $data=$2;
				if ($contact ne 'x') {
					$ret=$mrim->send_message($contact,$data);
					print_data(my_local_time()." > ".$data." (to $contact)\n");
				} else {
					print_data(my_local_time()." > ".$data." (discarded, $contact offline)\n");
				}
			}
			elsif ($command =~ m/^i([0-9]+)/) {
				my $contact=$clistkeys[$1-1];
				$ret=$mrim->contact_info($contact) if ($contact ne 'x');
			}
			elsif ($command =~ m/^add\s(.*)/) {
				$ret=$mrim->add_contact($1);
			}
			elsif ($command =~ m/^del\s(.*)/) {
				$ret=$mrim->remove_contact($1);
			}
			elsif ($command =~ m/^auth\s(.*)/) {
				$mrim->authorize_user($1);
			}
		}
		@dataout=();
		#sleep(1);
		$ret=$mrim->ping() if (!defined($ret));
		if (($ret->is_message())||($ret->is_server_msg())) {
			$data.=my_local_time()." ".$ret->get_from()." > ".$ret->get_message()."\n";
			flush_data();
		} elsif ($ret->is_contact_list()) {
			my $clist=$ret->get_contacts();
	                my $clitem;
			my @nclistkeys=();
			my @nclistitems=();
	                foreach $clitem (keys(%{$clist})) {
				if (defined($clist->{$clitem})) {
		                        push @nclistkeys,$clitem;
		                        push @nclistitems,$clist->{$clitem}->get_name();
					if(_is_in_list($clitem,@clistkeys)==0) {
						push @clistkeys,$clitem;
						push @clistitems, $clist->{$clitem}->get_name();
						#$data.="adding $clitem ". $clist->{$clitem}." to CL ".scalar(@clistkeys)." ".scalar( @clistitems)."\n";
					}
				}
	                }
			my $icl;
			for ($icl=0;$icl<scalar(@clistkeys);$icl++) {
				$clitem=$clistkeys[$icl];
				if (_is_in_list($clitem,@nclistkeys)==0) {
					$data.=my_local_time().': '.$clitem." disconnected.\n" if ($clitem ne 'x');
					$clistkeys[$icl]='x';
				}
			}
			flush_data() if ($data ne '');
		} elsif ($ret->is_logout_from_server()) {
			print "LOGGED OUT FROM SERVER\n";
			exit;
		}
	}

}

sub _is_in_list {
	my ($item,@list)=@_;
	foreach (@list) {
		return 1 if ($_ eq $item);
	}
	return 0;
} 
