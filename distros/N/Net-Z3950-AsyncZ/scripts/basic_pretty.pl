
# $Id: basic_pretty.pl,v 1.5 2003/05/04 04:05:52 tower Exp $


   use Net::Z3950::AsyncZ qw(:header :errors); 
   use Net::Z3950::AsyncZ::Errors qw(suppressErrors);
   
		
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
          my $asyncZ =
            Net::Z3950::AsyncZ->new(servers=>\@servers,query=>$query,cb=>\&output,                          
                           log=>suppressErrors(), num_to_fetch=>3			  
		);  
          showErrors($asyncZ);

     	  exit;



	
          #------END MAIN------#  

          sub output {
           my($index, $array) = @_;

           foreach my $line(@$array) {
             return if noZ_Response($line);
             next if isZ_Info($line);	# remove internal data                
             next if isZ_Header($line); # again remove internal data
					# you could first test for type of output:
					# isZ_MARC, etc.

					# extract server name from header
             (print "\nServer: ", Z_serverName($line), "\n"), next
                     if isZ_ServerName($line);

             print "$line\n" if $line;  
            }

          }       


          sub showErrors {
           my $asyncZ = shift;          

		# substitute some general statement for a system level error instead
		# of something puzzling to the user like:  'illegal seek'
           my $systemerr = "A system error occurred on the server\n";  

           print "The following servers have not responded to your query: \n";

           for(my $i=0; $i< $asyncZ->getMaxErrors();$i++) {
                  my $err = $asyncZ->getErrors($i);   
                  next if !isZ_Error($err);            # is this a geniuine error?	  
                  print "$servers[$i]->[0]\n";  
                  if($err->[0]->isSystem()) {
                        print $systemerr;
                  }
          	  else {
                      print "  $err->[0]->{msg}\n" if $err->[0]->{msg}; 
                  }
                  if($err->[1] && $err->[1]->isSystem()) {
                        print $systemerr;
                  }
          	  else {
                      print "  $err->[1]->{msg}\n" 
                        if $err->[1]->{msg} && $err->[1]->{msg} != $err->[0]->{msg};

                  }

          	}
              
          }



