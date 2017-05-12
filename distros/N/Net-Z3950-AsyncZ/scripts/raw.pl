#!/usr/bin/perl -w

# $Id: raw.pl,v 1.5 2003/05/04 04:05:52 tower Exp $


# This script demonstrates how to get raw records which have not been filtered through
# Net::Z3950::Record::render()

# 1. Create @options array, set raw=>1 and render=>0 
# 2. follow the sample callback below (&ouput), which involves the following
#    basic steps:
#
#	 my $recs = prep_Raw($array);	# first prep record data for getting records with get_ZRawRec
#	 $rec = get_ZRawRec($recs)      # get each record by calling get_ZRawRec() in a loop

   use Net::Z3950::AsyncZ qw(:header :errors asyncZOptions getZ_RecSize prep_Raw get_ZRawRec); 
   use Net::Z3950::AsyncZ::Errors qw(suppressErrors);		
   my @servers = (

                ['bison.umanitoba.ca', 210, 'MARION'],
		[ 'z3950.loc.gov', 7090, 'Voyager' ],
	        [ 'jasper.acadiau.ca', 2200, 'UNICORN']
          );

   
  my @options = (		#set render to false so that unrendered raw records are output to callback
   asyncZOptions (raw=>1,num_to_fetch=>3, render=>0),
   asyncZOptions (raw=>1,num_to_fetch=>3, render=>0),
   asyncZOptions (raw=>1,num_to_fetch=>3, render=>0),
  );

          my $query = '  @attr 1=1003  "James Joyce" ';  
          my $asyncZ =
            Net::Z3950::AsyncZ->new(servers=>\@servers,query=>$query,cb=>\&output,
                           monitor=>45, 
                           maxpipes=>2,    
                           log=>suppressErrors(),
			   options => \@options,            
		);  

          showErrors($asyncZ);
          
     	  exit;



	
          #------END MAIN------#  

          sub output {
	  use utf8;
           my($index, $array) = @_;
           my $count=0;
           return if noZ_Response($array=>[0]); #[3]
           my $recs = prep_Raw($array);		#[4] 


	   while(($rec = get_ZRawRec($recs))) { #[5]
             my $outfile = "> raw_${index}_$count"; 
             open OUTFILE, $outfile;  
	     print OUTFILE $rec;
             close OUTFILE;
             $count++;
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



