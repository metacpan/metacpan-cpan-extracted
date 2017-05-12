
This directory contains sample scripts for:
  * Wiping all HIT's from your account.
  
  You may want to use this after playing around with the API
  on the MechanicalTurk sandbox.
  
  Warning: This script will auto approve any Submitted assignments.

Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Run "perl removeAllHITs.pl" to remove all hits from the system.
