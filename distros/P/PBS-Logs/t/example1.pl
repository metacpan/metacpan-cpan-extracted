BEGIN {
	push @INC, "blib/lib", "blib/arch", "../blib/lib", "../blib/arch";
}

use PBS::Logs::Acct;
#PBS::Logs::debug(0);
#print PBS::Logs::debug(),"\n";

my $file = 'acct.20050201';
my $pl;
if (1) {
	open PL, $file or die "can not open $file";
	if (1) {					# data as an array
		my @a = <PL>;
		$pl = new PBS::Logs::Acct(\@a);
	} else {
		$pl = new PBS::Logs::Acct(\*PL);	# data as a filter
	}
} else {
	$pl = new PBS::Logs::Acct($file);		# data as a file
}
print "type = ",$pl->type(),"\n";

print "keys = ",join(':',%PBS::Logs::Acct::keys),"\n";

print $pl->filter_records(),"\n";
print $pl->filter_records(qw{S E}),"\n";
print $pl->filter_records(),"\n";

if (1) {					# retrieve via arrays
	if (1) {				#   array reference
		my ($cnt,$x) = 0;
		while ($x = $pl->get()) {
			print $cnt," -- ";
			print $pl->line()," -- ";
			print 'qq{',join(" | ",@$x),"},\n";
			$cnt++;
		}
	} else {				#   array
		my @x;
		while (@x = $pl->get()) {
			print $x[0]," ",join(' : ',$pl->datetime($x[0])),"\n";
			print $x[0]," ",$pl->datetime($x[0]),"\n";
			print 'qq{',join(" | ",@x),"},\n"; # }
		}
	}
} else {					# retrieve via hashes
	if (1) {				#   hash reference
		my $x;
		while ($x = $pl->get_hash()) {
			print $pl->line()," -- ";
			print 'qq{',join(" | ",%$x),"},\n"; # }
		}
	} else {				#   hash
		my %x;
		while (%x = $pl->get_hash()) {
			print $x[0]," ",join(' : ',$pl->datetime($x[0])),"\n";
			print $x[0]," ",$pl->datetime($x[0]),"\n";
			print 'qq{',join(" | ",%x),"},\n"; # }
		}
	}
}

print "\n";
