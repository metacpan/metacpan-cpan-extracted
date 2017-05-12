use IPC::Open3;

my ($wtr, $rdr, $err);
my $pid = open3($wtr, $rdr, $err, 'irssi -! --home=t');

$skip = 1;
print $wtr "/script load 02_unload.pl\n";
print $wtr "/foo\n";
print $wtr "/script unload 02_unload.pl\n";
sleep 1;
print $wtr "/quit\n";
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
