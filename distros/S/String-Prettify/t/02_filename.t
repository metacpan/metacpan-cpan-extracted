use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use constant DEBUG => 1;
use String::Prettify;



ok(1,"prettify_filename() example output");

my @strings = split( /\n/, q{/home/someone/Test Dir Here/!Creepi filename.txt
/home/someone/Test Dir He^^re/!Cre#,i--filename.epng
123104-ABIGAIL TANNER WORKPAPER-@TWK.pdf
/var/Clients/Gonyea Donald and Laurie-2395/incoming/2395-031508-W-LVW.PDF
/var/Clients/Gonyea Donald and Laurie-2395/incoming/2395-031508-H-POW.PDF
/var/Clients/Gonyea Donald and Laurie-2395/incoming/2395-031508-W-DOCB.PDF

/home/someone/Test D#%@^@ir Here/!Cre#,i--fi_11541241leName1241
dsc23552(4).pdf});



for my $string (@strings){
   $string or next;
   
   my $clean = prettify_filename($string);

   ok($clean,"from, to..\n$string\n$clean\n");   
}



print STDERR " - $0 ended\n" if DEBUG;

