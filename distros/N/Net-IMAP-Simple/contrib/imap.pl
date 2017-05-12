#!/usr/bin/perl
require 'lib/Net/IMAP/Simple.pm';
print "Square brackets: [] indicate optional arguments\n\n";
print "IMAP Server[:port] [localhost]: ";

while(<>){
	chomp;
	$_ ||= 'localhost';
	$imap = Net::IMAP::Simple->new($_, port => 143, timeout => 90) || die "$Net::IMAP::Simple::errstr\n";
	if($imap){
		print "Connected.\n";
		last;
	} else {
		print "Connection to $_ failed: $Net::IMAP::Simple::errstr\n";
		print "IMAP Server[:port]: ";
	}
}

print "User: ";
while(<>){
	chomp;
	$user = $_;
	if(!$user){
		print "Blank user not allowed\n";
		print "User: ";
	} else {
		last;
	}
}

print "Password: ";
system("stty -echo");
while(<>){
	chomp;
	if(!$imap->login($user, $_)){
		print "Login failed: " . $imap->errstr . "\n";
	} else {
		my $msgs = $imap->select("INBOX");
		print "Messages in INBOX: $msgs\n";
		last;
	}
}

system("stty echo");
print "\n";

my $ptc = qq{
 Please enter a command:

 help                   - This help screen
 list                   - List all folders / mail boxes accessable by this account
 folders		- List all folders within <box>
 select box <box>       - Select a mail box
 select folder <folder> - Select a folder within <box>, format: Some.Folder.I.Own
                          which looks like: Some/Folder/I/Own
 exit                   - Disconnect and close

};

print $ptc . "[root] ";

my %o;
while(<>){
	chomp;
	my (@folders, %boxes);
	my @folders = $imap->mailboxes;
	for(@folders){
		$boxes{ (split(/\./))[0] } = 1;
	}

	my @io = split(/\s+/, $_);

	if($io[0] eq 'select'){
		if($io[1] eq 'box'){
			if(!$boxes{ $io[2] }){
				print $ptc . "Invalid mail box: $io\n\n";
			} else {
				print "\n-- Mail box successfully selected --\n    $io[2]\n\n";
				$o{box} = $io[2];
			}
		} elsif($io[1] eq 'folder'){
			my $c = $imap->select($io[2]);
			if(!defined $c){
				print $ptc . "Select error: " . $imap->errstr . "\n\n";
			} else {
				print "-- Folder information: $io[2] --\n";
				print " Messages: " . $c . "\n";
				print "   Recent: " . $imap->recent . "\n";
				print "    Flags: " . $imap->flags . "\n";
				print "Flag List: " . join(" ", $imap->flags) . "\n\n";
		#		$o{folder} = $io[2];
			}
		} else {
			print $ptc . "Invalid select option\n\n";
		}
	} elsif($io[0] eq 'list'){
		print "-- Avaliable mail folders/boxes --\n";
		for(keys %boxes){
			print "Mail box: $_\n";
		}
		print "\n";
	} elsif($io[0] eq 'folders' && $o{box}){
		print "-- Listing folders in: $o{box} --\n";
		my $x = $o{box};
		$x =~ s/(\W)/\\$1/g;
		for(@folders){
			if(/^$x/){
				my $msgs = $imap->select($_);
				if(!defined $msgs){
					print "Failed to read: $o{box} -> $_: " . $imap->errstr . "\n";
				} else {
					printf("$o{box} -> $_ " . (" " x (30 - length($_))) . "[%06d]\n",  $msgs);
				}
			}
		}
		print "\n";
	} elsif($io[0] eq 'exit' || $io[0] eq 'quit'){
		print "Good bye!\n\n";
		$imap->quit;
		exit;
	} elsif($io[0] eq 'help'){
		print $ptc;
	} else {
		print $ptc . "Invalid command: $io[0]\n\n";
	}

	print "[" . ($o{box} ? $o{box} : 'root') . ($o{folder} ? " -> $o{folder}" : '') . "] ";
}
