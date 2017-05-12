use IPC::Open3;

my ($wtr, $rdr, $err);
my $pid = open3($wtr, $rdr, $err, 'irssi -! --home=t');

$skip = 1;
print $wtr "/script load 01_use.pl\n";
while (<$rdr>) {
  #s/\x1b//g;
  if ($skip) {
  	if (/foo/) {
  		$skip = 0;
	}
  	next 
  }
  print $_;
}
