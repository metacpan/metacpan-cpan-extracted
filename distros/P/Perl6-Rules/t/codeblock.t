use Perl6::Rules;

print "1..5\n";
"abc" =~ m{ ab { do{ print "ok 1 - do block\n" } } d
          | {print "ok 2 - pre fail\n"; fail; print "not ok 3 - post fail\n";}
     	  | abc { print "ok 3 - abc\n"; }
	      }
	  and print "ok 4 - Matched\n"
	  or print "not ok 4 - Matched\n";

print "not " unless $0 eq "abc";
print "ok 5 - Result\n";
