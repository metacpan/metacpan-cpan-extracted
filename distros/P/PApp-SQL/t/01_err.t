BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use PApp::SQL;
$loaded = 1;
print "ok 1\n";

eval { sql_exec "" }; 
print $@ =~ /no \$DBH/ ? "" : "not ", "ok 2\n";

$DBH=5;
eval { sql_exec "" }; 
print $@ =~ /no \$DBH/ ? "" : "not ", "ok 3\n";
undef $DBH;

$db = new PApp::SQL::Database "", "DBI:nodb:nodb", "user", "pass";
print $db->dsn eq "DBI:nodb:nodb" ? "" : "not $@", "ok 4\n";

