require "t/test.pl";

print "1..1\n";
print "indexed passwd test\n";
run("t/niscat -o '[name=rik],passwd' | sort",
  "/usr/bin/niscat -o '[name=rik],passwd' | sort") || print "not ";
print "ok\n";
