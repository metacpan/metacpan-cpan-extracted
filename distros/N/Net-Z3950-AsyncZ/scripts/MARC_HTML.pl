#!/usr/bin/perl -w

##  This script demonstrates a number of things
##	1. how to create you own MARC fields hash by adding fields to %$Net::Z3950::Report:all
##	2. use of the Z3950_options _params option
##      3. formatting HTML by starting with the default HTML row format
##      4. use of utf8 for unicode output TO browser
##

use Net::Z3950::AsyncZ qw(:header :errors asyncZOptions); 
use Net::Z3950::AsyncZ::Errors qw(suppressErrors);
use Net::Z3950::AsyncZ::Report;
use strict;


my @servers = (
                ['128.118.88.200',210,'catalog'],
                ['bison.umanitoba.ca', 210, 'MARION']

          );

	
# [1] create hash of additional MARC fields

my %my_MARC_fields = (
651 => "location",
654 => "terms",
655 => "genre",
656 => "occupation",
760 => "main series",
762 => "subseries",
765 => "original language",
767 => "translation entry",
770 => "supplement/special issue",
772 => "supplement parent",
773 => "host item entry",
774 => "constituent unit",
775 => "other edition",
776 => "add. physical form",
777 => "issued with",
780 => "preceding",
785 => "succeeding",
786 => "data source",
787 => "nonspecific rel.",
800 => "personal name",
810 => "corporate name",
811 => "meeting name",
830 => "uniform title"

);

# [2] create a new hash which adds the additional MARC fields to %$Net::Z3950::AsyncZ::Report::all,
# ($Net::Z3950::AsyncZ::Report::all is a reference to %Net::Z3950::AsyncZ::Report::MARC_Fields_All

my %my_MARC_hash = (%$Net::Z3950::AsyncZ::Report::all, %my_MARC_fields);


# [3] set options for both servers
#   --assign \%my_MARC_hash to marc_userdef
#   --ask for full records, the default is brief, by setting the Z3950 option elementSetName =>'f'.
#   The 'f' option is used by the Net::Z3950::ResultSet module.  We set this option by
#   using Z3950_options.  (Options set in the Manager are inherited by the other Z3950 modules.)
#  --set format to &Net::Z3950::AsyncZ::Report::_defaultRecordRowHTML or else set HTML to true.

my @options = (
             asyncZOptions(
                  num_to_fetch=>8, format=>\&Net::Z3950::AsyncZ::Report::_defaultRecordRowHTML,
                  marc_userdef=>\%my_MARC_hash,Z3950_options=>{elementSetName =>'f'}),
              asyncZOptions(
                  num_to_fetch=>8, HTML=>1,
                  marc_userdef=>\%my_MARC_hash)             
); 

#  [4] set the utf8 option to true--you could also do that above in step 3
$options[0]->set_utf8(1);
$options[1]->set_utf8(1);


# [5] set the query
my $query = '  @attr 1=1016  "Baudelaire" ';  
   
# [6] Output headers which notify the browser that this script is outputting utf8
print "Content-type: text/html;charset=utf-8'\n\n";		
print '<head><META http-equiv="Content-Type" content="text/html; charset=utf-8"></head><body>', "\n";

# [7] send out the query to the servers
          my $asyncZ =
            Net::Z3950::AsyncZ->new(servers=>\@servers,query=>$query,cb=>\&output,
                           options=>\@options, #log=>suppressErrors()
		);  


     	  exit;

          #------END MAIN------#  


          sub output {
           my($index, $array) = @_;

# [8] stipulate that the output stream is utf8--required!
           binmode(STDOUT, ":utf8");

# [9] create a table structure for the rows of <TD>'s which are output by the
# default format subroutine

           my $table_started = 0;
           my $server_found= 0;
           print "<TABLE><tr><td>";
           foreach my $line(@$array) {
             return if noZ_Response($line);
              
             next if isZ_Info($line);	# remove internal data                
             if (isZ_Header($line)) {
                    print '<tr><td>&nbsp;<td>&nbsp;</TABLE>' if $table_started;
                    $table_started = 1;

# [10] Add space around table elements and set the alignments for the columns
                    print '<TABLE cellspacing = "6" cellpadding="2" border="0" width = "600">';
                    print '<colgroup span="2"><COL ALIGN = "RIGHT" WIDTH="150" VALIGN="TOP"><COL ALIGN="LEFT"></COLGROUP>';
                    next;
             }
                  
             my $sn = Z_serverName($line);
             if($sn && ! $server_found) {			
                      print "\n<br><br><br><b>Server: ", $sn, "</b><br>\n";
		      $server_found = 1;	
             }
 
# [11] substitute a fancier style for the field names            
             $line =~ s/<TD>/<TD NOWRAP style="color:blue" align="right">/i;
             print "$line\n" if $line;  
            }
          print "</TABLE>";
          }       
