require "t/test.pl";

print "1..3\n";
@maps=qw(passwd hosts cred);
for $map (@maps)
{
  print "$map test minush\n";
  run("t/niscat -h $map | sort", "niscat -h $map | sort") || print "not ";
  print "ok\n";
}
