use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::Burst ':all';

$PDF::Burst::DEBUG = 1;


my $abs = './t/scan1.pdf';
ok -f $abs;

mkdir './t/alt';
ok_method( pdf_burst($abs) );

ok_method( pdf_burst($abs,'groupname') );

ok_method( pdf_burst($abs,'othergroupname', './t/alt') );

ok_method( pdf_burst($abs, undef , './t/alt') );

ok_method( pdf_burst_CAM_PDF($abs, undef , './t/alt') );



sub clean {


  my @arg  = qw(find ./t -type f -name "*_page_*pdf" -exec rm '{}' \;);
  #print STDERR " arg is '@arg'\n\n";

   `@arg`;
  #system @arg;
   
   # might not be anything there
   
   print STDERR "cleaned.\n";
   
}

#ok_method( pdf_burst($abs) );




sub ok_method {
   my $count = scalar @_;
   ok( $count, "count is $count" )
      or $PDF::Burst::DEBUG = 1;
   
   ( ok -f $_," have '$_'" ) for @_;
   print STDERR "\n"; 
   clean();
}
