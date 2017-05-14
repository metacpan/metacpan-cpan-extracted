require "t/test.pl";

print "1..3\n";
@maps=qw(passwd hosts cred);
for $map (@maps)
{
  print "$map test plain\n";
  run("t/niscat $map | sort", "niscat $map | sort") || print "not ";
  print "ok\n";
}
