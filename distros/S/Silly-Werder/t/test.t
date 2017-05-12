
use Silly::Werder;

print "1..1\n";

if(my $line = Silly::Werder->line()) {
  print "ok 1\n";
}
else {
  print "not ok 1\n";
}
