my $var1;
my $var2 = foo();
print ( exists $var2->{'$var1'} ? "ok " : "not ok ", "4\n");
print (!exists $var2->{'$var2'} ? "ok " : "not ok ", "5\n");
print (!exists $var2->{'$nono'} ? "ok " : "not ok ", "6\n");
