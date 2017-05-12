# $Id: basic.pl,v 1.5 2003/05/04 04:05:52 tower Exp $


   use Net::Z3950::AsyncZ qw(isZ_Error);   
  
   my @servers = (
	        [ 'amicus.nlc-bnc.ca', 210, 'NL'],
                ['bison.umanitoba.ca', 210, 'MARION'],
                [ 'library.anu.edu.au', 210, 'INNOPAC' ],
                ['130.17.3.75', 210, 'MAIN*BIBMAST'],	                
		[ 'library.usc.edu', 2200,'unicorn'],
		[ 'z3950.loc.gov', 7090, 'Voyager' ],
    	        [ 'fc1n01e.fcla.edu', 210, 'FI' ],
                [ 'axp.aacpl.lib.md.us', 210, 'MARION'],
		[ 'jasper.acadiau.ca', 2200, 'UNICORN']
          );



          my $query = '  @attr 1=1003  "Henry James" ';  
          my $asyncZ = Net::Z3950::AsyncZ->new(servers=>\@servers,query=>$query,cb=>\&output,timeout=>60);  
          showErrors($asyncZ);

     	  exit;
	
          #------END MAIN------#  

          sub output {
           my($index, $array) = @_;
           foreach my $line(@$array) {
             print "$line\n" if $line;  
            }
           print "\n--------\n\n";    
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



