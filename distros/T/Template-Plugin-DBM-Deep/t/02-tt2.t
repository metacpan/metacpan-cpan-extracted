#!perl
use Test::More 'no_plan';

chdir "t" if -d "t";

BEGIN { use_ok("Template") }
BEGIN { use_ok("DBM::Deep") }
isa_ok(my $engine = Template->new, "Template");

ok($engine->process(\"[% USE DBM.Deep('x.db') %]"), "USE DBM.Deep");
ok(-e "x.db", "made x.db");

isa_ok(my $db = DBM::Deep->new("x.db"), "DBM::Deep");
$db->{"fred"} = "flintstone";
is($db->{"fred"}, "flintstone", "set db fred to flintstone");

my $output;

$output = "";
ok($engine->process(\<<XXX, {}, \$output), "USE DBM.Deep to get fred");
[% USE db = DBM.Deep('x.db'); db.fred -%]
XXX
is($output, "flintstone", "proper output for db fred");

$output = "";
ok($engine->process(\<<XXX, {}, \$output), "set barney using file arg");
[% USE db = DBM.Deep(file = 'x.db'); db.barney = "rubble";
  db.fred; " "; db.barney;
-%]
is($output, "flintstone rubble", "proper output for db fred and db barney");
XXX

END {
  unlink "x.db";
}
