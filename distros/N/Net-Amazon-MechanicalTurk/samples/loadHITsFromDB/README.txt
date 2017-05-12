
This directory contains sample scripts for:
  * Bulk loading hits from a database

Note: This sample uses SQLite as a database. 

    From http://www.sqlite.org/
    ---------------------------
    SQLite is a small C library that implements a self-contained,
    embeddable, zero-configuration SQL database engine.
    
To run these scripts you will need to have DBI and DBD::SQLite2 installed.
    
If your are using ActivePerl you can install SQLite2 and DBI using the ppm command.

    C:\>ppm install DBI
    C:\>ppm install DBD::SQLite2

On *nix, I suggest using CPAN to install these modules.

Steps:

1. Make sure you have properly configured the sdk.
     You can run the following command to edit your configuration:
   
       perl -MNet::Amazon::MechanicalTurk::Configurer -e configure
       
2. Run the command "perl createdb.pl" to generate the database.
   (A file named turk.db will be created)
   
3. Run the command "perl dumptables.pl" to show whats in the database.

4. Run the command "perl loadhits.pl" to load hits into MechanicalTurk.

5. If you want to remove these hits, you can use the script in the
   removeAllHITs sample to remove everything.
   (I would only suggest doing this in the sandbox environment.)
   
