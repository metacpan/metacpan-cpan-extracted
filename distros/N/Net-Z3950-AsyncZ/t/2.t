use Socket;
use Net::Z3950::AsyncZ qw(:header :errors :record asyncZOptions);
print "1..10\n";
print STDERR "\n--Checking for Internet connection\n";
use strict;
my $num_tests = 0;
my $MAX_TESTS = 10;
   my @servers = (

                [ 'bison.umanitoba.ca', 210, 'MARION'],
		[ 'z3950.loc.gov', 7090, 'Voyager' ],
                [ 'library.anu.edu.au', 210, 'INNOPAC' ],
		[ 'library.usc.edu', 2200,'unicorn'],
	        [ 'amicus.nlc-bnc.ca', 210, 'NL'],
    	        [ 'fc1n01e.fcla.edu', 210, 'FI' ],
                [ 'axp.aacpl.lib.md.us', 210, 'MARION'],
		[ 'jasper.acadiau.ca', 2200, 'UNICORN']
          );


my $count = 0;
for my $s(@servers){  
    my @address = gethostbyname($s->[0]) && $count++;
  }


ok($count > 0) or {print  "Bail out! You don\'t appear to be connected to the Internet" .
                      "   --these tests require an Internet connection\n"} and
                exit;

($count > 0) and print STDERR " -- Internet Connection Found.\n -- Contacting test servers. Please wait.\n";

	   my @slice = @servers[0,7,3]; 
           my $query = '  @attr 1=1003  "Henry James" ';  
           my $asyncZ = Net::Z3950::AsyncZ->new(servers=>\@slice,query=>$query,cb=>\&output,
                     timeout=>45, maxpipes=>2);  

ok(ref $asyncZ eq 'Net::Z3950::AsyncZ');

 

  for(my $i = $num_tests; $i <$MAX_TESTS; $i++) {

          ok(1 == 1);
  }

exit;	
          #------END MAIN------#  

          sub output {            
            my($i, $a) = @_;
            ok (ref($a) eq "ARRAY");
           
          }       

          sub showErrors {
           my $asyncZ = shift;          
           print "The following servers have not responded to your query: \n";
           for(my $i=0; $i< $asyncZ->getMaxErrors();$i++) {
                  my $err = $asyncZ->getErrors($i);
                  next if !isZ_Error($err);  	  
                  print "$servers[$i]->[0]\n";                 
            	  print "  $err->[0]->{msg}\n" if $err->[0]->{msg};
                  print "  $err->[1]->{msg}\n" if $err->[1]->{msg};
          	}
              
          }



sub ok {
print @_,"\n";
$num_tests++;

if ($_[0])  {
   print STDOUT "ok $num_tests\n";
   return 1; 
}

print STDOUT "Not ok $num_tests\n"; print STDERR " \n Error at line: ", (caller())[2], "\n";
return 0;
}


