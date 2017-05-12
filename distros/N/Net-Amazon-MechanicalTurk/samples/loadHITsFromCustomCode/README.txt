
This directory contains sample scripts for:
  * Bulk loading hits using custom code.


Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Run the command "perl loadhits.pl" to load hits using cities.xml as
   input.  This sample streams data directly out of the XML and into
   the loadHITs process, so only 1 hit is in memory at a time.
   
3. Run the command "perl loadhits2.pl" to load hits using cities.xml as
   input.  This sample reads cities.xml into memory as an array of hashes and
   gives that to the loadHITs process.

4. If you want to remove these hits, you can use the script in the
   removeAllHITs sample to remove everything.
   (I would only suggest doing this in the sandbox environment.)
   
