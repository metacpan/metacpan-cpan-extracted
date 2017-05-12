$|++;

END { print "not ok\n" unless $loaded;}

#first check perl version
BEGIN {
  if($] < 5.005) {
     print "you need at least version 5.005 to run this module. sorry.\n";
     exit 2;
  }      
}


#-----
#all I can do is test for dependencies..
#-----
  print "\n\n";
  my @mod = qw/Sybase::DBlib Sybase::ObjectInfo Sybase::Xfer Getopt::Long Tie::IxHash/;
  for my $m (@mod) {
     print "checking for $m. ";
     eval "use $m";
     if($@) {
        print "\n\nERROR: package $m is required and could not be found.\n\n";
        pinc();
     } else {
        print "yes\n";
     }
  }




#----
#if it got here everything went fine.
#----
  $loaded = 1;
  print "\nPasses all tests!\n";
  print "ok\n";
  exit 0;


#----
# print @INC arry to see what's in there
#----
  sub pinc {
     my $x;
     print "\n\@INC Array\n";
     print "  ",++$x,' ',$_,"\n" for (@INC);
     exit 2;
  }
