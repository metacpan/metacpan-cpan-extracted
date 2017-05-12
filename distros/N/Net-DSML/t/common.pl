BEGIN 
{
  foreach (qw(my.cfg test.cfg)) {
    -f and require "$_" and last;
  }
}

sub compare_test
{
my ($p1, $p2) = @_;
chomp($p1);
chomp($p1);
#print "p1:  ", $p1,"\n";
#print "p2:  ", $p2,"\n";

return 1 if ( $p1 eq $p2);
return 0;
}

1;
