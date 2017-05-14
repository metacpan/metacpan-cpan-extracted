require "t/test.pl";

use Net::NISPlus::Table;

#Net::NISPlus::WarningsOn;

print "1..1\n";
$map="perltest-";
$suf=0;
while(1)
{
  print "checking $map$suf\n";
  $table=Net::NISPlus::Table->new("$map$suf");
  last unless $table;
  $suf++;
}
$start="$map$suf";
$dom=Net::NISPlus::nis_local_directory();
$map="$start.org_dir.$dom";
print "create map $map\n";
$table=Net::NISPlus::Table->create($map, "abc", "def", 1324, 27, "test",
58, "", [["key", &Net::NISPlus::TA_SEARCHABLE | &Net::NISPlus::TA_CASE, 6839],
["value", 0, 1264]]);
print "failed to create table\n" unless $table;
run2("niscat -o $map", "sed -e 's/YYY/$dom/' -e 's/XXX/$start/' -e '/^__END__/,\$p' -e d $0 | tail +2") || print "not ";
print "ok\n";

__END__
Object Name   : XXX
Owner         : abc
Group	      : def
Domain        : org_dir.YYY
Access Rights : --------r-c---cd
Time to Live  : 0:0:27
Object Type   : TABLE
Table Type          : test
Number of Columns   : 2
Character Separator : :
Search Path         : 
Columns             :
	[0]	Name          : key
		Attributes    : (SEARCHABLE, TEXTUAL DATA, CASE INSENSITIVE)
		Access Rights : ---------m-drmc-
	[1]	Name          : value
		Attributes    : (TEXTUAL DATA)
		Access Rights : ----------c-----
