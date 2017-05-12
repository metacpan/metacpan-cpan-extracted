#!perl -w
use DBI;
use Config qw(%Config);
$| = 1; # autoflush
use Ruby::Run;
puts "DBI demo";

pcfg = Perl["%Config"];

dbh = Perl["DBI"].connect("dbi:DBM:", Perl::undef, Perl::undef,
	{ "AutoCommit" => 0, "RaiseError" => 1}.to_perl());

puts "Initializing ...";

dbh.do("CREATE TABLE test (name VARCHAR PRIMARY KEY, value VARCHAR NOT NULL)");

sth = dbh.prepare("INSERT INTO test VALUES(?,?)");

pcfg.each_pair {|key,value|
	sth.execute(key, value);
}


sth = dbh.prepare("SELECT * FROM test WHERE name LIKE ?".to_perl());

puts "Selecting from Perl::Config,",
		"please input a key of the config hash (the wildcard '*' is available).",
		"CTRL-D to exit from this program.";

print "> ";

STDIN.each do |line|
	sth.execute(line.gsub(/\*/, '%').chomp());

	while( (row = sth.fetchrow_hashref()).defined? )
		puts "%s=%s" % [ row["name"], row["value"] ];
	end

	print "> ";
end

puts "\nCreaning up ...";

dbh.do("DROP TABLE test");

