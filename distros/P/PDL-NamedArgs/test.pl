#!/opt/perl/bin/perl
use PDL::NamedArgs;

sub xbinom
{
   my($status,%argHash)=parseArgs('q, size, prob, lower_tail=1, log_p=0',@_);

   die ("xbinom error\n$status\n") if $status;

   print "(q, size, prob, lower_tail, log_p) = ";
   print "($argHash{q}, $argHash{size}, $argHash{prob}, $argHash{lower_tail}, $argHash{log_p})\n";
   return "";
}

# Simple tests with only numeric values
xbinom(.5, 50, 3,1,0);
xbinom(.5,size=>50,3,log_p=>0);
xbinom(prob=>3,q=>.5,size=>50);
xbinom(prob=>3,size=>50,.5);

# Torture test with both numeric & alpha values
xbinom(blah, junk, foo,1,0);
xbinom(blah,size=>junk,foo,log_p=>0);
xbinom(prob=>foo,q=>blah,size=>junk);
xbinom(prob=>foo,size=>junk,blah);

