use Perl6::Form;

my @data = <DATA>;

for (@data) {
	my ($pid, $cmd, $time, $cpu) = split;
	$cmd =~ s/_/ /g;
	print form
		 "{>>>}  {<<<<<<<<<<<<<<}  {>>>>>>}  {>>.}%",
		  $pid,  $cmd,             $time,    $cpu;
}

print "---------------------------------------------\n";

for (@data) {
	my ($pid, $cmd, $time, $cpu) = split;
	$cmd =~ s/_/ /g;
	print form
		 "{>>>}  {<<<<<<<<<<<<<<}  {]]]]]]}   {>{5.2}.<%}",
		  $pid,  $cmd,             $time,    $cpu;
}

print "---------------------------------------------\n";

for (@data) {
	my ($pid, $cmd, $time, $cpu) = split;
	$cmd =~ s/_/ /g;
	print form
		 {single=>'%'},
		 "{>>>}  {<<<<<<<<<<<<<<}  {]]]]]]}  {>>.}%",
		  $pid,  $cmd,             $time,    $cpu, '%';
}

print "---------------------------------------------\n";

for (@data) {
	my ($pid, $cmd, $time, $cpu) = split;
	$cmd =~ s/_/ /g;
	print form
		 "{>>>}  {<<<<<<<<<<<<<<}  {]]]]]+}  {>>.}%",
		  $pid,  $cmd,             $time,    $cpu;
}

print "---------------------------------------------\n";

for (@data) {
	my ($pid, $cmd, $time, $cpu) = split;
	$cmd =~ s/_/ /g;
	printf "%5d  %-16s  %8s  %5.1f%%\n",
		  $pid,  $cmd,  $time, $cpu;
}

__DATA__
 2461  vi_henry           0:55.83   11.6
 2395  ex_cathedra        0:06.59    3.5
27384  mozillum          1214:23.75    0.8
 2439  head_anne.boleyn   0:00.18    0.1
 2581  dig_-short_grave   0:01.04    0.0
