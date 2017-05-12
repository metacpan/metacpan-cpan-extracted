use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use constant DEBUG => 1;
use String::Prettify;
print STDERR " - $0 started\n" if DEBUG;

ok(1);

my @strings = ('/home/super/whatever/thing file here.php',
qw(Themost_interesting124315.jpg alsosomOtherThing.txt usages),
'Client. Harry Waltzman, PPD',

'/home/leo/devel_attic/misc/DMS_old/doc.users/Georgia O Triantis/2002 Tax File/Triantis Workpaper File.pdf',
'/home/leo/devel_attic/misc/DMS_old/doc.users/RGS Title - Maryland LLC/RGS FU New Maryland/Escrow reconciliations/FU New MD 91005.pdf',
'/home/leo/devel_attic/misc/DMS_old/doc.users/RGS Title - Maryland LLC/RGS FU New Maryland/Escrow reconciliations/FU New MD 81005 final.pdf',
'/home/leo/devel_attic/misc/DMS_old/doc.users/RGS Title - Maryland LLC/2002 Tax File/RGS Title MD 2002 Workpaper file.pdf',
'/home/leo/devel/vyc_content/misc/af_news_letter.pdf',
'/home/leo/devel/vyc_content/misc/contributions_and_pledges.pdf',

split( /\n/ ,q{/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/MICHELLE PERRY/082905-MICHELLE PERRY-030574-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/MICHELLE PERRY/092805-MICHELLE PERRY-031088-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/RECORDING R US INC/090605-RECORDING R US INC-030793-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/AMERICAN FIRST ABSTRACT LLC/122005-AMERICAN FIRST ABSTRACT LLC-032501-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PITNEYBOWES CREDIT CORPORATION/102105-PITNEYBOWES CREDIT CORPORATION-031585-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/D SCOTT LEE/092805-D SCOTT LEE-031098-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/D SCOTT LEE/082905-D SCOTT LEE-030584-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/D SCOTT LEE/082505-D SCOTT LEE-030509-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/D SCOTT LEE/103005-D SCOTT LEE-031881-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/D SCOTT LEE/121305-D SCOTT LEE-032486-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/RE MAX  REALTY SERVICES/101305-RE MAX  REALTY SERVICES-031483-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/KEITH BEACHLEY/093005-KEITH BEACHLEY-031337-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/US LEC CORP/122005-US LEC CORP-032623-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/US LEC CORP/092705-US LEC CORP-031031-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/US LEC CORP/102705-US LEC CORP-031752-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/US LEC CORP/112805-US LEC CORP-032309-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/UNITED PARSEL SERVICE/102105-UNITED PARSEL SERVICE-031605-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/WOMENS COUNCIL OF REALTORS/120105-WOMENS COUNCIL OF REALTORS-032409-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/MIRIAM DEL GRANADO/101305-MIRIAM DEL GRANADO-031464-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/MIRIAM DEL GRANADO/111005-MIRIAM DEL GRANADO-031960-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/092705-JOE RAGANS COFFEE-031003-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/112805-JOE RAGANS COFFEE-032271-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/101305-JOE RAGANS COFFEE-031452-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/122905-JOE RAGANS COFFEE-032744-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/111005-JOE RAGANS COFFEE-031945-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/082505-JOE RAGANS COFFEE-030485-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/120105-JOE RAGANS COFFEE-032369-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/121305-JOE RAGANS COFFEE-032466-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/093005-JOE RAGANS COFFEE-031336-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/102105-PROPERTY INSIGHT-031531-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/082505-PROPERTY INSIGHT-030343-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/092705-PROPERTY INSIGHT-030922-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/082505-PROPERTY INSIGHT-030342-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/093005-PROPERTY INSIGHT-031161-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/092705-PROPERTY INSIGHT-030927-@AP.pdf
/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/PROPERTY INSIGHT/112305-PROPERTY INSIGHT-032199-@AP.pdf})


);

for my $string (@strings){
   
   my $clean = prettify($string);
  # print STDERR "\n\n# '$string'\n";

   ok($clean,"from, to..\n$string\n$clean\n");

   
}



print STDERR " - $0 ended\n" if DEBUG;

