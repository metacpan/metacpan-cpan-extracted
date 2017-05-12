
This directory contains sample scripts for:
  * Downloading HIT information.


Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Run the command "perl listHITs.pl" to save the following fields to 
   a CSV file for all HITs:
     HITId
     HITTypeId
     HITStatus
     Title
   A file named hits.csv will be generated.
