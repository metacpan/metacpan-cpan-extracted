require "t/test.pl";

print "1..3\n";
@maps=qw(passwd hosts cred);
for $map (@maps)
{
  print "$map test minuso\n";
  run("t/niscat -o $map | sort", "niscat -o $map | sort") || print "not ";
  print "ok\n";
}
