
This directory contains sample scripts for:
  * Creating a HIT using the web service API.

Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Run "perl helloworld-create.pl" from this directory to create a simple HIT.

3. If you are on Sandbox, go ahead and do the HIT as a worker.

4. Run "perl helloworld-answer.pl" from this directory to view the answer and approve the assignment.

