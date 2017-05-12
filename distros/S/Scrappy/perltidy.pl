my $ver = $ARGV[0] ? "./$ARGV[0]" : ".";

print  "... cleaning up $ver";

system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/*.pm";
system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/Scrappy/*.pm";
system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/Scrappy/Action/*.pm";
system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/Scrappy/Plugin/*.pm";
system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/Scrappy/Project/*.pm";
system "perltidy --pro=perltidyrc " . $_ for glob "$ver/lib/Scrappy/Scraper/*.pm";

if ($ver ne '.') {
    system "rm $ver.tar.gz";
    system "tar -czf $ver.tar.gz $ver/*";
}