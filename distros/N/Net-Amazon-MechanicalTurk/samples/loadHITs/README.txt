
This directory contains sample scripts for:
  * Bulk loading hits
  * Downloading results
  * Rejecting assignments
  * Approving assignments

Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Edit loadhits-input.csv to add any questions you want to ask on MechanicalTurk.

3. Run the command "perl loadhits.pl" from this directory to load the questions.
   A file named loadhits-success.csv will be created which contains the HITId's and
   HITTypeId's for the items loaded.  If there were any failures, a file named
   loadhits-failure.csv will be generated, with the items that failed.

4. If you are on the Sandbox, you should be able to go complete those hits
   as a worker.
   
5. Run the command "perl getresults.pl" from this directory to download the answers to the questions.
   A file named loadhits-results.csv will be created with those answers.
   
6. To reject any worker, open up loadhits-results.csv and a Column title "Reject".
   Place an "X" in the reject column for any assignments you wish to reject and save the file.
   Next run "perl reject.pl" from this directory to reject those.
   
7. To approve the remaining assignments run "perl approveRemaining.pl".

8. To clean up your hits you can run "perl removehits.pl" from this directory.
   This will try to dispose all hits in the success file.  If you have any submitted
   assignments it will auto approve them.
   
