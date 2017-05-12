open(FH,$ARGV[0]);
@f = (<FH>);
close(FH);
foreach $line (@f) {
  @c = split(//,$line);
  foreach $c (@c) { $f{$c}++; }
}
print "number of opening braces '{' = ",$f{'{'},"\n";
print "number of closing braces '}' = ",$f{'}'},"\n";
print "braces are ", ($f{'{'} == $f{'}'}) ? '' : "not ","balanced\n";

